import Foundation
import Combine

/// Holds the site's content. Starts from the last copy fetched (or the one bundled in the app),
/// then refreshes from the website, so new log entries and release dates arrive without an app update.
final class ContentStore: ObservableObject {
    static let shared = ContentStore()

    @Published private(set) var content: SiteContent

    private static let cacheURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("content.json")
    }()

    private init() {
        content = ContentStore.loadCached() ?? ContentStore.loadBundled()
        Clock.previewDate = ADate.parse(content.site.previewDate)
    }

    func refresh() async {
        var request = URLRequest(url: Config.contentURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }
            let fresh = try JSONDecoder().decode(SiteContent.self, from: data)
            try? FileManager.default.createDirectory(at: ContentStore.cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? data.write(to: ContentStore.cacheURL, options: .atomic)
            await MainActor.run {
                self.content = fresh
                Clock.previewDate = ADate.parse(fresh.site.previewDate)
                Notifications.reschedule(fresh)
            }
        } catch {
            // Offline or the site is unreachable: keep what we have.
        }
    }

    private static func loadCached() -> SiteContent? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        return try? JSONDecoder().decode(SiteContent.self, from: data)
    }

    private static func loadBundled() -> SiteContent {
        guard let url = Bundle.main.url(forResource: "content", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let content = try? JSONDecoder().decode(SiteContent.self, from: data) else {
            fatalError("Content/content.json is missing from the app bundle. Run: node scripts/export-content.mjs ios/ANNEALER/Content/content.json")
        }
        return content
    }
}
