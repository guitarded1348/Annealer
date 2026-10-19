import SwiftUI
import UIKit

/// Home: you're standing on the workshop floor in front of the lehr.
/// The cabinet holds the three chambers; the bench in front holds everything else.
struct FloorView: View {
    @EnvironmentObject var store: ContentStore
    @EnvironmentObject var player: AudioPlayer
    @EnvironmentObject var intake: IntakeStore

    @State var pokes = 0
    @State var says = ""
    @State var room: RoomRef?
    @State var sheet: FloorSheet?
    @State var showBooklet = false

    var body: some View {
        let c = store.content
        ZStack {
            SootBackground(glow: Palette.straw, glowStrength: pokes >= 7 ? 0.4 : 0.18)

            ScrollView {
                VStack(spacing: 22) {
                    header(c)
                    cabinet(c)
                    bench(c)
                    if let credits = c.credits {
                        Text(credits)
                            .font(AFont.narratorItalic(15))
                            .foregroundStyle(Palette.boneDim)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if player.current != nil {
                HookBar { sheet = .bench }
            }
        }
        .fullScreenCover(item: $room) { ref in
            ChamberRoom(chamberID: ref.id)
                .environmentObject(store)
                .environmentObject(player)
        }
        .fullScreenCover(isPresented: $showBooklet) {
            BookletView()
                .environmentObject(store)
        }
        .sheet(item: $sheet) { which in
            Group {
                switch which {
                case .bench: BenchView()
                case .log: ClipboardView()
                case .counter: CounterView()
                case .intake: IntakeView()
                }
            }
            .environmentObject(store)
            .environmentObject(player)
            .environmentObject(intake)
        }
    }

    // MARK: Header

    private func header(_ c: SiteContent) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                Eyebrow("Lehr No. 4 · \(litLine(c))", color: Palette.boneDim, size: 12)
                Spacer()
                Pyrometer(temp: pokes >= 7 ? 999 : hottest(c), phase: "Lehr", ink: Temper.ink(0))
            }
            Wordmark(name: c.site.name, ink: Temper.ink(0))
        }
    }

    // MARK: The cabinet

    private func cabinet(_ c: SiteContent) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                HStack(alignment: .center, spacing: 16) {
                    Porthole(size: 96, awake: pokes >= 7) { poke(c) }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(says.isEmpty ? c.heroLine : says)
                            .font(AFont.narratorItalic(19, relativeTo: .title3))
                            .foregroundStyle(says.isEmpty ? Palette.bone : Temper.ink(0))
                            .fixedSize(horizontal: false, vertical: true)
                            .animation(.easeInOut(duration: 0.2), value: says)
                        Text("— A.").font(AFont.narrator(15)).foregroundStyle(Palette.boneDim)
                    }
                    Spacer(minLength: 0)
                }

                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    let now = Clock.now()
                    VStack(spacing: 12) {
                        ForEach(Kiln.chambers(c, now: now)) { chamber in
                            ChamberDoor(chamber: chamber, temperature: Kiln.temperature(of: chamber, content: c, now: now)) {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                room = RoomRef(id: chamber.id)
                            }
                        }
                        if !TestBench.tracks.isEmpty {
                            Button {
                                room = RoomRef(id: TestBench.chamberID)
                            } label: {
                                HStack {
                                    Image(systemName: "wrench.and.screwdriver")
                                    Text("TEST BENCH · \(TestBench.tracks.count) ON THE HOOK · DEBUG ONLY")
                                        .font(AFont.label(12))
                                        .tracking(1.4)
                                    Spacer()
                                }
                                .foregroundStyle(Palette.paleBlue)
                                .padding(12)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Palette.paleBlue.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
            .padding(.top, 6)
            .ironPanel(corner: 22)

            // crooked stove legs
            Canvas { ctx, size in
                let w = size.width, h = size.height
                let legs: [(CGFloat, CGFloat)] = [(0.12, -14), (0.34, -4), (0.66, 6), (0.88, 16)]
                for (x, lean) in legs {
                    var p = Path()
                    p.move(to: CGPoint(x: w * x, y: 0))
                    p.addQuadCurve(to: CGPoint(x: w * x + lean, y: h - 4), control: CGPoint(x: w * x + lean * 0.2, y: h * 0.6))
                    p.addQuadCurve(to: CGPoint(x: w * x + lean + (lean < 0 ? -12 : 12), y: h - 2), control: CGPoint(x: w * x + lean, y: h))
                    ctx.stroke(p, with: .color(Palette.bone.opacity(0.85)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                }
            }
            .frame(height: 34)
            .accessibilityHidden(true)
        }
    }

    // MARK: The bench

    private func bench(_ c: SiteContent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("On the bench", color: Palette.boneDim, size: 12)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                BenchObject(symbol: "list.clipboard", title: "The Log", subtitle: logSubtitle(c)) { sheet = .log }
                BenchObject(symbol: "book.closed", title: "Liner Notes", subtitle: "The Workshop, folded") { showBooklet = true }
                BenchObject(symbol: "tray.and.arrow.down", title: "Bring In", subtitle: intakeSubtitle) { sheet = .intake }
                BenchObject(symbol: "bell", title: "Counter", subtitle: "Leave your name") { sheet = .counter }
            }
        }
    }

    // MARK: Behaviour

    private func poke(_ c: SiteContent) {
        pokes += 1
        if pokes == 7 {
            says = c.lehrSeventh
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        } else if !c.lehrLines.isEmpty {
            says = c.lehrLines[(pokes - 1 - (pokes > 7 ? 1 : 0)) % c.lehrLines.count]
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func hottest(_ c: SiteContent) -> Double {
        let now = Clock.now()
        return Kiln.chambers(c, now: now).map { Kiln.temperature(of: $0, content: c, now: now) }.max() ?? c.site.ambient
    }

    private func litLine(_ c: SiteContent) -> String {
        guard let lit = ADate.parse(c.site.litOn) else { return "lit" }
        let days = Clock.daysSince(lit)
        return days == 0 ? "lit today" : "lit \(days) \(days == 1 ? "day" : "days") ago"
    }

    private func logSubtitle(_ c: SiteContent) -> String {
        guard let latest = c.log?.entries.compactMap({ ADate.parse($0.date) }).max() else { return "Nothing written yet" }
        return "Last entry \(ADate.short.string(from: latest))"
    }

    private var intakeSubtitle: String {
        let hot = intake.items.filter { !IntakeStore.isCooled($0) }.count
        let cooled = intake.items.count - hot
        if hot > 0 { return "\(hot) cooling" }
        if cooled > 0 { return "\(cooled) cooled" }
        return "What made you hot?"
    }
}

struct RoomRef: Identifiable {
    let id: String
}

enum FloorSheet: String, Identifiable {
    case bench, log, counter, intake
    var id: String { rawValue }
}

// MARK: - Pieces of the floor

/// One chamber door on the cabinet: a glowing window, a name plate, a temperature.
struct ChamberDoor: View {
    let chamber: Chamber
    let temperature: Double
    let onOpen: () -> Void

    var body: some View {
        let color = Palette.chamber(chamber.phase.id)
        let heat = chamber.state == .open ? 0.9 : min(1, temperature / 600)
        Button(action: onOpen) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(color.opacity(heat * 0.5)).blur(radius: 10)
                    Circle().fill(RadialGradient(colors: [Palette.whiteHot.opacity(heat), color.opacity(0.35 + heat * 0.6), Palette.soot],
                                                 center: .center, startRadius: 0, endRadius: 30))
                    Circle().stroke(Palette.bone, lineWidth: 2.5)
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 3) {
                    Eyebrow("Chamber \(chamber.numeral)", color: Palette.boneDim, size: 11)
                    Text(chamber.phase.name.uppercased())
                        .font(AFont.display(30, relativeTo: .title))
                        .foregroundStyle(Palette.bone)
                    Text(shortStatus.uppercased())
                        .font(AFont.label(11))
                        .tracking(1.4)
                        .foregroundStyle(chamber.state == .open ? Temper.ink(0) : Palette.boneDim)
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 6) {
                    Text("\(Int(temperature.rounded()))°")
                        .font(AFont.display(26))
                        .monospacedDigit()
                        .foregroundStyle(chamber.state == .open ? Temper.ink(0) : Palette.bone)
                    Image(systemName: chamber.state == .open ? "lock.open.fill" : "lock.fill")
                        .font(.footnote)
                        .foregroundStyle(Palette.boneDim)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(Palette.soot))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.75), lineWidth: 1.5))
            .rotationEffect(.degrees([-0.5, 0.4, -0.3][chamber.index % 3]))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Chamber \(chamber.numeral), \(chamber.phase.name). \(Kiln.statusLine(chamber)). \(Int(temperature.rounded())) degrees.")
        .accessibilityHint(chamber.state == .open ? "Opens the chamber" : "Shows the sealed door")
    }

    private var shortStatus: String {
        switch chamber.state {
        case .open: return chamber.isExample ? "Example" : "Open · \(chamber.tracks.count) inside"
        case .dated:
            if let r = chamber.release { return "Opens \(ADate.short.string(from: r))" }
            return "Sealed"
        case .heating: return "Heating · no date yet"
        case .cold: return "Cold · not loaded"
        }
    }
}

