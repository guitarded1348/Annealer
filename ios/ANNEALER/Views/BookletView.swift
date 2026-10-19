import SwiftUI
import UIKit

/// The liner notes: a paper booklet you page through, like the one tucked inside a box set.
/// One paragraph of lore per page. Two pages look blank; hold them to read the invisible ink.
struct BookletView: View {
    @EnvironmentObject var store: ContentStore
    @Environment(\.dismiss) var dismiss
    @State var page = 0
    @State var inkRevealed = false
    @State var showTangle = false

    var body: some View {
        let c = store.content
        let lore = c.workshop.lore
        ZStack(alignment: .topLeading) {
            SootBackground(glowStrength: 0.08)
            TabView(selection: $page) {
                cover(c).tag(0)
                ForEach(Array(lore.enumerated()), id: \.offset) { item in
                    lorePage(item.element, number: item.offset + 1, first: item.offset == 0).tag(item.offset + 1)
                }
                schedulePage.tag(lore.count + 1)
                creditsPage(c).tag(lore.count + 2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                dismiss()
            } label: {
                Label("Close the booklet", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                    .font(.headline)
                    .foregroundStyle(Palette.bone)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Palette.soot.opacity(0.8)))
            }
            .padding(.leading, 16)
            .padding(.top, 4)
        }
        .sheet(isPresented: $showTangle) { TangleView() }
    }

    // MARK: Pages

