import SwiftUI
import UIKit

// Shared pieces of the workshop: gauges, tags, the name, the lehr.

struct Countdown: View {
    let seconds: Double

    var body: some View {
        let s = Int(seconds)
        HStack(spacing: 6) {
            cell(s / 86_400, "days")
            cell((s / 3600) % 24, "hrs", pad: true)
            cell((s / 60) % 60, "min", pad: true)
            cell(s % 60, "sec", pad: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Opens in \(s / 86_400) days, \((s / 3600) % 24) hours")
    }

    private func cell(_ value: Int, _ unit: String, pad: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(pad ? String(format: "%02d", value) : "\(value)")
                .font(AFont.label(24))
                .monospacedDigit()
                .foregroundStyle(Palette.bone)
            Text(unit.uppercased())
                .font(AFont.label(10))
                .tracking(1.4)
                .foregroundStyle(Palette.boneDim)
        }
        .frame(width: 58)
        .padding(.vertical, 6)
        .background(Palette.soot)
        .overlay(Rectangle().stroke(Palette.rule))
    }
}

/// A kiln door: tall arch over a straight-sided chamber.
struct ArchShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let r = min(w * 0.32, 110)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + h))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addCurve(to: CGPoint(x: rect.minX + w / 2, y: rect.minY),
                   control1: CGPoint(x: rect.minX, y: rect.minY + r * 0.45),
                   control2: CGPoint(x: rect.minX + w * 0.22, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.minX + w, y: rect.minY + r),
                   control1: CGPoint(x: rect.minX + w * 0.78, y: rect.minY),
                   control2: CGPoint(x: rect.minX + w, y: rect.minY + r * 0.45))
        p.addLine(to: CGPoint(x: rect.minX + w, y: rect.minY + h))
        p.closeSubpath()
        return p
    }
}

/// A pyrometer dial, 0–600 °C, coloured by steel's temper.
struct GaugeView: View {
    let temperature: Double

