import Foundation

/// The same four chamber states as the website (js/main.js):
///   open     release date has passed: tracks are playable
///   dated    sealed with a release date: cooling gauge and countdown
///   heating  first chamber with no date: gauge creeps up from the day the lehr was lit
///   cold     any later chamber with no date: waits its turn at ambient
enum ChamberState {
    case open, dated, heating, cold
}

struct PlayableTrack: Identifiable, Equatable {
    let id: String
    let track: Track
    let phaseID: String
    let phaseName: String
    let chamberNo: String
    let chamberTemp: Double
    let phaseNote: String
    let intakeNumber: Int
    let url: URL

    var isPlaceholder: Bool { AudioSource.isPlaceholder(track.audio) }

    static func == (a: PlayableTrack, b: PlayableTrack) -> Bool { a.id == b.id }
}

struct Chamber: Identifiable {
    let id: String
    let index: Int
    let numeral: String
    let phase: Phase
    let state: ChamberState
    let release: Date?
    let sealed: Date?
    let tracks: [PlayableTrack]
    let objectCount: Int
    let isExample: Bool
}

enum Kiln {
    static let numerals = ["I", "II", "III", "IV", "V", "VI"]
    static let intakeBase = 273 // intake numbers start at absolute zero, in kelvin

    static func chambers(_ content: SiteContent, now: Date = Clock.now()) -> [Chamber] {
        var undatedSeen = false
        var intake = intakeBase
        var result: [Chamber] = []

        for (i, phase) in content.phases.enumerated() {
            let example = (content.site.showExamples ?? false) && i == 0
            let raw = example ? (content.exampleTracks ?? []) : phase.tracks
            let release = ADate.parse(phase.releaseDate)
            let numeral = i < numerals.count ? numerals[i] : String(i + 1)

            let state: ChamberState
            if example {
                state = .open
            } else if let r = release {
                state = now >= r ? .open : .dated
            } else {
                state = undatedSeen ? .cold : .heating
                undatedSeen = true
            }

            var tracks: [PlayableTrack] = []
            for (j, t) in raw.enumerated() {
                tracks.append(PlayableTrack(
                    id: "\(phase.id)-\(j)", track: t, phaseID: phase.id, phaseName: phase.name,
                    chamberNo: numeral, chamberTemp: phase.chamberTemp, phaseNote: phase.note,
                    intakeNumber: intake + j, url: AudioSource.url(for: t.audio)))
            }
            intake += raw.count

            result.append(Chamber(
                id: phase.id, index: i, numeral: numeral, phase: phase, state: state,
                release: release, sealed: ADate.parse(phase.sealedOn),
                tracks: state == .open ? tracks : [], objectCount: raw.count, isExample: example))
        }
        return result
    }

    static func temperature(of chamber: Chamber, content: SiteContent, now: Date = Clock.now()) -> Double {
        let ambient = content.site.ambient
        let top = chamber.phase.chamberTemp
        switch chamber.state {
        case .open, .cold:
            return ambient
        case .heating:
            let lit = ADate.parse(content.site.litOn) ?? now
            let days = max(0, now.timeIntervalSince(lit) / 86_400)
            return ambient + (top - ambient) * (1 - exp(-days / 90))
        case .dated:
            guard let release = chamber.release else { return ambient }
            let left = release.timeIntervalSince(now)
            var frac = 1.0
            if let sealed = chamber.sealed {
                frac = min(1, max(0, left / max(1, release.timeIntervalSince(sealed))))
            }
            return ambient + frac * (top - ambient)
        }
    }

    static func statusLine(_ chamber: Chamber) -> String {
        switch chamber.state {
        case .open:
            if chamber.isExample { return "Example · not real yet" }
            if let r = chamber.release { return "Open · since \(ADate.long.string(from: r))" }
            return "Open"
        case .dated: return "Sealed"
        case .heating: return "Heating · no date yet"
        case .cold: return "Cold · not yet loaded"
        }
    }

    static func whenLine(_ chamber: Chamber) -> String {
        switch chamber.state {
        case .dated:
            if let r = chamber.release { return "Opens \(ADate.longWithTime.string(from: r))" }
            return ""
        case .heating: return "No date yet. It opens when it's ready, and not before."
        case .cold: return "Waits for the chamber before it."
        case .open: return ""
        }
    }

    static func stamp(for phaseID: String) -> String {
        switch phaseID {
        case "heat": return "Received hot"
        case "soak": return "Holding"
        case "cool": return "Cooled"
        default: return "On the bench"
        }
    }

    /// Everything playable right now, in order (used by CarPlay and "play all").
    static func playable(_ content: SiteContent) -> [PlayableTrack] {
        TestBench.tracks + chambers(content).flatMap { $0.tracks }
    }
}

/// Where a track's audio comes from.
///   ""                    → the lehr's placeholder hum (bundled)
///   "bundle:file.m4a"     → a file inside the app (unreleased tests; never on the website)
///   "audio/file.mp3"      → relative to the website
///   "https://…"           → anywhere
enum AudioSource {
    static var hum: URL { Bundle.main.url(forResource: "lehr-hum", withExtension: "m4a")! }

    static func isPlaceholder(_ audio: String?) -> Bool {
        (audio ?? "").trimmingCharacters(in: .whitespaces).isEmpty
    }

    static func url(for audio: String?) -> URL {
        guard let a = audio?.trimmingCharacters(in: .whitespaces), !a.isEmpty else { return hum }
        if a.hasPrefix("bundle:") {
            let name = String(a.dropFirst("bundle:".count)) as NSString
            return Bundle.main.url(forResource: name.deletingPathExtension, withExtension: name.pathExtension) ?? hum
        }
        if let u = URL(string: a, relativeTo: Config.siteURL) { return u.absoluteURL }
        if let encoded = a.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
           let u = URL(string: encoded, relativeTo: Config.siteURL) { return u.absoluteURL }
        return hum
    }
}
