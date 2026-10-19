import SwiftUI
import UIKit

/// Inside one chamber. An open chamber's door swings away to show the tags hanging on a rail;
/// flick through them like records in a crate. A sealed door stays shut and rattles when you try it.
struct ChamberRoom: View {
    let chamberID: String
    @EnvironmentObject var store: ContentStore
    @EnvironmentObject var player: AudioPlayer
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @State var doorAngle: Double = 0
    @State var rattles = 0
    @State var tried = false
    @State var page = 0
    @State var ringMe = Notifications.enabled

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            let now = Clock.now()
            if let chamber = resolve(now) {
                room(chamber, now: now)
            } else {
                Text("This chamber isn't here anymore.")
                    .font(AFont.narratorItalic(20))
                    .foregroundStyle(Palette.bone)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Palette.soot.ignoresSafeArea())
                    .onTapGesture { dismiss() }
            }
        }
    }

    private func resolve(_ now: Date) -> Chamber? {
        if chamberID == TestBench.chamberID { return TestBench.chamber }
        return Kiln.chambers(store.content, now: now).first { $0.id == chamberID }
    }

    // MARK: The room

    @ViewBuilder
    private func room(_ chamber: Chamber, now: Date) -> some View {
        let color = Palette.chamber(chamber.phase.id)
        let isOpen = chamber.state == .open
        ZStack {
            // the interior: firebrick dark, lit by the chamber
            ZStack {
                Palette.soot3
                RadialGradient(colors: [color.opacity(isOpen ? 0.5 : 0.12), .clear], center: .center, startRadius: 0, endRadius: 480)
            }
            .ignoresSafeArea()

            if isOpen {
                interior(chamber)
            }

            if doorAngle > -95 {
                DoorFace(chamber: chamber, content: store.content, now: now, tried: tried, ringMe: $ringMe)
                    .rattle(rattles)
                    .rotation3DEffect(.degrees(doorAngle), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.55)
                    .onTapGesture {
                        guard !isOpen else { return }
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        withAnimation(.linear(duration: 0.45)) { rattles += 1 }
                        tried = true
                    }
            }

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Label("Shut the door", systemImage: "xmark")
                            .font(AFont.label(14))
                            .tracking(1.2)
                            .foregroundStyle(Palette.bone)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Palette.soot.opacity(0.8)))
                    }
                    Spacer()
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
        }
        .onAppear {
            guard isOpen else { return }
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            if reduceMotion {
                doorAngle = -100
            } else {
                withAnimation(.easeInOut(duration: 0.95).delay(0.2)) { doorAngle = -100 }
            }
        }
    }

    private func interior(_ chamber: Chamber) -> some View {
        VStack(spacing: 10) {
            VStack(spacing: 4) {
                Eyebrow("Chamber \(chamber.numeral) · \(Kiln.statusLine(chamber))", color: Palette.boneDim, size: 12)
                Text(chamber.phase.name.uppercased())
                    .font(AFont.display(44, relativeTo: .largeTitle))
                    .foregroundStyle(Palette.bone)
            }
            .padding(.top, 56)

            // the rail the tags hang from
            Rectangle().fill(Palette.bone.opacity(0.8)).frame(height: 3).padding(.horizontal, 10)

            TabView(selection: $page) {
                ForEach(Array(chamber.tracks.enumerated()), id: \.offset) { item in
                    VStack(spacing: 0) {
                        Rectangle().fill(Palette.boneDim).frame(width: 1.5, height: 22)
                        ScrollView {
                            TagView(track: item.element, tilt: item.offset % 2 == 0 ? -0.8 : 0.7) {
                                player.play(item.element, in: chamber.tracks)
                            }
                            .padding(.horizontal, 26)
                            .padding(.bottom, 40)
                        }
                    }
                    .tag(item.offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))

            if chamber.tracks.count > 1 {
                Button {
                    if let first = chamber.tracks.first { player.play(first, in: chamber.tracks) }
                } label: {
                    Label("Play the whole chamber", systemImage: "play.fill")
                        .font(AFont.label(16))
                        .tracking(1.4)
                        .foregroundStyle(Palette.soot)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Palette.straw))
                }
                .padding(.bottom, 12)
            }
        }
    }
}

/// The face of a chamber door. Sealed doors carry the gauge, the countdown, and a bell-pull.
struct DoorFace: View {
    let chamber: Chamber
    let content: SiteContent
    let now: Date
    let tried: Bool
    @Binding var ringMe: Bool

    var body: some View {
        let color = Palette.chamber(chamber.phase.id)
        let temp = Kiln.temperature(of: chamber, content: content, now: now)
        ScrollView {
            VStack(spacing: 14) {
                Eyebrow("Chamber \(chamber.numeral) · \(Int(chamber.phase.chamberTemp)) °C", color: Palette.boneDim, size: 12)
                    .padding(.top, 80)
                Text(chamber.phase.name.uppercased())
                    .font(AFont.display(56, relativeTo: .largeTitle))
                    .foregroundStyle(Palette.bone)
                Text(Kiln.statusLine(chamber).uppercased())
                    .font(AFont.label(13))
                    .tracking(2)
                    .foregroundStyle(Palette.boneDim)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(Palette.boneDim))
                Text(chamber.phase.summary)
                    .font(AFont.narratorItalic(18))
                    .foregroundStyle(Palette.boneDim)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if chamber.state != .open {
                    GaugeView(temperature: temp)
                        .frame(maxWidth: 300)
                        .accessibilityLabel("Chamber at \(Int(temp.rounded())) degrees Celsius")
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(temp.rounded()))").font(AFont.display(60)).monospacedDigit()
                        Text("°C").font(AFont.label(20)).foregroundStyle(Palette.boneDim)
                    }
                    .foregroundStyle(Palette.bone)
                    if chamber.state == .dated, let release = chamber.release {
                        Countdown(seconds: max(0, release.timeIntervalSince(now)))
                    }
                    Text(Kiln.whenLine(chamber))
                        .font(AFont.narrator(16))
                        .foregroundStyle(Palette.boneDim)
                        .multilineTextAlignment(.center)
                    Eyebrow(chamber.objectCount > 0
                            ? "\(chamber.objectCount) \(chamber.objectCount == 1 ? "object" : "objects") inside · contents withheld"
                            : "Objects still arriving",
                            color: Palette.boneDim, size: 12)

                    Toggle(isOn: Binding(
                        get: { ringMe },
                        set: { on in
                            if on {
                                Notifications.enable(content) { granted in ringMe = granted }
                            } else {
                                Notifications.disable()
                                ringMe = false
                            }
                        }
                    )) {
                        Text("RING ME WHEN IT OPENS")
                            .font(AFont.label(14))
                            .tracking(1.4)
                            .foregroundStyle(Palette.bone)
                    }
                    .tint(Palette.straw)
                    .padding(12)
                    .background(Palette.soot)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Palette.rule))
                    .padding(.horizontal, 8)
                }

                Text("“\(chamber.phase.note)”")
                    .font(AFont.narratorItalic(19))
                    .foregroundStyle(Palette.bone)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if tried && chamber.state != .open {
                    Text("The door won't budge. It isn't being difficult. It's being careful.")
                        .font(AFont.narratorItalic(16))
                        .foregroundStyle(Temper.ink(0))
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 40)
        }
        .background(
            ZStack {
                ArchShape().fill(Palette.soot2)
                ArchShape().stroke(color.opacity(0.85), lineWidth: 3)
                Rivets(inset: 18)
            }
            .padding(.horizontal, 8)
            .padding(.top, 50)
            .ignoresSafeArea(edges: .bottom)
        )
    }
}