    var body: some View {
        Canvas { ctx, size in
            let r = min(size.width / 2, size.height) * 0.86
            let center = CGPoint(x: size.width / 2, y: size.height * 0.94)

            func point(_ t: Double, _ radius: CGFloat) -> CGPoint {
                let a = Double.pi - (min(600, max(0, t)) / 600) * Double.pi
                return CGPoint(x: center.x + radius * CGFloat(cos(a)), y: center.y - radius * CGFloat(sin(a)))
            }

            var face = Path()
            face.addArc(center: center, radius: r * 1.06, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            face.closeSubpath()
            ctx.fill(face, with: .color(Palette.soot))
            ctx.stroke(face, with: .color(Palette.boneDim), lineWidth: 1.5)

            var band = Path()
            band.addArc(center: center, radius: r * 1.0, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            ctx.stroke(band,
                       with: .linearGradient(Gradient(colors: [Palette.blue, Palette.purple, Palette.bronze, Palette.straw]),
                                             startPoint: CGPoint(x: center.x - r, y: 0),
                                             endPoint: CGPoint(x: center.x + r, y: 0)),
                       lineWidth: 6)

            for t in stride(from: 0, through: 600, by: 50) {
                let major = t % 100 == 0
                var tick = Path()
                tick.move(to: point(Double(t), r * (major ? 0.78 : 0.83)))
                tick.addLine(to: point(Double(t), r * 0.92))
                ctx.stroke(tick, with: .color(Palette.boneDim), lineWidth: 1.4)
                if major {
                    var label = point(Double(t), r * 0.63)
                    if t == 0 || t == 600 { label.y -= 8 }
                    ctx.draw(Text("\(t)").font(AFont.label(11)).foregroundColor(Palette.boneDim), at: label)
                }
            }

            ctx.draw(Text("°C").font(AFont.narratorItalic(12)).foregroundColor(Palette.boneDim),
                     at: CGPoint(x: center.x, y: center.y - r * 0.3))

            var needle = Path()
            needle.move(to: center)
            needle.addLine(to: point(temperature, r * 0.8))
            ctx.stroke(needle, with: .color(Palette.bone), style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
            ctx.fill(Path(ellipseIn: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)), with: .color(Palette.bone))
        }
        .aspectRatio(1.75, contentMode: .fit)
    }
}

struct TagView: View {
    @EnvironmentObject var player: AudioPlayer
    let track: PlayableTrack
    var tilt: Double = 0
    var showPlayer = true
    let onPlay: () -> Void

    private var isCurrent: Bool { player.current?.id == track.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text("INTAKE No. \(String(format: "%04d", track.intakeNumber))")
                    .font(AFont.label(13))
                    .tracking(1.6)
                    .foregroundStyle(Palette.tagInkDim)
                Spacer()
                Text(Kiln.stamp(for: track.phaseID).uppercased())
                    .font(AFont.display(14))
                    .tracking(1.6)
                    .foregroundStyle(Palette.stampInk(track.phaseID))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .overlay(Rectangle().stroke(Palette.stampInk(track.phaseID), lineWidth: 2))
                    .rotationEffect(.degrees(-9))
                    .opacity(0.8)
                    .accessibilityHidden(true)
            }
            Rectangle().fill(Palette.tagInkDim).frame(height: 1)

            Text(track.track.title.uppercased())
                .font(AFont.display(32, relativeTo: .title))
                .foregroundStyle(Palette.tagInk)
                .fixedSize(horizontal: false, vertical: true)

            field("Object received", track.track.object)
            if let condition = track.track.condition {
                field("Condition", condition)
            }

            VStack(alignment: .trailing, spacing: 4) {
                Text(track.track.note)
                    .font(AFont.narratorItalic(18))
                    .foregroundStyle(Palette.tagInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text("— A.").font(AFont.narrator(16)).foregroundStyle(Palette.tagInkDim)
            }
            .padding(10)
            .background(Color.white.opacity(0.28))
            .overlay(alignment: .leading) { Rectangle().fill(Palette.tagInkDim).frame(width: 2) }

            if showPlayer {
                HStack(spacing: 12) {
                    Button {
                        if isCurrent { player.toggle() } else { onPlay() }
                    } label: {
                        Image(systemName: isCurrent && player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.body.weight(.bold))
                            .foregroundStyle(Palette.manila)
                            .frame(width: 46, height: 46)
                            .background(Circle().fill(Palette.tagInk))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel((isCurrent && player.isPlaying ? "Pause " : "Play ") + track.track.title)

                    VStack(alignment: .leading, spacing: 2) {
                        if let d = track.track.duration {
                            Text(d).font(AFont.label(15)).monospacedDigit().foregroundStyle(Palette.tagInkDim)
                        }
                        if track.isPlaceholder {
                            Text("No tape threaded yet. This is the lehr humming.")
                                .font(AFont.narratorItalic(14))
                                .foregroundStyle(Palette.tagInkDim)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.top, 6)
                .overlay(alignment: .top) {
                    Rectangle().fill(Palette.tagInkDim.opacity(0.6)).frame(height: 1)
                }
            }
        }
        .padding(EdgeInsets(top: 40, leading: 16, bottom: 16, trailing: 16))
        .background(
            TagShape().fill(LinearGradient(colors: [Palette.manila, Palette.manilaDeep],
                                           startPoint: .top, endPoint: .bottom))
        )
        .overlay(alignment: .top) {
            Circle()
                .fill(Palette.soot2)
                .frame(width: 15, height: 15)
                .overlay(Circle().stroke(Palette.manilaDeep, lineWidth: 3))
                .overlay(Circle().stroke(Palette.tagInkDim, lineWidth: 1).padding(-2))
                .padding(.top, 13)
                .accessibilityHidden(true)
        }
        .rotationEffect(.degrees(tilt))
        .accessibilityElement(children: .contain)
    }

    private func field(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label.uppercased())
                .font(AFont.label(12))
                .tracking(1.4)
                .foregroundStyle(Palette.tagInkDim)
                .frame(width: 92, alignment: .leading)
            Text(value)
                .font(AFont.narrator(17))
                .foregroundStyle(Palette.tagInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A luggage tag: chamfered top corners.
struct TagShape: Shape {
    func path(in rect: CGRect) -> Path {
        let c = min(rect.width * 0.14, 44)
        let drop: CGFloat = 26
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + c, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - c, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + drop))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + drop))
        p.closeSubpath()
        return p
    }
}

struct Pyrometer: View {
    let temp: Double
    let phase: String
    let ink: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(Int(temp.rounded()))")
                .font(AFont.display(22))
                .monospacedDigit()
            Text("°C").font(AFont.label(12))
            Text(phase.uppercased())
                .font(AFont.label(11))
                .tracking(1.6)
                .foregroundStyle(Palette.boneDim)
                .padding(.leading, 4)
        }
        .foregroundStyle(ink)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Palette.soot.opacity(0.88))
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(ink.opacity(0.6), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pyrometer, \(Int(temp.rounded())) degrees, \(phase)")
    }
}

/// The name, each letter slightly crooked; one letter never quite cools.
struct Wordmark: View {
    let name: String
    let ink: Color
    let rotations: [Double] = [-2, 1.5, -1, 2.5, -1.5, 1, -2.5, 1.8]
    let lifts: [Double] = [0, 0.04, -0.03, 0.02, -0.02, 0.05, -0.01, 0.03]

