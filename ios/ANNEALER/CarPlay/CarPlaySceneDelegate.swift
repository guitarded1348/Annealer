import CarPlay
import Combine
import UIKit

/// The lehr in the car. CarPlay only allows Apple's templates, so this is the plain version:
/// one list with a section per chamber, sealed chambers shown as locked rows, and the
/// now-playing screen with one extra button, the thermometer, which starts or stops a 30-minute slow cool.
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private var root: CPListTemplate?
    private var bag = Set<AnyCancellable>()

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        let template = CPListTemplate(title: "ANNEALER", sections: sections())
        root = template
        interfaceController.setRootTemplate(template, animated: false, completion: nil)
        configureNowPlaying()

        ContentStore.shared.$content
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &bag)
        AudioPlayer.shared.$index
            .combineLatest(AudioPlayer.shared.$isPlaying)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &bag)
        // chambers open on their own schedule; check once a minute
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &bag)

        Task { await ContentStore.shared.refresh() }
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        self.interfaceController = nil
        root = nil
        bag.removeAll()
    }

    private func refresh() {
        root?.updateSections(sections())
    }

    private func sections() -> [CPListSection] {
        let content = ContentStore.shared.content
        let player = AudioPlayer.shared
        var result: [CPListSection] = []

        let bench = TestBench.tracks
        if !bench.isEmpty {
            result.append(CPListSection(items: bench.map { item(for: $0, in: bench, player: player) },
                                        header: "Test Bench", sectionIndexTitle: nil))
        }

        for chamber in Kiln.chambers(content) {
            let header = "Chamber \(chamber.numeral) · \(chamber.phase.name)"
            var items: [CPListItem]
            if chamber.state == .open {
                items = chamber.tracks.map { item(for: $0, in: chamber.tracks, player: player) }
            } else {
                let sealed = CPListItem(text: sealedTitle(chamber), detailText: sealedDetail(chamber),
                                        image: UIImage(named: "LehrAsleep"))
                sealed.isEnabled = false
                items = [sealed]
            }
            if items.isEmpty {
                let empty = CPListItem(text: "Nothing inside yet", detailText: nil)
                empty.isEnabled = false
                items = [empty]
            }
            result.append(CPListSection(items: items, header: header, sectionIndexTitle: nil))
        }
        return result
    }

    private func item(for track: PlayableTrack, in queue: [PlayableTrack], player: AudioPlayer) -> CPListItem {
        let row = CPListItem(text: track.track.title, detailText: track.track.object, image: UIImage(named: "LehrMini"))
        row.isPlaying = player.current?.id == track.id && player.isPlaying
        row.playingIndicatorLocation = .trailing
        row.handler = { [weak self] _, completion in
            player.play(track, in: queue)
            self?.showNowPlaying()
            completion()
        }
        return row
    }

    private func showNowPlaying() {
        guard let controller = interfaceController else { return }
        if controller.topTemplate !== CPNowPlayingTemplate.shared {
            controller.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
        }
    }

    private func configureNowPlaying() {
        let nowPlaying = CPNowPlayingTemplate.shared
        nowPlaying.isUpNextButtonEnabled = false
        nowPlaying.isAlbumArtistButtonEnabled = false
        let thermometer = UIImage(systemName: "thermometer.low") ?? UIImage()
        let slowCool = CPNowPlayingImageButton(image: thermometer) { _ in
            let player = AudioPlayer.shared
            if player.cooldownEnds == nil { player.coolDown(minutes: 30) } else { player.cancelCoolDown() }
        }
        nowPlaying.updateNowPlayingButtons([slowCool])
    }

    private func sealedTitle(_ chamber: Chamber) -> String {
        switch chamber.state {
        case .dated:
            if let r = chamber.release { return "Sealed · opens \(ADate.short.string(from: r))" }
            return "Sealed"
        case .heating: return "Heating"
        case .cold: return "Cold"
        case .open: return "Open"
        }
    }

    private func sealedDetail(_ chamber: Chamber) -> String {
        switch chamber.state {
        case .dated:
            guard let r = chamber.release else { return "" }
            let days = max(0, Int(ceil(r.timeIntervalSince(Clock.now()) / 86_400)))
            return "\(days) \(days == 1 ? "day" : "days") to go"
        case .heating: return "No date yet. It opens when it's ready."
        case .cold: return "Waits for the chamber before it."
        case .open: return ""
        }
    }
}
