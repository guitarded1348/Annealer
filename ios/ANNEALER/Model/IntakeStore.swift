import Foundation
import Combine

/// "Bring something in": a listener's own lehr. Entries stay on this phone, in a protected file.
struct IntakeItem: Codable, Identifiable {
    let id: UUID
    let text: String
    let broughtIn: Date
    let coolHours: Double
}

final class IntakeStore: ObservableObject {
    static let shared = IntakeStore()

    @Published private(set) var items: [IntakeItem] = []

    private let fileURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("intake.json")
    }()

    private init() {
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([IntakeItem].self, from: data) {
            items = saved
        }
    }

    func bringIn(_ text: String, coolHours: Double) {
        items.insert(IntakeItem(id: UUID(), text: text, broughtIn: Date(), coolHours: max(0.01, coolHours)), at: 0)
        save()
    }

    func letGo(_ item: IntakeItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    private func save() {
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }

    // MARK: The anneal

    static func progress(_ item: IntakeItem, now: Date = Date()) -> Double {
        min(1, max(0, now.timeIntervalSince(item.broughtIn) / (item.coolHours * 3600)))
    }

    static func isCooled(_ item: IntakeItem, now: Date = Date()) -> Bool {
        progress(item, now: now) >= 1
    }

    /// Held at heat for the first 15% (the soak), then a slow cool to ambient.
    static func temperature(_ item: IntakeItem, ambient: Double, top: Double = 565, now: Date = Date()) -> Double {
        let p = progress(item, now: now)
        let cool = p < 0.15 ? 0 : (p - 0.15) / 0.85
        return ambient + (top - ambient) * (1 - pow(cool, 1.4))
    }

    static func timeLeft(_ item: IntakeItem, now: Date = Date()) -> String {
        let seconds = max(0, item.broughtIn.addingTimeInterval(item.coolHours * 3600).timeIntervalSince(now))
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m left" : "\(minutes)m left"
    }

    /// Same note every time for the same entry.
    static func reply(for item: IntakeItem, replies: [String]) -> String {
        guard !replies.isEmpty else { return "" }
        let seed = item.id.uuidString.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return replies[seed % replies.count]
    }
}