    var body: some View {
        GeometryReader { g in
            let size = min(120, g.size.width / 3.4)
            HStack(spacing: 0) {
                ForEach(Array(name.enumerated()), id: \.offset) { item in
                    let i = item.offset
                    let hot = i == 6
                    Text(String(item.element))
                        .font(.custom("BigShouldersDisplay-Black", size: size))
                        .foregroundStyle(hot ? Palette.whiteHot : ink)
                        .shadow(color: (hot ? Palette.straw : ink).opacity(0.55), radius: size * 0.16)
                        .rotationEffect(.degrees(rotations[i % rotations.count]))
                        .offset(y: lifts[i % lifts.count] * size)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .aspectRatio(3.1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityAddTraits(.isHeader)
    }
}

/// The lehr: blinks when it likes, flickers at the mouth, wakes on the seventh poke.
struct LehrArt: View {
    let awake: Bool
    let onPoke: () -> Void
    @State var blink = false
    @State var flicker = 1.0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        Button {
            onPoke()
            blinkOnce()
        } label: {
            Image(blink ? "LehrBlink" : (awake ? "LehrAwake" : "Lehr"))
                .resizable()
                .scaledToFit()
                .overlay(
                    GeometryReader { g in
                        RadialGradient(colors: [Color(hex: 0xfff4cf).opacity(0.6), Palette.straw.opacity(0)],
                                       center: .center, startRadius: 0, endRadius: g.size.width * 0.09)
                            .frame(width: g.size.width * 0.18, height: g.size.width * 0.18)
                            .position(x: g.size.width * 0.216, y: g.size.height * 0.61)
                            .opacity(flicker)
                            .blendMode(.plusLighter)
                    }
                    .allowsHitTesting(false)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("The lehr. Poke it, if you must.")
        .task { await blinkLoop() }
        .task { await flickerLoop() }
    }

    private func blinkOnce() {
        blink = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { blink = false }
    }

    private func blinkLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 2.8...7.0) * 1_000_000_000))
            if !reduceMotion { blinkOnce() }
        }
    }

    private func flickerLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 0.18...0.5) * 1_000_000_000))
            if reduceMotion {
                flicker = 1
            } else {
                withAnimation(.easeInOut(duration: 0.15)) { flicker = Double.random(in: 0.6...1.0) }
            }
        }
    }
}

// MARK: - The machine's materials

/// The workshop floor: soot, the manual's etched grid, and a glow from whatever is hottest.
struct SootBackground: View {
    var glow: Color = Palette.straw
    var glowStrength: Double = 0.2

    var body: some View {
        ZStack {
            Palette.soot
            Canvas { ctx, size in
                var grid = Path()
                let step: CGFloat = 44
                var x: CGFloat = 0
                while x <= size.width { grid.move(to: CGPoint(x: x, y: 0)); grid.addLine(to: CGPoint(x: x, y: size.height)); x += step }
                var y: CGFloat = 0
                while y <= size.height { grid.move(to: CGPoint(x: 0, y: y)); grid.addLine(to: CGPoint(x: size.width, y: y)); y += step }
                ctx.stroke(grid, with: .color(Palette.bone.opacity(0.05)), lineWidth: 1)
            }
            RadialGradient(colors: [glow.opacity(glowStrength), .clear], center: .top, startRadius: 0, endRadius: 560)
        }
        .ignoresSafeArea()
    }
}

/// A riveted iron panel.
struct IronPanel: ViewModifier {
    var stroke: Color = Palette.bone
    var corner: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: corner, style: .continuous).fill(Palette.soot2))
            .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).stroke(stroke.opacity(0.85), lineWidth: 2.5))
            .overlay(Rivets(inset: 9).allowsHitTesting(false))
    }
}

extension View {
    func ironPanel(stroke: Color = Palette.bone, corner: CGFloat = 14) -> some View {
        modifier(IronPanel(stroke: stroke, corner: corner))
    }

    /// Rattles the view whenever `trigger` changes, like a door that won't budge.
    func rattle(_ trigger: Int) -> some View {
        modifier(Rattle(animatableData: CGFloat(trigger)))
    }
}

struct Rivets: View {
    var inset: CGFloat = 8

    var body: some View {
        GeometryReader { g in
            let pts = [CGPoint(x: inset, y: inset), CGPoint(x: g.size.width - inset, y: inset),
                       CGPoint(x: inset, y: g.size.height - inset), CGPoint(x: g.size.width - inset, y: g.size.height - inset)]
            ForEach(0..<pts.count, id: \.self) { i in
                Circle().fill(Palette.bone.opacity(0.55)).frame(width: 5, height: 5).position(pts[i])
            }
        }
        .accessibilityHidden(true)
    }
}

