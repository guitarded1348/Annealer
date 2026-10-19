import SwiftUI
import UIKit

/// First launch: a crate arrives with a specimen tag. Pull the tag, the crate falls away,
/// the lehr ignites, and the narrator says his first line. It only happens once.
struct UnboxingView: View {
    @EnvironmentObject var store: ContentStore
    let onDone: () -> Void

    @State var pull: CGFloat = 0
    @State var opened = false
    @State var ignition: Double = 0
    @State var showLine = false
    @State var showEnter = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let threshold: CGFloat = 140

    var body: some View {
        ZStack {
            SootBackground(glow: Palette.straw, glowStrength: 0.08 + ignition * 0.3)

            // What was inside: the lehr, lighting up.
            VStack(spacing: 24) {
                Spacer()
                Image(ignition > 0.6 ? "LehrAwake" : "Lehr")
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 12)
                    .opacity(opened ? 1 : 0)
                    .scaleEffect(opened ? 1 : 0.92)
                    .shadow(color: Palette.straw.opacity(ignition * 0.6), radius: 40)
                if opened {
                    Wordmark(name: store.content.site.name, ink: Temper.ink(0))
                        .padding(.horizontal, 24)
                        .opacity(ignition)
                }
                if showLine {
                    TypedLine(text: store.content.heroLine)
                        .padding(.horizontal, 28)
                }
                Spacer()
                if showEnter {
                    Button("Step inside") { onDone() }
                        .font(AFont.display(22))
                        .tracking(2)
                        .foregroundStyle(Palette.soot)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Palette.straw)
                        .transition(.opacity)
                        .padding(.bottom, 40)
                }
            }

            if !opened {
                crate
                    .transition(.asymmetric(insertion: .identity,
                                            removal: .offset(y: 900).combined(with: .opacity)))
            }
        }
    }

    // MARK: The crate

    private var crate: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)
            VStack(alignment: .leading, spacing: 14) {
                Eyebrow("Delivery · Handle with tongs", color: Palette.tagInkDim)
                Rectangle().fill(Palette.tagInkDim).frame(height: 1)
                Text("SPECIMEN No. 1")
                    .font(AFont.display(46, relativeTo: .largeTitle))
                    .foregroundStyle(Palette.tagInk)
                Group {
                    line("Contents", "One lehr. Live.")
                    line("Condition", "Received hot.")
                    line("Deliver to", "Whoever opened this.")
                }
                Text("Do not open near anything you're fond of.")
                    .font(AFont.narratorItalic(18))
                    .foregroundStyle(Palette.tagInk)
                    .padding(.top, 6)
                Text("THIS SIDE UP  ↑")
                    .font(AFont.display(16))
                    .tracking(3)
                    .foregroundStyle(Color(hex: 0x7a2c12))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .overlay(Rectangle().stroke(Color(hex: 0x7a2c12), lineWidth: 2))
                    .rotationEffect(.degrees(-4))
                    .opacity(0.8)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(24)
            .background(PaperBackground(corner: 4))
            .overlay(
                // the crate's strapping
                VStack {
                    Spacer()
                    Rectangle().fill(Palette.tagInk.opacity(0.85)).frame(height: 10)
                    Spacer().frame(height: 26)
                }
                .allowsHitTesting(false)
            )
            .rotationEffect(.degrees(-1.2 + Double(pull) * 0.01))
            .padding(.horizontal, 22)

            pullTag
            Spacer(minLength: 20)
        }
    }

    private var pullTag: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Palette.boneDim)
                .frame(width: 2, height: 40 + pull)
            VStack(spacing: 6) {
                Circle().fill(Palette.soot).frame(width: 10, height: 10).padding(.top, 10)
                Text("PULL")
                    .font(AFont.display(22))
                    .tracking(3)
                    .foregroundStyle(Palette.tagInk)
                Image(systemName: "chevron.compact.down")
                    .foregroundStyle(Palette.tagInkDim)
                    .padding(.bottom, 10)
            }
            .frame(width: 92)
            .background(TagShape().fill(Palette.manila))
            .rotationEffect(.degrees(Double(pull) * 0.04))
        }
        .gesture(
            DragGesture()
                .onChanged { v in
                    let next = max(0, v.translation.height)
                    if next > threshold && pull <= threshold {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                    pull = next
                }
                .onEnded { _ in
                    if pull > threshold { open() } else { withAnimation(.spring()) { pull = 0 } }
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pull the tag to open the crate")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { open() }
    }

    private func line(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label.uppercased())
                .font(AFont.label(13))
                .tracking(1.6)
                .foregroundStyle(Palette.tagInkDim)
                .frame(width: 96, alignment: .leading)
            Text(value).font(AFont.narrator(19)).foregroundStyle(Palette.tagInk)
        }
    }

    // MARK: Ignition

    private func open() {
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        heavy.impactOccurred()
        if reduceMotion {
            opened = true
            ignition = 1
            showLine = true
            showEnter = true
            return
        }
        withAnimation(.easeIn(duration: 0.45)) { opened = true }
        // three thumps as the lehr catches, then the glow comes up
        for (i, delay) in [0.5, 0.85, 1.15].enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                UIImpactFeedbackGenerator(style: i == 2 ? .heavy : .rigid).impactOccurred()
            }
        }
        withAnimation(.easeInOut(duration: 2.2).delay(0.5)) { ignition = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { showLine = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.4) {
            withAnimation(.easeOut(duration: 0.6)) { showEnter = true }
        }
    }
}
