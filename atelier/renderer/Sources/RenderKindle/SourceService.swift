import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

enum SourceService {
    static let presetURLs: Set<String> = ["https://www.lemonde.fr/rss/une.xml", "https://techcrunch.com/category/artificial-intelligence/feed/", "https://www.theverge.com/rss/ai-artificial-intelligence/index.xml", "https://www.technologyreview.com/topic/artificial-intelligence/feed", "https://tldr.tech/api/rss/ai"]
    static func data(_ url: URL) async throws -> Data {
        try await data(url, session: .shared)
    }
    static func data(_ url: URL, session: URLSession, attempts: Int = 3) async throws -> Data {
        guard url.scheme == "https" else { throw PageError.invalid("La source doit utiliser HTTPS.") }
        for attempt in 0..<max(1, attempts) {
            try Task.checkCancellation()
            do {
                var request = URLRequest(url: url, timeoutInterval: 25)
                request.cachePolicy = .reloadIgnoringLocalCacheData
                request.setValue("AtelierKindle/0.7.8", forHTTPHeaderField: "User-Agent")
                let (bytes, response) = try await session.data(for: request)
                guard let response = response as? HTTPURLResponse, response.url?.scheme == "https", bytes.count < 8_000_000 else {
                    throw PageError.invalid("Réponse invalide : \(url.host ?? "source").")
                }
                if response.statusCode == 429 || (500..<600).contains(response.statusCode) {
                    throw URLError(.resourceUnavailable)
                }
                guard (200..<300).contains(response.statusCode) else {
                    throw PageError.invalid("La source \(url.host ?? "") répond HTTP \(response.statusCode).")
                }
                return bytes
            } catch {
                guard error is URLError, (error as? URLError)?.code != .cancelled, attempt + 1 < max(1, attempts) else { throw error }
                try await Task.sleep(nanoseconds: UInt64(attempt + 1) * 500_000_000)
            }
        }
        throw URLError(.unknown)
    }

