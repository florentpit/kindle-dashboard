import Foundation
import CryptoKit

enum ServerSourceCache {
    struct Entry: Codable {
        var url: String
        var fetchedAt: Double
        var data: Data
    }
    static func key(_ url: URL) -> String { SHA256.hash(data: Data(url.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined() }
    static func requests(for page: KindlePage) throws -> Data {
        var addresses = Set<String>()
        for block in page.blocks where !block.hidden && block.kind == .weather {
            addresses.insert(try WeatherService.url(block: block, timezone: page.schedule.timezone).absoluteString)
        }
        return try JSONEncoder().encode(addresses.sorted())
    }
    static func read(_ url: URL, folder: URL, now: Date = Date()) -> Data? {
        let file = folder.appendingPathComponent(key(url) + ".json")
        guard let bytes = try? Data(contentsOf: file), bytes.count < 12_000_000,
              let entry = try? JSONDecoder().decode(Entry.self, from: bytes), entry.url == url.absoluteString,
              entry.fetchedAt <= now.timeIntervalSince1970 + 60, entry.fetchedAt >= now.timeIntervalSince1970 - 1800,
              entry.data.count < 8_000_000 else { return nil }
        return entry.data
    }
}
