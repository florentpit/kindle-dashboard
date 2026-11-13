import Foundation

enum BlockKind: String, Codable, CaseIterable, Identifiable {
    case weather, news, text, image, clock, date, divider, shape
    var id: String { rawValue }
    var title: String {
        switch self {
        case .weather: "Météo"
        case .news: "Actualités"
        case .text: "Texte"
        case .image: "Image"
        case .clock: "Horloge"
        case .date: "Date"
        case .divider: "Séparateur"
        case .shape: "Forme"
        }
    }
    var symbol: String {
        switch self {
        case .weather: "cloud.sun"
        case .news: "newspaper"
        case .text: "textformat"
        case .image: "photo"
        case .clock: "clock"
        case .date: "calendar"
        case .divider: "minus"
        case .shape: "square"
        }
    }
}

struct PageBlock: Codable, Identifiable, Equatable {
    var id = UUID()
    var kind: BlockKind
    var x: Double = 64
    var y: Double = 64
    var width: Double = 944
    var height: Double = 200
    var text = ""
    var fontName = "Inter"
    var fontSize: Double = 32
    var bold = false
    var italic = false
    var alignment = "left"
    var lineSpacing: Double = 5
    var ink: Double = 0.08
    var background: Double = 1
    var hasBackground = false
    var opacity: Double = 1
    var cornerRadius: Double = 0
    var padding: Double = 0
    var locked = false
    var hidden = false
    var imageID: UUID?
    var imageFill = true
    var imageContrast: Double = 1
    var imageBrightness: Double = 0
    var sourceURL = "https://techcrunch.com/category/artificial-intelligence/feed/"
    var articleCount = 3
    var showSummary = true
    // Optional additions keep documents created by 0.1/0.2 readable.
    var summaryLines: Int?
    var articleOffset: Int?
    var showNewsSource: Bool?
    var newsSummaryLines: Int { max(1, min(30, summaryLines ?? 6)) }
    var newsOffset: Int { max(0, min(11, articleOffset ?? 0)) }
    var city = "Bouliac"
    var latitude = 44.8193
    var longitude = -0.50265
    var showForecast = true
    var forecastOnly: Bool?
    var weatherStyle: String?
    var region: String?
    var weatherHeader: Bool?
    var unit = "celsius"
    var clockFormat = "HH:mm"
    var dateFormat = "EEEE d MMMM"
    var font: String { fontName }

    static func make(_ kind: BlockKind, x: Double = 64, y: Double = 64) -> Self {
        var b = PageBlock(kind: kind, x: x, y: y)
        switch kind {
        case .text: b.text = "Votre texte ici"; b.height = 100; b.fontSize = 44
        case .weather: b.height = 656; b.fontSize = 32; b.weatherStyle = "detailed"; b.weatherHeader = true; b.fontName = "Newsreader"
        case .news: b.text = "À la une"; b.height = 800; b.fontSize = 32; b.summaryLines = 6
        case .image: b.width = 600; b.height = 300
        case .clock: b.width = 320; b.height = 100; b.fontSize = 64
        case .date: b.height = 60; b.fontSize = 26
        case .divider: b.height = 2
        case .shape: b.width = 240; b.height = 180; b.hasBackground = true; b.background = 0.92
        }
        return b
    }
}

struct EmbeddedAsset: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var data: Data
}

struct EmbeddedFont: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var postScriptName: String
    var data: Data
}

enum ScheduleMode: String, Codable, CaseIterable {
    case hourly, fixed, interval, manual
    var title: String {
        switch self {
        case .hourly: "Chaque heure"
        case .fixed: "À heures fixes"
        case .interval: "À intervalle régulier"
        case .manual: "Manuellement"
        }
    }
}

struct UpdateSchedule: Codable, Equatable {
    var mode: ScheduleMode = .hourly
    var fixedTimes = ["07:00", "12:00", "18:00"]
    var intervalMinutes = 60
    var timezone = "Europe/Paris"
    var weekdays = [1, 2, 3, 4, 5, 6, 7] // Calendar: Sunday = 1
    var activeWindow = false
    var startHour = 7
    var endHour = 22
    var lightEnabled = false
    var lightPercent = 25
    var lightSeconds = 30
    var lightDayOnly = true
    var lightStartHour = 7
    var lightEndHour = 22
    var lightOnlyChanged = true
    var restoreLight = true

    func allows(hour: Int) -> Bool {
        !activeWindow || Self.contains(hour: hour, start: startHour, end: endHour)
    }