    /// Hosted macOS runners can stall in URLSession while reaching the weather
    /// provider. The system curl gives the renderer an explicit IPv4 route.
    static func serverData(_ url: URL, executable: String = "/usr/bin/curl") async throws -> Data {
        guard url.scheme == "https" else { throw PageError.invalid("La source doit utiliser HTTPS.") }
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("atelier-source-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: folder) }
        let output = folder.appendingPathComponent("source.data")
        let process = Process(); process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = ["--ipv4", "--fail", "--silent", "--show-error", "--location", "--proto", "=https", "--proto-redir", "=https", "--connect-timeout", "8", "--max-time", "25", "--retry", "2", "--retry-delay", "1", "--retry-max-time", "75", "--max-filesize", "8000000", "--user-agent", "AtelierKindle/0.7.9", "--output", output.path, url.absoluteString]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try Task.checkCancellation(); try process.run()
        defer { if process.isRunning { process.terminate() } }
        while process.isRunning { try await Task.sleep(nanoseconds: 20_000_000) }
        guard process.terminationStatus == 0 else {
            // A second HTTPS transport is useful if curl's route is unavailable.
            // No insecure certificate option is ever used.
            return try await data(url, session: .shared, attempts: 1)
        }
        let bytes = try Data(contentsOf: output)
        guard bytes.count < 8_000_000 else { throw PageError.invalid("La source dépasse la taille maximale.") }
        return bytes
    }

    static func fetch(for page: KindlePage) async throws -> SourceSnapshot {
        try await fetch(for: page, loader: { try await data($0) })
    }
    private enum Loaded {
        case weather(String, WeatherSnapshot), news(String, [NewsItem]), failed(String, String)
    }
    static func fetch(for page: KindlePage, loader: @escaping (URL) async throws -> Data) async throws -> SourceSnapshot {
        // Each source has its own failure boundary. A slow feed cannot discard fresh weather.
        var result = page.sources.example ? SourceSnapshot() : page.sources
        if page.sources.example { result.weather = [:]; result.news = [:] }
        var seen = Set<String>(), requested = 0, refreshed = 0
        var failures: [String: String] = [:]
        await withTaskGroup(of: Loaded.self) { group in
            for block in page.blocks where !block.hidden {
                if block.kind == .weather {
                    let key = "\(block.city)|\(block.unit)"
                    guard seen.insert("weather:" + key).inserted else { continue }; requested += 1
                    group.addTask {
                        do { return .weather(key, try WeatherService.decode(try await loader(WeatherService.url(block: block, timezone: page.schedule.timezone)), timezone: page.schedule.timezone)) }
                        catch { return .failed("weather:" + key, error.localizedDescription) }
                    }
                } else if block.kind == .news {
                    let address = block.sourceURL
                    guard seen.insert("news:" + address).inserted else { continue }; requested += 1
                    group.addTask {
                        do { return .news(address, Array(try await articles(at: address, loader: loader).prefix(12))) }
                        catch { return .failed("news:" + address, error.localizedDescription) }
                    }
                }
            }
            for await item in group {
                switch item {
                case let .weather(key, snapshot):
                    result.weather[key] = snapshot
                    if result.weatherFetchedAt == nil { result.weatherFetchedAt = [:] }
                    result.weatherFetchedAt?[key] = Date(); refreshed += 1
                case let .news(key, items):
                    result.news[key] = items
                    if result.newsFetchedAt == nil { result.newsFetchedAt = [:] }
                    result.newsFetchedAt?[key] = Date(); refreshed += 1
                case let .failed(key, message): failures[key] = message
                }
            }
        }
        try Task.checkCancellation()
        guard requested == 0 || refreshed > 0 else {
            throw PageError.invalid("Aucune source actualisée. " + failures.sorted{$0.key < $1.key}.map{"\($0.key) : \($0.value)"}.joined(separator: " ; "))
        }
        result.sourceErrors = failures.isEmpty ? nil : failures
        result.example = false
        // A partial refresh must not make a failed weather source look newly fetched.
        if failures.isEmpty { result.fetchedAt = Date() }
        return result
    }

    struct Cache: Codable {
        var deploymentID: String
        var sources: SourceSnapshot
    }
    static func previousSources(_ bytes: Data, deploymentID: String) -> SourceSnapshot? {
        guard let cache = try? JSONDecoder().decode(Cache.self, from: bytes),
              !deploymentID.isEmpty, cache.deploymentID == deploymentID, !cache.sources.example else { return nil }
        return cache.sources
    }

    static func parseFeed(_ bytes: Data) -> [NewsItem] {
        let reader = FeedReader(); let parser = XMLParser(data: bytes); parser.delegate = reader
        parser.shouldResolveExternalEntities = false
        return parser.parse() ? reader.items : []
    }

    static func articles(at address: String) async throws -> [NewsItem] {
        try await articles(at: address, loader: { try await data($0) })
    }
    static func articles(at address: String, loader: (URL) async throws -> Data) async throws -> [NewsItem] {
        guard let url = URL(string: address.trimmingCharacters(in: .whitespacesAndNewlines)), url.scheme == "https", url.host != nil else {
            throw PageError.invalid("Indiquez une adresse HTTPS de site ou de flux RSS / Atom.")
        }
        if url.host?.lowercased()=="tldr.tech",url.path.hasPrefix("/ai/") {
            let stories=TLDRReader.stories(in:String(decoding:try await loader(url),as:UTF8.self),edition:url)
            guard !stories.isEmpty else { throw PageError.invalid("Aucun article lisible dans cette édition TLDR.") };return stories
        }
        let bytes = try await loader(url)
        let direct = parseFeed(bytes)
        if url.host?.lowercased()=="tldr.tech",url.path=="/api/rss/ai" {
            guard let address=direct.first?.link,let edition=URL(string:address),edition.scheme=="https",edition.host?.lowercased()=="tldr.tech",edition.path.hasPrefix("/ai/") else { throw PageError.invalid("Le flux TLDR ne contient pas d’édition quotidienne valide.") }
            let stories=TLDRReader.stories(in:String(decoding:try await loader(edition),as:UTF8.self),edition:edition)
            guard !stories.isEmpty else { throw PageError.invalid("Les résumés de cette édition TLDR sont indisponibles.") };return stories
        }
        if !direct.isEmpty { return direct }
        let candidates = discoveredFeeds(in: String(decoding: bytes, as: UTF8.self), base: url)
        for feed in candidates.prefix(4) {
            if let bytes = try? await loader(feed) {
                let articles = parseFeed(bytes)
                if !articles.isEmpty { return articles }
            }
        }
        throw PageError.invalid("Cette adresse ne fournit pas de flux RSS / Atom lisible. Collez l’adresse du flux de ce média ; le texte disponible dépend de ce qu’il publie.")
    }

    static func discoveredFeeds(in html: String, base: URL) -> [URL] {
        guard let tags = try? NSRegularExpression(pattern: "<link\\b[^>]*>", options: .caseInsensitive),
              let attributes = try? NSRegularExpression(pattern: "([a-zA-Z:-]+)\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)'|([^\\s>]+))") else { return [] }
        var result: [URL] = []
        for tag in tags.matches(in: html, range: NSRange(html.startIndex..., in: html)) {
            guard let range = Range(tag.range, in: html) else { continue }
            let text = String(html[range]); var values: [String: String] = [:]
            for match in attributes.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                guard let key = Range(match.range(at:1),in:text) else { continue }
                for index in 2...4 { if let value = Range(match.range(at:index),in:text) { values[String(text[key]).lowercased()] = String(text[value]); break } }
            }
            if ["application/rss+xml","application/atom+xml","application/rdf+xml"].contains(values["type"]?.lowercased() ?? ""),
               let href = values["href"], let url = URL(string: href.replacingOccurrences(of: "&amp;", with: "&"), relativeTo: base)?.absoluteURL, url.scheme == "https", !result.contains(url) { result.append(url) }
        }
        return result
    }

