import Foundation
import UserNotifications

/// "Ring me when a chamber opens": local notifications scheduled from the release dates.
/// No server needed; they're rescheduled whenever new content arrives from the website.
enum Notifications {
    private static let key = "annealer.ringMe"

    static var enabled: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    static func enable(_ content: SiteContent, completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                Notifications.enabled = granted
                if granted { Notifications.reschedule(content) }
                completion(granted)
            }
        }
    }

    static func disable() {
        enabled = false
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    static func reschedule(_ content: SiteContent) {
        guard enabled else { return }
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for chamber in Kiln.chambers(content) where chamber.state == .dated {
            guard let release = chamber.release else { continue }
            let wait = release.timeIntervalSince(Clock.now())
            guard wait > 1 else { continue }
            let note = UNMutableNotificationContent()
            note.title = "Chamber \(chamber.numeral) is open"
            note.body = "\(chamber.phase.name) has cooled enough. \(chamber.phase.note)"
            note.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: wait, repeats: false)
            center.add(UNNotificationRequest(identifier: "chamber-\(chamber.id)", content: note, trigger: trigger))
        }
    }
}

/// The counter: posts to the same Netlify form the website uses, so signups land in one list.
enum CounterDesk {
    private static let nameKey = "annealer.name"

    static var savedName: String? {
        get { UserDefaults.standard.string(forKey: nameKey) }
        set { UserDefaults.standard.set(newValue, forKey: nameKey) }
    }

    static func sign(name: String, email: String) async -> Bool {
        var request = URLRequest(url: Config.siteURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var form = URLComponents()
        form.queryItems = [
            URLQueryItem(name: "form-name", value: "counter"),
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "email", value: email),
        ]
        // URLComponents leaves "+" alone, which a form body would read as a space.
        request.httpBody = form.percentEncodedQuery?
            .replacingOccurrences(of: "+", with: "%2B")
            .data(using: .utf8)
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            return (200..<400).contains(code)
        } catch {
            return false
        }
    }

    static func looksLikeEmail(_ text: String) -> Bool {
        text.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]{2,}$"#, options: .regularExpression) != nil
    }
}