struct Rattle: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let dx = 7 * sin(animatableData * .pi * 6)
        let r = 0.012 * sin(animatableData * .pi * 6)
        let t = CGAffineTransform(translationX: dx, y: 0).rotated(by: r)
        return ProjectionTransform(t)
    }
}

/// Round machine buttons with an iron rim.
struct MachineButtonStyle: ButtonStyle {
    var size: CGFloat = 64
    var hot = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.34, weight: .bold))
            .foregroundStyle(hot ? Palette.soot : Palette.bone)
            .frame(width: size, height: size)
            .background(Circle().fill(hot ? Palette.straw : Palette.soot2))
            .overlay(Circle().stroke(Palette.bone.opacity(0.85), lineWidth: 2.5))
            .overlay(Circle().stroke(Palette.soot, lineWidth: 2).padding(4))
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .shadow(color: hot ? Palette.straw.opacity(0.45) : .clear, radius: 14)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Manila paper, for anything you'd hold in your hand: tags, the booklet, the ledger.
struct PaperBackground: View {
    var corner: CGFloat = 3

    var body: some View {
        RoundedRectangle(cornerRadius: corner)
            .fill(LinearGradient(colors: [Palette.manila, Palette.manilaDeep], startPoint: .top, endPoint: .bottom))
            .overlay(
                Canvas { ctx, size in
                    // a little foxing, always in the same places
                    var rng = SeededRandom(seed: 7)
                    for _ in 0..<40 {
                        let r = CGFloat(rng.next() * 3 + 1)
                        let p = CGPoint(x: CGFloat(rng.next()) * size.width, y: CGFloat(rng.next()) * size.height)
                        ctx.fill(Path(ellipseIn: CGRect(x: p.x, y: p.y, width: r, height: r)), with: .color(Palette.tagInkDim.opacity(0.12)))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: corner))
            )
    }
}

struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 0x9E3779B97F4A7C15 }
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 11) / Double(1 << 53)
    }
}

/// The observation port. It looks out. It blinks when it likes.
struct Porthole: View {
    var size: CGFloat = 120
    var awake = false
    let onPoke: () -> Void
    @State var blink = false
    @State var flicker = 1.0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        Button {
            onPoke()
            blinkOnce()
        } label: {
            ZStack {
                Circle().fill(Palette.straw.opacity(awake ? 0.45 : 0.28)).blur(radius: size * 0.22)
                Circle().fill(Palette.soot2)
                Circle().stroke(Palette.bone, lineWidth: size * 0.05)
                Circle()
                    .fill(RadialGradient(colors: [Color(hex: 0xfff4cf), Color(hex: 0xe9ad4c), Color(hex: 0x8a3a14)],
                                         center: .center, startRadius: 0, endRadius: size * 0.36))
                    .padding(size * 0.12)
                    .opacity(flicker)
                Capsule()
                    .fill(Palette.soot)
                    .frame(width: size * (awake ? 0.08 : 0.1), height: size * (awake ? 0.56 : 0.48))
                Circle()
                    .fill(Palette.soot2)
                    .padding(size * 0.1)
                    .scaleEffect(x: 1, y: blink ? 1 : 0.001, anchor: .top)
                ForEach(0..<8, id: \.self) { i in
                    let a = Double(i) / 8 * 2 * Double.pi
                    Circle()
                        .fill(Palette.bone.opacity(0.7))
                        .frame(width: size * 0.045, height: size * 0.045)
                        .offset(x: CGFloat(cos(a)) * size * 0.56, y: CGFloat(sin(a)) * size * 0.56)
                }
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("The observation port. Poke it, if you must.")
        .task { await blinkLoop() }
        .task { await flickerLoop() }
    }

    private func blinkOnce() {
        withAnimation(.easeIn(duration: 0.08)) { blink = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.easeOut(duration: 0.1)) { blink = false }
        }
    }

    private func blinkLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 2.8...7.0) * 1_000_000_000))
            if !reduceMotion { blinkOnce() }
        }
    }

    private func flickerLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 0.18...0.5) * 1_000_000_000))
            if reduceMotion {
                flicker = 1
            } else {
                withAnimation(.easeInOut(duration: 0.15)) { flicker = Double.random(in: 0.72...1.0) }
            }
        }
    }
}

/// Plays the narrator's lines one letter at a time, like a typewriter.
struct TypedLine: View {
    let text: String
    var font: Font = AFont.narratorItalic(24, relativeTo: .title2)
    var color: Color = Palette.bone
    @State var shown = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        Text(String(text.prefix(shown)))
            .font(font)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(text)
            .task(id: text) {
                if reduceMotion { shown = text.count; return }
                shown = 0
                for i in 0...text.count {
                    shown = i
                    try? await Task.sleep(nanoseconds: 38_000_000)
                    if Task.isCancelled { return }
                }
            }
    }
}