struct BenchObject: View {
    let symbol: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(Palette.straw)
                Text(title.uppercased())
                    .font(AFont.label(17))
                    .tracking(1.4)
                    .foregroundStyle(Palette.bone)
                Text(subtitle)
                    .font(AFont.narratorItalic(14))
                    .foregroundStyle(Palette.boneDim)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
            .padding(14)
            .ironPanel(stroke: Palette.boneDim, corner: 8)
        }
        .buttonStyle(.plain)
    }
}

/// The now-playing tag, hanging from the rail at the bottom of the floor.
struct HookBar: View {
    @EnvironmentObject var player: AudioPlayer
    @EnvironmentObject var store: ContentStore
    let open: () -> Void

    var body: some View {
        if let t = player.current {
            let p = player.progress
            let temp = BenchMath.temperature(t, progress: p, ambient: store.content.site.ambient)
            VStack(spacing: 0) {
                Rectangle().fill(Palette.bone.opacity(0.7)).frame(height: 2)
                HStack(spacing: 12) {
                    Button(action: open) {
                        HStack(spacing: 10) {
                            VStack(spacing: 0) {
                                Rectangle().fill(Palette.boneDim).frame(width: 1.5, height: 8)
                                Text("\(Int(temp.rounded()))°")
                                    .font(AFont.display(20))
                                    .monospacedDigit()
                                    .foregroundStyle(Palette.tagInk)
                                    .frame(width: 58, height: 40)
                                    .background(TagShape().fill(Temper.ink(p)))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.track.title.uppercased())
                                    .font(AFont.label(17))
                                    .tracking(1.2)
                                    .foregroundStyle(Palette.bone)
                                    .lineLimit(1)
                                Text("On the hook · Chamber \(t.chamberNo)")
                                    .font(AFont.narratorItalic(14))
                                    .foregroundStyle(Palette.boneDim)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Now playing \(t.track.title). Opens the hook.")

                    Button {
                        player.toggle()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(MachineButtonStyle(size: 46))
                    .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .background(Palette.soot2.opacity(0.97).ignoresSafeArea(edges: .bottom))
        }
    }
}
