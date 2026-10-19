import AVFoundation
import Combine
import MediaPlayer
import UIKit

/// One player for the whole app: the phone screens, the lock screen, and CarPlay all drive this.
final class AudioPlayer: ObservableObject {
    static let shared = AudioPlayer()

    @Published private(set) var queue: [PlayableTrack] = []
    @Published private(set) var index: Int?
    @Published private(set) var isPlaying = false
    @Published private(set) var elapsed: Double = 0
    @Published private(set) var duration: Double = 0
    /// "Slow cool": when set, playback fades out over the last 90 seconds and stops here.
    @Published private(set) var cooldownEnds: Date?

    var current: PlayableTrack? {
        guard let i = index, queue.indices.contains(i) else { return nil }
        return queue[i]
    }

    var progress: Double { duration > 0 ? min(1, max(0, elapsed / duration)) : 0 }

    private let player = AVPlayer()
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var cooldownTimer: Timer?
    private var sessionReady = false

    private lazy var artwork: MPMediaItemArtwork? = {
        guard let image = UIImage(named: "Artwork") else { return nil }
        return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }()

    private init() {
        setupRemoteCommands()
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main
        ) { [weak self] time in
            self?.tick(time)
        }
    }

    // MARK: Playback

    func play(_ track: PlayableTrack, in tracks: [PlayableTrack]) {
        queue = tracks
        load(tracks.firstIndex(of: track) ?? 0)
    }

    func toggle() {
        if isPlaying { pause() } else { resume() }
    }

    func pause() {
        player.pause()
        isPlaying = false
        updateNowPlaying()
    }

    func resume() {
        guard current != nil else { return }
        activateSession()
        player.play()
        isPlaying = true
        updateNowPlaying()
    }

    func next() {
        guard let i = index else { return }
        if i + 1 < queue.count {
            load(i + 1)
        } else {
            pause()
            seek(to: 0)
        }
    }

    func previous() {
        guard let i = index else { return }
        if elapsed > 3 || i == 0 { seek(to: 0) } else { load(i - 1) }
    }

    func seek(to seconds: Double) {
        player.seek(to: CMTime(seconds: max(0, seconds), preferredTimescale: 600))
        elapsed = max(0, seconds)
        updateNowPlaying()
    }

    private func load(_ i: Int) {
        guard queue.indices.contains(i) else { return }
        activateSession()
        index = i
        let item = AVPlayerItem(url: queue[i].url)
        if let old = endObserver { NotificationCenter.default.removeObserver(old) }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            self?.next()
        }
        player.replaceCurrentItem(with: item)
        elapsed = 0
        duration = AudioPlayer.parseDuration(queue[i].track.duration)
        player.play()
        isPlaying = true
        updateNowPlaying()
    }

    private func tick(_ time: CMTime) {
        let seconds = time.seconds
        elapsed = seconds.isFinite ? seconds : 0
        if let d = player.currentItem?.duration.seconds, d.isFinite, d > 0, abs(d - duration) > 0.5 {
            duration = d
            updateNowPlaying()
        }
    }

    static func parseDuration(_ text: String?) -> Double {
        guard let text = text else { return 0 }
        return text.split(separator: ":").compactMap { Double($0) }.reduce(0) { $0 * 60 + $1 }
    }

    // MARK: Slow cool (a sleep timer that fades like the end of an anneal)

    func coolDown(minutes: Double) {
        cooldownEnds = Date().addingTimeInterval(minutes * 60)
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.cooldownTick()
        }
    }

    func cancelCoolDown() {
        cooldownTimer?.invalidate()
        cooldownTimer = nil
        cooldownEnds = nil
        player.volume = 1
    }

    private func cooldownTick() {
        guard let end = cooldownEnds else { return }
        let left = end.timeIntervalSinceNow
        if left <= 0 {
            pause()
            cancelCoolDown()
            return
        }
        player.volume = Float(min(1, left / 90))
    }

    // MARK: System integration

    private func activateSession() {
        guard !sessionReady else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            sessionReady = true
        } catch {
            sessionReady = false
        }
    }

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.toggle()
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.next()
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.previous()
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: event.positionTime)
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let t = current else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: t.track.title,
            MPMediaItemPropertyArtist: "ANNEALER",
            MPMediaItemPropertyAlbumTitle: "Chamber \(t.chamberNo) · \(t.phaseName)",
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
        ]
        if let artwork = artwork { info[MPMediaItemPropertyArtwork] = artwork }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

/// The bench's temperature for a track: starts at its chamber's heat and cools to ambient as it plays.
enum BenchMath {
    static func temperature(_ track: PlayableTrack, progress: Double, ambient: Double) -> Double {
        ambient + (track.chamberTemp - ambient) * (1 - pow(min(1, max(0, progress)), 1.6))
    }
}