    private func paper<Inner: View>(@ViewBuilder _ inner: () -> Inner) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            inner()
        }
        .padding(26)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(PaperBackground(corner: 3))
        .shadow(color: .black.opacity(0.5), radius: 18, y: 8)
        .padding(.horizontal, 22)
        .padding(.top, 60)
        .padding(.bottom, 54)
    }

    private func cover(_ c: SiteContent) -> some View {
        VStack(spacing: 18) {
            Spacer()
            Eyebrow("Liner notes · Volume I", color: Palette.boneDim)
            Wordmark(name: c.site.name, ink: Temper.ink(0))
            Image("Lehr").resizable().scaledToFit()
            Text(c.workshop.title.uppercased())
                .font(AFont.display(34))
                .foregroundStyle(Palette.bone)
            Text("As described by its keeper. Swipe to turn the page.")
                .font(AFont.narratorItalic(17))
                .foregroundStyle(Palette.boneDim)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(Palette.soot2)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Palette.straw.opacity(0.6), lineWidth: 1.5))
                .padding(.horizontal, 22)
                .padding(.top, 60)
                .padding(.bottom, 54)
        )
    }

    private func lorePage(_ lore: Lore, number: Int, first: Bool) -> some View {
        let ink = lore.ink ?? false
        return paper {
            Eyebrow("Page \(number)", color: Palette.tagInkDim, size: 12)
            if first, let initial = lore.text.first {
                HStack(alignment: .top, spacing: 8) {
                    Text(String(initial))
                        .font(AFont.display(84))
                        .foregroundStyle(Color(hex: 0x7a2c12))
                    Text(String(lore.text.dropFirst()))
                        .font(AFont.narrator(23, relativeTo: .title3))
                        .lineSpacing(6)
                        .foregroundStyle(Palette.tagInk)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                }
            } else {
                Text(lore.text)
                    .font(AFont.narrator(23, relativeTo: .title3))
                    .lineSpacing(6)
                    // invisible ink is printed in the paper's own colour
                    .foregroundStyle(ink ? (inkRevealed ? Color(hex: 0x7a2c12) : Palette.manila) : Palette.tagInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Text("— A.").font(AFont.narratorItalic(18)).foregroundStyle(Palette.tagInkDim)
        }
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.9) {
            guard ink else { return }
            withAnimation(.easeInOut(duration: 0.8)) { inkRevealed.toggle() }
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    private var schedulePage: some View {
        paper {
            Eyebrow("Fig. 2", color: Palette.tagInkDim, size: 12)
            Text("AN ANNEALING SCHEDULE")
                .font(AFont.display(30))
                .foregroundStyle(Palette.tagInk)
            AnnealChart()
                .aspectRatio(400.0 / 260.0, contentMode: .fit)
            Text("For soda-lime glass, in °C. Also a release schedule.")
                .font(AFont.narratorItalic(18))
                .foregroundStyle(Palette.tagInk)
            Spacer()
        }
    }

    private func creditsPage(_ c: SiteContent) -> some View {
        paper {
            Eyebrow("Colophon", color: Palette.tagInkDim, size: 12)
            Image("LehrAsleep")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 120)
                .colorMultiply(Palette.tagInk)
            if let credits = c.credits {
                Text(credits).font(AFont.narratorItalic(22)).foregroundStyle(Palette.tagInk)
            }
            if let footer = c.footer {
                Text(footer).font(AFont.narrator(18)).foregroundStyle(Palette.tagInkDim)
            }
            if let signoff = c.workshop.signoff {
                Text(signoff).font(AFont.narratorItalic(20)).foregroundStyle(Palette.tagInk)
            }
            Spacer()
            Button {
                showTangle = true
            } label: {
                Text("k = 1.380649 × 10⁻²³ J/K")
                    .font(AFont.label(14))
                    .foregroundStyle(Palette.tagInkDim.opacity(0.7))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("A constant. Press to see what it's for.")
        }
    }
}

/// Fig. 2 from the website, redrawn in ink: heat, soak, slow cool. Drawn in a 400 × 260 space.
struct AnnealChart: View {
    var body: some View {
        Canvas { ctx, size in
            let sx = size.width / 400, sy = size.height / 260
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * sx, y: y * sy) }
            let ink = Palette.tagInk, dim = Palette.tagInkDim

            var axes = Path()
            axes.move(to: pt(40, 20)); axes.addLine(to: pt(40, 220)); axes.addLine(to: pt(385, 220))
            ctx.stroke(axes, with: .color(dim), lineWidth: 1)

            for y in [153.3, 86.7, 20.0] {
                var l = Path(); l.move(to: pt(40, y)); l.addLine(to: pt(385, y))
                ctx.stroke(l, with: .color(dim.opacity(0.35)), style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
            }
            for x in [97.5, 183.75] {
                var l = Path(); l.move(to: pt(x, 20)); l.addLine(to: pt(x, 220))
                ctx.stroke(l, with: .color(dim.opacity(0.5)), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            for y in [37.3, 48.7] {
                var l = Path(); l.move(to: pt(40, y)); l.addLine(to: pt(385, y))
                ctx.stroke(l, with: .color(dim.opacity(0.7)), style: StrokeStyle(lineWidth: 1, dash: [6, 3]))
            }

            var curve = Path()
            curve.move(to: pt(40, 213.3))
            curve.addCurve(to: pt(97.5, 31.7), control1: pt(70, 213), control2: pt(80, 32))
            curve.addLine(to: pt(183.75, 31.7))
            curve.addCurve(to: pt(298.75, 48.7), control1: pt(230, 33), control2: pt(260, 42))
            curve.addCurve(to: pt(385, 213.3), control1: pt(330, 60), control2: pt(350, 190))
            ctx.stroke(curve, with: .color(Color(hex: 0x7a2c12)), style: StrokeStyle(lineWidth: 2.6, lineCap: .round))

            let small = AFont.label(11), note = AFont.narratorItalic(11)
            for (label, y) in [("0", 223.0), ("200", 156.0), ("400", 90.0), ("600", 23.0)] {
                ctx.draw(Text(label).font(small).foregroundColor(dim), at: pt(34, CGFloat(y)), anchor: .trailing)
            }
            for (label, x) in [("0", 40.0), ("4", 155.0), ("8", 270.0), ("12 h", 385.0)] {
                ctx.draw(Text(label).font(small).foregroundColor(dim), at: pt(CGFloat(x), 236), anchor: .center)
            }
            for (label, x) in [("HEAT", 69.0), ("SOAK", 140.6), ("SLOW COOL", 284.0)] {
                ctx.draw(Text(label).font(AFont.display(12)).foregroundColor(ink), at: pt(CGFloat(x), 10), anchor: .center)
            }
            ctx.draw(Text("annealing pt 548°").font(note).foregroundColor(dim), at: pt(383, 30), anchor: .trailing)
            ctx.draw(Text("strain pt 514°").font(note).foregroundColor(dim), at: pt(104, 58), anchor: .leading)
            ctx.draw(Text("hours in the lehr").font(note).foregroundColor(dim), at: pt(212, 252), anchor: .center)
        }
        .accessibilityElement()
        .accessibilityLabel("Annealing schedule: heat to 565 degrees, soak, then a slow cool past the strain point to room temperature.")
    }
}

/// The Keeper's Log, clipped to a board on the bench.
struct ClipboardView: View {
    @EnvironmentObject var store: ContentStore

    var body: some View {
        let c = store.content
        ZStack {
            SootBackground(glowStrength: 0.08)
            ScrollView {
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Palette.bone)
                        .frame(width: 120, height: 26)
                        .overlay(Capsule().stroke(Palette.soot, lineWidth: 2).padding(4))
                        .zIndex(1)
                        .offset(y: 13)
                    VStack(alignment: .leading, spacing: 18) {
                        Eyebrow("Work order · Lehr No. 4", color: Palette.tagInkDim, size: 12)
                        Text("THE KEEPER'S LOG")
                            .font(AFont.display(36))
                            .foregroundStyle(Palette.tagInk)
                        Text("Kept on the back of an invoice. Most recent first.")
                            .font(AFont.narratorItalic(17))
                            .foregroundStyle(Palette.tagInkDim)
                        Rectangle().fill(Palette.tagInkDim).frame(height: 1)
                        ForEach(entries(c)) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Text("DAY \(day(of: entry, litOn: c.site.litOn))")
                                        .font(AFont.label(17))
                                        .tracking(1.6)
                                        .foregroundStyle(Color(hex: 0x7a2c12))
                                    if let d = ADate.parse(entry.date) {
                                        Text(ADate.long.string(from: d).uppercased())
                                            .font(AFont.label(12))
                                            .tracking(1.4)
                                            .foregroundStyle(Palette.tagInkDim)
                                    }
                                }
                                Text(entry.text)
                                    .font(AFont.narrator(19))
                                    .foregroundStyle(Palette.tagInk)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.bottom, 6)
                            .overlay(alignment: .bottom) { Rectangle().fill(Palette.tagInkDim.opacity(0.25)).frame(height: 1).offset(y: 8) }
                        }
                        if entries(c).isEmpty {
                            Text("Nothing written yet. Nothing worth writing.")
                                .font(AFont.narratorItalic(18))
                                .foregroundStyle(Palette.tagInkDim)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 34)
                    .padding(.bottom, 28)
                    .background(PaperBackground(corner: 2))
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0x4a3221)))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func entries(_ c: SiteContent) -> [LogEntry] {
        guard let log = c.log else { return [] }
        return log.entries.sorted {
            (ADate.parse($0.date) ?? .distantPast) > (ADate.parse($1.date) ?? .distantPast)
        }
    }

    private func day(of entry: LogEntry, litOn: String) -> Int {
        guard let lit = ADate.parse(litOn), let d = ADate.parse(entry.date) else { return 1 }
        return max(1, Int(floor(d.timeIntervalSince(lit) / 86_400)) + 1)
    }
}