    static func contains(hour: Int, start: Int, end: Int) -> Bool {
        if start == end { return true }
        return start < end ? hour >= start && hour < end : hour >= start || hour < end
    }

    func nextDates(after date: Date, count: Int = 6) -> [Date] {
        guard mode != .manual, let tz = TimeZone(identifier: timezone), !weekdays.isEmpty else { return [] }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz
        var result: [Date] = []
        let start = Int(date.timeIntervalSince1970 / 60) * 60 + 60
        for offset in 0..<(60 * 24 * 15) {
            let candidate = Date(timeIntervalSince1970: Double(start + offset * 60))
            let c = calendar.dateComponents([.hour, .minute, .weekday], from: candidate)
            let h = c.hour!, m = c.minute!
            guard weekdays.contains(c.weekday!), allows(hour: h) else { continue }
            let matches: Bool
            switch mode {
            case .hourly: matches = m == 0
            case .fixed: matches = fixedTimes.contains(String(format: "%02d:%02d", h, m))
            case .interval: matches = (h * 60 + m) % max(5, intervalMinutes) == 0
            case .manual: matches = false
            }
            if matches { result.append(candidate) }
            if result.count == count { break }
        }
        return result
    }
}

struct NewsItem: Codable, Equatable, Identifiable {
    var id: String { link.isEmpty ? title : link }
    var title: String
    var summary: String
    var link: String
}

struct ForecastDay: Codable, Equatable {
    var day: String
    var low: Double
    var high: Double
    var code: Int
    var rainProbability: Double?
}

struct HourlyWeather: Codable, Equatable {
    var time: Date
    var temperature: Double?
    var code: Int?
    var isDay: Bool?
}

struct WeatherSnapshot: Codable, Equatable {
    var temperature: Double
    var code: Int
    var days: [ForecastDay]
    var apparentTemperature: Double?
    var humidity: Double?
    var windSpeed: Double?
    var windDirection: Double?
    var isDay: Bool?
    var high: Double?
    var low: Double?
    var rainProbability: Double?
    var rainAmount: Double?
    var uvIndex: Double?
    var sunrise: Date?
    var sunset: Date?
    var observedAt: Date?
    var hours: [HourlyWeather]?
}

struct SourceSnapshot: Codable, Equatable {
    var weather: [String: WeatherSnapshot] = [:]
    var news: [String: [NewsItem]] = [:]
    var fetchedAt: Date?
    var example = true
    var newsFetchedAt: [String: Date]?
    var weatherFetchedAt: [String: Date]?
    var sourceErrors: [String: String]?
    static var sample: Self {
        .init(weather: ["Bouliac|celsius": .reference], news: ["https://techcrunch.com/category/artificial-intelligence/feed/": [
            .init(title: "L’intelligence artificielle entre dans le quotidien", summary: "Recherche, création et nouveaux usages : les sujets à suivre aujourd’hui. Les outils évoluent et trouvent leur place dans les gestes du quotidien, de la recherche d’informations à la création. Prenez quelques minutes pour découvrir les idées qui façonnent notre rapport à la technologie.", link: "example:1"),
            .init(title: "Des outils pour travailler autrement", summary: "Une sélection d’actualités pour commencer la journée avec un autre regard. Chercheurs, créateurs et entreprises explorent de nouvelles façons de travailler. Derrière chaque annonce, une même question : comment rendre ces outils utiles, compréhensibles et accessibles au quotidien ?", link: "example:2"),
            .init(title: "Prendre le temps de comprendre", summary: "Au-delà des annonces, les usages se dessinent. Cette page d’exemple présente une mise en forme ; actualisez la source pour lire les titres et les résumés réellement publiés par votre média.", link: "example:3")
        ]], example: true)
    }
}

struct KindlePage: Codable, Equatable {
    static let schemaVersion = 1
    var version = schemaVersion
    var name = "Mon journal du matin"
    var width: Double = 1072
    var height: Double = 1448
    var background: Double = 1
    var blocks: [PageBlock] = []
    var assets: [EmbeddedAsset] = []
    var fonts: [EmbeddedFont] = []
    var schedule = UpdateSchedule()
    var sources = SourceSnapshot.sample
    var updatedAt = Date()
    var templateID: String?

