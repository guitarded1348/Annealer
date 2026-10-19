import Foundation

/// Debug builds only: tracks that live inside the app for testing and never touch the website.
/// To test a song: drop the file into ios/ANNEALER/Audio, then add an entry below with
/// audio: "bundle:<file name>". Release (App Store) builds leave the test bench out entirely.
enum TestBench {
    static let chamberID = "test"

    static let entries: [Track] = [
        Track(
            title: "Lehr Hum",
            object: "The lehr itself, recorded through the door.",
            condition: "Warm.",
            note: "It hums when it's thinking. It's always thinking.",
            duration: "0:40",
            audio: "bundle:lehr-hum.m4a"
        ),
    ]

    static var tracks: [PlayableTrack] {
        #if DEBUG
        return entries.enumerated().map { i, t in
            PlayableTrack(
                id: "test-\(i)", track: t, phaseID: chamberID, phaseName: "Test Bench",
                chamberNo: "0", chamberTemp: 565, phaseNote: "Nobody else hears these. Yet.",
                intakeNumber: i, url: AudioSource.url(for: t.audio))
        }
        #else
        return []
        #endif
    }

    /// The test bench as a chamber, so it opens like any other.
    static var chamber: Chamber {
        let phase = Phase(
            id: chamberID, name: "Test Bench", chamberTemp: 565, sealedOn: nil, releaseDate: nil,
            summary: "Nobody else hears these. They're inside the app, not on the website.",
            note: "Nobody else hears these. Yet.", tracks: entries)
        return Chamber(
            id: chamberID, index: 0, numeral: "0", phase: phase, state: .open, release: nil, sealed: nil,
            tracks: tracks, objectCount: tracks.count, isExample: false)
    }
}
