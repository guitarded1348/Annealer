import SwiftUI

/// Now playing: the tag hangs on the hook and sways. It starts at its chamber's heat and
/// cools to room temperature as the song plays; the scrubber is the cooling curve itself.
struct BenchView: View {
    @EnvironmentObject var player: AudioPlayer
    @EnvironmentObject var store: ContentStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State var scrub: Double?

    var body: some View {
        let shown = scrub ?? player.progress
        ZStack {
            SootBackground(glow: Temper.fill(shown), glowStrength: 0.4)
            if let t = player.current {
                let temp = BenchMath.temperature(t, progress: shown, ambient: store.content.site.ambient)
                ScrollView {
                    VStack(spacing: 18) {
                        HStack(alignment: .firstTextBaseline) {
                            Eyebrow("On the hook · Chamber \(t.chamberNo)", color: Palette.boneDim, size: 12)
                            Spacer()
                            Button("Done") { dismiss() }
                                .font(AFont.label(15))
                                .foregroundStyle(Palette.bone)
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(Int(temp.rounded()))")
                                .font(AFont.display(84))
                                .monospacedDigit()
                                .foregroundStyle(Temper.ink(shown))
                            Text("°C").font(AFont.label(24)).foregroundStyle(Palette.boneDim)
                            Spacer()
                            Text(phaseWord(shown).uppercased())
                                .font(AFont.label(14))
                                .tracking(2)
                                .foregroundStyle(Palette.boneDim)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(Int(temp.rounded())) degrees and cooling")

                        hangingTag(t, progress: shown)

                        CoolingCurve(progress: shown) { value in
                            scrub = value
                        } onCommit: { value in
                            player.seek(to: value * max(1, player.duration))
                            scrub = nil
                        }
                        .frame(height: 74)

                        HStack {
                            Text(clock(shown * player.duration))
                            Spacer()
                            Text(clock(player.duration))
                        }
                        .font(AFont.label(14))
                        .monospacedDigit()
                        .foregroundStyle(Palette.boneDim)

                        HStack(spacing: 30) {
                            Button { player.previous() } label: { Image(systemName: "backward.fill") }
                                .buttonStyle(MachineButtonStyle(size: 58))
                                .accessibilityLabel("Previous")
                            Button { player.toggle() } label: { Image(systemName: player.isPlaying ? "pause.fill" : "play.fill") }
                                .buttonStyle(MachineButtonStyle(size: 84, hot: true))
                                .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
                            Button { player.next() } label: { Image(systemName: "forward.fill") }
                                .buttonStyle(MachineButtonStyle(size: 58))
                                .accessibilityLabel("Next")
                        }
                        .padding(.vertical, 6)

                        SlowCoolControl()

                        Text("“\(t.phaseNote)”")
                            .font(AFont.narratorItalic(18))
                            .foregroundStyle(Palette.bone)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                }
            } else {
                Text("Nothing on the hook.")
                    .font(AFont.narratorItalic(22))
                    .foregroundStyle(Palette.boneDim)
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func hangingTag(_ t: PlayableTrack, progress: Double) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion || !player.isPlaying)) { context in
            let swing = reduceMotion ? 0 : sin(context.date.timeIntervalSinceReferenceDate * 1.25) * 1.8
            VStack(spacing: 0) {
                HookShape()
                    .stroke(Palette.bone, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 26, height: 30)
                Rectangle().fill(Palette.boneDim).frame(width: 1.5, height: 22)
                TagView(track: t, showPlayer: false) {}
                    .shadow(color: Temper.fill(progress).opacity(0.55), radius: 26)
            }
            .rotationEffect(.degrees(swing), anchor: .top)
        }
    }

    private func phaseWord(_ p: Double) -> String {
        p < 0.12 ? "Heat" : p < 0.35 ? "Soak" : p < 0.97 ? "Slow cool" : "Ambient"
    }

    private func clock(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "0:00" }
        let s = max(0, Int(seconds))
        return "\(s / 60):\(String(format: "%02d", s % 60))"
    }
}

/// The hook the tag hangs from.
struct HookShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY + h * 0.55))
        p.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.5, y: rect.maxY),
                       control: CGPoint(x: rect.minX + w * 0.95, y: rect.minY + h * 0.95))
        p.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.12, y: rect.minY + h * 0.62),
                       control: CGPoint(x: rect.minX + w * 0.1, y: rect.maxY))
        return p
    }
}

/// The scrubber: the slow-cool half of an annealing curve. Drag along it to move through the song.
struct CoolingCurve: View {
    let progress: Double
    let onScrub: (Double) -> Void
    let onCommit: (Double) -> Void

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let pad: CGFloat = 10
            let point: (Double) -> CGPoint = { x in
                let cool = 1 - pow(min(1, max(0, x)), 1.6)
                return CGPoint(x: pad + CGFloat(x) * (w - pad * 2), y: pad + CGFloat(1 - cool) * (h - pad * 2))
            }
            ZStack {
                Path { p in
                    p.move(to: point(0))
                    for i in 1...60 { p.addLine(to: point(Double(i) / 60)) }
                }
                .stroke(Palette.boneDim.opacity(0.45), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))

                Path { p in
                    p.move(to: point(0))
                    let steps = max(1, Int(progress * 60))
                    for i in 1...steps { p.addLine(to: point(min(progress, Double(i) / 60))) }
                }
                .stroke(Temper.ink(progress), style: StrokeStyle(lineWidth: 3, lineCap: .round))

                Circle()
                    .fill(Temper.ink(progress))
                    .frame(width: 18, height: 18)
                    .shadow(color: Temper.fill(progress), radius: 8)
                    .position(point(progress))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in onScrub(fraction(v.location.x, width: w, pad: pad)) }
                    .onEnded { v in onCommit(fraction(v.location.x, width: w, pad: pad)) }
            )
        }
        .accessibilityElement()
        .accessibilityLabel("Position in the song")
        .accessibilityValue("\(Int(progress * 100)) percent")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onCommit(min(1, progress + 0.05))
            case .decrement: onCommit(max(0, progress - 0.05))
            @unknown default: break
            }
        }
    }

    private func fraction(_ x: CGFloat, width: CGFloat, pad: CGFloat) -> Double {
        Double(min(1, max(0, (x - pad) / max(1, width - pad * 2))))
    }
}

/// "Slow cool": a sleep timer that fades out over the last minute and a half.
struct SlowCoolControl: View {
    @EnvironmentObject var player: AudioPlayer

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            Menu {
                ForEach([15, 30, 45, 60], id: \.self) { minutes in
                    Button("Cool down over \(minutes) minutes") { player.coolDown(minutes: Double(minutes)) }
                }
                if player.cooldownEnds != nil {
                    Button("Keep it hot", role: .destructive) { player.cancelCoolDown() }
                }
            } label: {
                Label(label, systemImage: "thermometer.low")
                    .font(AFont.label(15))
                    .tracking(1.4)
                    .foregroundStyle(player.cooldownEnds == nil ? Palette.bone : Temper.ink(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .overlay(Capsule().stroke(Palette.rule))
            }
        }
    }

    private var label: String {
        guard let end = player.cooldownEnds else { return "SLOW COOL" }
        let minutes = max(1, Int(ceil(end.timeIntervalSinceNow / 60)))
        return "COOLING · \(minutes) MIN LEFT"
    }
}
