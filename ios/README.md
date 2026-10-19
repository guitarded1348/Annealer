# ANNEALER for iPhone (and CarPlay)

The box-set edition of the site. Same workshop, different package: you unbox a crate, the lehr
ignites, and you work the machine itself. Chamber doors swing open, tags hang on a rail, the
now-playing tag sways on a hook and cools as the song plays.

## Open it

1. Pull the repo on your Mac and open `ios/ANNEALER.xcodeproj` in Xcode (16 or newer).
2. Click the **ANNEALER** project in the sidebar → **ANNEALER** target → **Signing & Capabilities**.
   Pick your **Team**. If Xcode says the bundle ID is taken, change `com.abeytaaudio.annealer`
   to something unique to you.
3. Choose an iPhone simulator and press **Run** (⌘R).

To see the unboxing again, delete the app from the simulator and run it again.

## Try CarPlay in the simulator

With the app running in the simulator: **I/O → External Displays → CarPlay**. The ANNEALER icon
appears on the CarPlay screen. Simulator builds already carry the CarPlay audio entitlement
(`Config/ANNEALER-CarPlay.entitlements`).

**On a real iPhone and in a real car**, Apple must grant your developer account the CarPlay audio
entitlement first: request it at developer.apple.com/contact/carplay (category: audio). Until then,
device builds use `Config/ANNEALER.entitlements`, which leaves CarPlay out so signing works.
Once Apple approves it, point `CODE_SIGN_ENTITLEMENTS` (target → Build Settings) at
`Config/ANNEALER-CarPlay.entitlements` for all SDKs.

## Where the content comes from

The app reads the same `js/data.js` as the website. Every Netlify deploy publishes it as
`content.json`, and the app downloads it on launch. So new log entries, release dates and tracks
show up in the app without an App Store update.

The app also ships a copy for offline first launch, `ANNEALER/Content/content.json`. Refresh it
before each App Store build:

```sh
node scripts/export-content.mjs ios/ANNEALER/Content/content.json
```

## Testing an unreleased song

The **Test Bench** shows up only in Debug builds (what Xcode's Run button makes), never on the
website and never in App Store builds.

1. Drop the file (`.m4a`, `.mp3`, `.wav`) into `ios/ANNEALER/Audio/`.
2. Add an entry in `ANNEALER/Model/TestBench.swift` with `audio: "bundle:your-file.m4a"`.

Songs with an empty `audio` play the lehr's placeholder hum.

## What's inside

| On the floor | What it is |
|---|---|
| Porthole | The lehr's eye. Poke it. Seven times, if you're brave. |
| Chamber doors | Heat, Soak, Slow Cool. Open doors swing wide; sealed doors rattle and show their gauge and countdown. |
| The Log | The Keeper's Log, on a clipboard. |
| Liner Notes | The Workshop lore as a paper booklet. Two pages are printed in invisible ink: press and hold. |
| Bring In | Write down what made you hot; it rides the conveyor into the lehr and comes out cooled a day later with a note. Stays on the phone. |
| Counter | Ring the bell, leave your name. Goes to the same Netlify list as the website. |
| On the hook | Now playing. The scrubber is a cooling curve. **Slow cool** is a sleep timer that fades out. |

Lock screen, Control Center, AirPods and steering-wheel controls all work. Notifications for
chamber openings are scheduled on the phone from the release dates; no server needed.

## Files

```
ANNEALER/App         entry point, unboxing-or-floor switch
ANNEALER/Model       content (mirrors js/data.js), chamber logic, intake journal, notifications, counter
ANNEALER/Audio       the player (+ lock screen / CarPlay controls) and the placeholder hum
ANNEALER/Views       the floor, chamber room, hook, booklet, clipboard, counter, intake, unboxing
ANNEALER/CarPlay     the CarPlay list and now-playing screen
ANNEALER/Fonts       Big Shoulders Display and IM Fell English (SIL Open Font License)
Config               Info.plist and entitlements
```