    static func geocode(_ city: String) async throws -> (String, Double, Double, String) {
        var c = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        c.queryItems = [.init(name: "name", value: city), .init(name: "count", value: "1"), .init(name: "language", value: "fr")]
        let json = try JSONSerialization.jsonObject(with: await data(c.url!)) as? [String: Any]
        guard let results = json?["results"] as? [[String: Any]], let first = results.first,
              let name = first["name"] as? String, let lat = first["latitude"] as? Double, let lon = first["longitude"] as? Double else {
            throw PageError.invalid("Ville introuvable. Essayez un nom plus précis.")
        }
        return (name, lat, lon, first["admin2"] as? String ?? first["admin1"] as? String ?? "")
    }
}

final class FeedReader: NSObject, XMLParserDelegate {
    var items: [NewsItem] = []
    private var inside = false
    private var stack: [String] = []
    private var values: [String: String] = [:]
    private var link = ""
    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String]) {
        stack.append(name)
        if name == "item" || name == "entry" { inside = true; values = [:]; link = "" }
        if inside && name == "link", let href = attributes["href"], attributes["rel"] == nil || attributes["rel"] == "alternate" { link = href }
        if inside && name == "br" { append(" ") }
    }
    private func append(_ string: String) {
        guard inside, let key = stack.last(where: { ["title","description","summary","content:encoded","content","link"].contains($0) }) else { return }
        // Bounded buffers, including feeds supplying full content.
        if (values[key]?.count ?? 0) < 100_000 { values[key, default: ""] += string }
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) { append(string) }
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) { append(String(decoding: CDATABlock, as: UTF8.self)) }
    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName: String?) {
        if name == "item" || name == "entry" {
            let title = Self.clean(values["title"] ?? "")
            let summaries = ["content:encoded","content","description","summary"].compactMap { values[$0].map(Self.clean) }
            if !title.isEmpty {
                items.append(.init(title: title, summary: String((summaries.max(by: { $0.count < $1.count }) ?? "").prefix(8000)), link: (link.isEmpty ? values["link"] ?? "" : link).trimmingCharacters(in: .whitespacesAndNewlines)))
            }
            inside = false
        }
        if !stack.isEmpty { stack.removeLast() }
    }
    static func clean(_ text: String) -> String {
        var result = text.replacingOccurrences(of: "(?is)<(script|style)[^>]*>.*?</\\1>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        for (entity, value) in ["&amp;":"&", "&quot;":"\"", "&#39;":"’", "&apos;":"’", "&nbsp;":" ", "&lt;":"<", "&gt;":">", "&rsquo;":"’", "&lsquo;":"‘", "&eacute;":"é", "&agrave;":"à", "&mdash;":"—", "&ndash;":"–"] { result = result.replacingOccurrences(of: entity, with: value) }
        if let regex = try? NSRegularExpression(pattern: "&#(x[0-9a-fA-F]+|[0-9]+);") {
            for match in regex.matches(in: result, range: NSRange(result.startIndex..., in: result)).reversed() {
                guard let range = Range(match.range, in: result), let digits = Range(match.range(at: 1), in: result) else { continue }
                let value = String(result[digits]); let number = value.hasPrefix("x") ? UInt32(value.dropFirst(), radix:16) : UInt32(value)
                if let number, let scalar = UnicodeScalar(number) { result.replaceSubrange(range, with: String(scalar)) }
            }
        }
        return result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
