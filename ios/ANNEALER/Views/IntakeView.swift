import SwiftUI
import UIKit

/// The charging end of the lehr. Write down what made you hot, put it on the belt, and it rides
/// into the mouth. It cools over a day; then it comes out the far end with a note from the Annealer.
/// Everything here stays on this phone.
struct IntakeView: View {
    @EnvironmentObject var store: ContentStore
    @EnvironmentObject var intake: IntakeStore
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State var draft = ""
    @State var sending = false
    @State var beltPhase: CGFloat = 0
    @FocusState var writing: Bool

    var body: some View {
        let copy = store.content.intake ?? IntakeCopy.fallback
        let ambient = store.content.site.ambient
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        ZStack {
            SootBackground(glowStrength: 0.15)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Eyebrow("The charging end · private to this phone", color: Palette.boneDim, size: 12)
                    Text(copy.title.uppercased())
                        .font(AFont.display(38))
                        .foregroundStyle(Palette.bone)
                    Text(copy.prompt)
                        .font(AFont.narratorItalic(19))
                        .foregroundStyle(Palette.boneDim)
                        .fixedSize(horizontal: false, vertical: true)

                    // the slip, riding the belt into the mouth
                    VStack(spacing: 0) {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $draft)
                                .focused($writing)
                                .scrollContentBackground(.hidden)
                                .font(AFont.narrator(20))
                                .foregroundStyle(Palette.tagInk)
                                .tint(Palette.tagInk)
                                .frame(minHeight: 130)
                                .padding(10)
                            if draft.isEmpty {
                                Text(copy.placeholder)
                                    .font(AFont.narratorItalic(20))
                                    .foregroundStyle(Palette.tagInkDim.opacity(0.7))
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 18)
                                    .allowsHitTesting(false)
                            }
                        }
                        .background(PaperBackground())
                        .rotationEffect(.degrees(sending ? 8 : -0.8))
                        .offset(x: sending ? 520 : 0, y: sending ? 30 : 0)
                        .opacity(sending ? 0 : 1)

                        Conveyor(phase: beltPhase)
                            .frame(height: 30)
                            .padding(.top, 6)
                    }

                    Button {
                        send(trimmed, copy: copy)
                    } label: {
                        Label(copy.button.uppercased(), systemImage: "arrow.right")
                            .font(AFont.display(18))
                            .tracking(1.6)
                            .foregroundStyle(Palette.soot)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(trimmed.isEmpty ? Palette.boneDim : Palette.straw)
                    }
                    .disabled(trimmed.isEmpty || sending)

                    TimelineView(.periodic(from: .now, by: 30)) { context in
                        let now = context.date
                        let hot = intake.items.filter { !IntakeStore.isCooled($0, now: now) }
                        let cooled = intake.items.filter { IntakeStore.isCooled($0, now: now) }
                        VStack(alignment: .leading, spacing: 14) {
                            if intake.items.isEmpty {
                                Text(copy.empty)
                                    .font(AFont.narratorItalic(18))
                                    .foregroundStyle(Palette.boneDim)
                                    .padding(.top, 10)
                            }
                            if !hot.isEmpty {
                                Eyebrow("In the lehr", color: Palette.boneDim, size: 12).padding(.top, 10)
                                ForEach(hot) { item in HotSlip(item: item, ambient: ambient, now: now) }
                            }
                            if !cooled.isEmpty {
                                Eyebrow("Out the far end", color: Palette.boneDim, size: 12).padding(.top, 10)
                                ForEach(cooled) { item in
                                    CooledSlip(item: item, reply: IntakeStore.reply(for: item, replies: copy.replies)) {
                                        withAnimation(.easeInOut(duration: 0.4)) { intake.letGo(item) }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 22)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .presentationDragIndicator(.visible)
    }

    private func send(_ text: String, copy: IntakeCopy) {
        guard !text.isEmpty else { return }
        writing = false
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if reduceMotion {
            intake.bringIn(text, coolHours: copy.coolHours)
            draft = ""
            return
        }
        withAnimation(.easeIn(duration: 0.9)) {
            sending = true
            beltPhase += 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            intake.bringIn(text, coolHours: copy.coolHours)
            draft = ""
            sending = false
        }
    }
}

/// Rollers and belt. `phase` animates the rollers turning.
struct Conveyor: View {
    var phase: CGFloat

    var body: some View {
        GeometryReader { g in
            let count = 7
            ZStack {
                Rectangle().fill(Palette.bone.opacity(0.7)).frame(height: 2).offset(y: -11)
                Rectangle().fill(Palette.bone.opacity(0.7)).frame(height: 2).offset(y: 11)
                ForEach(0..<count, id: \.self) { i in
                    ZStack {
                        Circle().stroke(Palette.bone, lineWidth: 2)
                        Rectangle().fill(Palette.bone).frame(width: 2, height: 14)
                    }
                    .frame(width: 18, height: 18)
                    .rotationEffect(.degrees(Double(phase) * 720))
                    .position(x: g.size.width * (CGFloat(i) + 0.5) / CGFloat(count), y: g.size.height / 2)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct HotSlip: View {
    let item: IntakeItem
    let ambient: Double
    let now: Date

    var body: some View {
        let p = IntakeStore.progress(item, now: now)
        let temp = IntakeStore.temperature(item, ambient: ambient, now: now)
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(Int(temp.rounded())) °C")
                    .font(AFont.display(24))
                    .monospacedDigit()
                    .foregroundStyle(Temper.ink(p))
                Spacer()
                Text(IntakeStore.timeLeft(item, now: now).uppercased())
                    .font(AFont.label(12))
                    .tracking(1.4)
                    .foregroundStyle(Palette.boneDim)
            }
            Text(item.text)
                .font(AFont.narrator(17))
                .foregroundStyle(Palette.bone.opacity(0.75))
                .lineLimit(3)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.rule)
                    Capsule().fill(Temper.fill(p)).frame(width: max(6, g.size.width * p))
                }
            }
            .frame(height: 4)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 6).fill(Palette.soot2))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Temper.fill(p).opacity(0.7), lineWidth: 1.5))
        .contextMenu {
            Button("Take it back out", role: .destructive) { IntakeStore.shared.letGo(item) }
        }
        .accessibilityElement(children: .combine)
    }
}

struct CooledSlip: View {
    let item: IntakeItem
    let reply: String
    let onLetGo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow("Cooled · \(ADate.short.string(from: item.broughtIn))", color: Palette.tagInkDim, size: 12)
                Spacer()
                Text("COOLED")
                    .font(AFont.display(13))
                    .tracking(1.6)
                    .foregroundStyle(Color(hex: 0x1f356e))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .overlay(Rectangle().stroke(Color(hex: 0x1f356e), lineWidth: 2))
                    .rotationEffect(.degrees(-8))
            }
            Text(item.text)
                .font(AFont.narrator(17))
                .foregroundStyle(Palette.tagInk)
                .fixedSize(horizontal: false, vertical: true)
            Text(reply)
                .font(AFont.narratorItalic(18))
                .foregroundStyle(Palette.tagInk)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.28))
                .overlay(alignment: .leading) { Rectangle().fill(Palette.tagInkDim).frame(width: 2) }
            Button("Let it go", action: onLetGo)
                .font(AFont.label(15))
                .tracking(1.4)
                .foregroundStyle(Palette.tagInk)
        }
        .padding(16)
        .background(PaperBackground())
    }
}
