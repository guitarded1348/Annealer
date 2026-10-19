import Foundation

/// Where the app finds the website. The site publishes content.json on every deploy,
/// generated from js/data.js, so the website and the app always say the same thing.
enum Config {
    // The live domain, not a redirecting one: a redirect would turn the counter's POST into a GET.
    static let siteURL = URL(string: "https://annealermusic.com/")!
    static var contentURL: URL { siteURL.appendingPathComponent("content.json") }
}

// MARK: - The shape of js/data.js

struct SiteContent: Codable {
    var site: SiteInfo
    var heroLine: String
    var kilnsLede: String?
    var lehrLines: [String]
    var lehrSeventh: String
    var workshop: Workshop
    var log: KeeperLog?
    var phases: [Phase]
    var exampleTracks: [Track]?
    var intake: IntakeCopy?
    var counter: CounterCopy
    var footer: String?
    var credits: String?
}

struct SiteInfo: Codable {
    var name: String
    var litOn: String
    var ambient: Double
    var showExamples: Bool?
    var previewDate: String?
}

struct Workshop: Codable {
    var title: String
    var lore: [Lore]
    var signoff: String?
}

struct Lore: Codable {
    var text: String
    var ink: Bool?
}

struct KeeperLog: Codable {
    var show: Int?
    var entries: [LogEntry]
}

struct LogEntry: Codable, Identifiable {
    var date: String
    var text: String
    var id: String { date + text }
}

struct Phase: Codable, Identifiable {
    var id: String
    var name: String
    var chamberTemp: Double
    var sealedOn: String?
    var releaseDate: String?
    var summary: String
    var note: String
    var tracks: [Track]
}

struct Track: Codable {
    var title: String
    var object: String
    var condition: String?
    var note: String
    var duration: String?
    var audio: String?
}

struct IntakeCopy: Codable {
    var title: String
    var prompt: String
    var placeholder: String
    var button: String
    var coolHours: Double
    var empty: String
    var replies: [String]

    static let fallback = IntakeCopy(
        title: "Bring something in",
        prompt: "What made you hot today? Write it down and leave it in the lehr.",
        placeholder: "It started when…",
        button: "Leave it in the lehr",
        coolHours: 24,
        empty: "Nothing on the bench.",
        replies: ["Cooled. It looks smaller from here. Most things do."]
    )
}

struct CounterCopy: Codable {
    var title: String
    var intro: String
    var button: String
    var replies: [String]?
    var thanks: String?
    var returning: String
    var selfName: String
    var badEmail: String
    var noName: String
    var failed: String?
}

// MARK: - Dates and time

enum ADate {
    /// Reads the date formats used in data.js: full ISO 8601 with offset, or a bare "yyyy-MM-dd".
    static func parse(_ string: String?) -> Date? {
        guard let s = string, !s.isEmpty else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: s) { return d }
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: s) { return d }
        let day = DateFormatter()
        day.locale = Locale(identifier: "en_US_POSIX")
        day.dateFormat = "yyyy-MM-dd"
        return day.date(from: s)
    }

    static let long: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    static let longWithTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        return f
    }()

    static let short: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMM d")
        return f
    }()
}

/// The app's idea of "now". `site.previewDate` in data.js moves it, exactly as on the website.
enum Clock {
    static let launched = Date()
    static var previewDate: Date?

    static func now() -> Date {
        if let p = previewDate { return p.addingTimeInterval(Date().timeIntervalSince(launched)) }
        return Date()
    }

    static func daysSince(_ date: Date, now: Date = Clock.now()) -> Int {
        max(0, Int(floor(now.timeIntervalSince(date) / 86_400)))
    }
}