    static func journal() -> Self {
        var page = Self()
        var date = PageBlock.make(.date, y: 52)
        date.fontSize = 24
        var title = PageBlock.make(.text, y: 112)
        title.text = "Bonjour, Florent."; title.fontName = "Newsreader"; title.fontSize = 76; title.height = 112
        let line = PageBlock.make(.divider, y: 244)
        var weather = PageBlock.make(.weather, y: 286)
        weather.height = 224; weather.weatherStyle = "compact"; weather.fontName = "Inter"
        var news = PageBlock.make(.news, y: 552)
        news.fontName = "Newsreader"; news.fontSize = 38; news.height = 580; news.articleCount = 3; news.summaryLines = 5
        let rule = PageBlock.make(.divider, y: 1240)
        var footer = PageBlock.make(.text, y: 1280)
        footer.text = "Un instant pour lire le monde."; footer.fontSize = 26; footer.ink = 0.4
        var clock = PageBlock.make(.clock, x: 760, y: 1280)
        clock.width = 248; clock.height = 70; clock.fontSize = 40; clock.alignment = "right"
        page.blocks = [date, title, line, weather, news, rule, footer, clock]
        return page
    }

    static func decode(_ data: Data) throws -> Self {
        guard data.count < 100_000_000 else { throw PageError.invalid("Ce document dépasse la limite de 100 Mo.") }
        let page = try JSONDecoder().decode(Self.self, from: data)
        guard page.version == schemaVersion else { throw PageError.invalid("Version du document non prise en charge.") }
        guard (300...2400).contains(page.width), (300...3200).contains(page.height), page.blocks.count <= 200 else {
            throw PageError.invalid("Dimensions ou nombre de composants invalides.")
        }
        for b in page.blocks {
            let numbers = [b.x, b.y, b.width, b.height, b.fontSize, b.opacity, b.padding, b.lineSpacing]
            guard numbers.allSatisfy(\.isFinite), b.width >= 1, b.height >= 1, (6...300).contains(b.fontSize),
                  abs(b.x) <= 5000, abs(b.y) <= 5000, b.width <= 5000, b.height <= 5000 else {
                throw PageError.invalid("Un composant contient des valeurs invalides.")
            }
        }
        guard Set(page.blocks.map(\.id)).count == page.blocks.count,
              Set(page.assets.map(\.id)).count == page.assets.count else {
            throw PageError.invalid("Le document contient des identifiants dupliqués.")
        }
        let s = page.schedule
        guard TimeZone(identifier: s.timezone) != nil,
              (5...1440).contains(s.intervalMinutes), s.weekdays.allSatisfy({ (1...7).contains($0) }),
              [s.startHour, s.endHour, s.lightStartHour, s.lightEndHour].allSatisfy({ (0...23).contains($0) }),
              (1...100).contains(s.lightPercent), (1...600).contains(s.lightSeconds),
              s.fixedTimes.allSatisfy({ $0.range(of: "^([01][0-9]|2[0-3]):[0-5][0-9]$", options: .regularExpression) != nil }) else {
            throw PageError.invalid("Le calendrier contient des valeurs invalides.")
        }
        return page
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}

enum PageError: LocalizedError {
    case invalid(String)
    var errorDescription: String? { if case .invalid(let message) = self { return message }; return nil }
}

extension WeatherSnapshot {
    /// Explicit example matching the user's reference photograph; never live data.
    static var reference: Self {
        func date(_ text:String)->Date { ISO8601DateFormatter().date(from:text)! }
        return .init(temperature:9,code:0,days:[
            .init(day:"Sam. 7",low:3,high:15,code:45,rainProbability:3),
            .init(day:"Dim. 8",low:8,high:19,code:3,rainProbability:3),
            .init(day:"Lun. 9",low:14,high:19,code:61,rainProbability:50)
        ],apparentTemperature:8,humidity:87,windSpeed:5,windDirection:90,isDay:false,high:15,low:3,rainProbability:0,rainAmount:0,uvIndex:3,
        sunrise:date("2026-11-06T06:46:00Z"),sunset:date("2026-11-06T16:44:00Z"),observedAt:date("2026-11-06T17:53:00Z"),hours:[
            .init(time:date("2026-11-06T18:00:00Z"),temperature:9,code:0,isDay:false),
            .init(time:date("2026-11-06T21:00:00Z"),temperature:6,code:45,isDay:false),
            .init(time:date("2026-11-07T00:00:00Z"),temperature:5,code:45,isDay:false),
            .init(time:date("2026-11-07T03:00:00Z"),temperature:3,code:45,isDay:false)
        ])
    }
}
