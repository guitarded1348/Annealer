import SwiftUI
import UIKit

/// The front counter: a bell and a ledger. Signups go to the same list as the website's.
struct CounterView: View {
    @EnvironmentObject var store: ContentStore
    @State var name = ""
    @State var email = ""
    @State var reply = ""
    @State var sending = false
    @State var rings = 0
    @FocusState var focus: Field?

    enum Field { case name, email }

    var body: some View {
        let c = store.content.counter
        ZStack {
            SootBackground(glowStrength: 0.12)
            ScrollView {
                VStack(spacing: 22) {
                    Button {
                        ring()
                    } label: {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(Palette.straw)
                            .rattle(rings)
                            .frame(width: 120, height: 120)
                            .background(Circle().fill(Palette.soot2))
                            .overlay(Circle().stroke(Palette.bone, lineWidth: 2.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Ring the bell")
                    .padding(.top, 28)

                    Text(c.title.uppercased())
                        .font(AFont.display(36))
                        .foregroundStyle(Palette.bone)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow("Intake ledger · correspondence", color: Palette.tagInkDim, size: 12)
                        Rectangle().fill(Palette.tagInkDim).frame(height: 1)
                        Text(intro(c))
                            .font(AFont.narratorItalic(18))
                            .foregroundStyle(Palette.tagInk)
                            .fixedSize(horizontal: false, vertical: true)
                        field("Name") {
                            TextField("", text: $name)
                                .textContentType(.name)
                                .focused($focus, equals: .name)
                                .submitLabel(.next)
                                .onSubmit { focus = .email }
                        }
                        field("Where to send word") {
                            TextField("", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focus, equals: .email)
                                .submitLabel(.send)
                                .onSubmit { Task { await submit(c) } }
                        }
                        Button {
                            Task { await submit(c) }
                        } label: {
                            HStack(spacing: 8) {
                                if sending { ProgressView().tint(Palette.manila) } else { Image(systemName: "bell") }
                                Text(c.button.uppercased()).font(AFont.display(18)).tracking(1.6)
                            }
                            .foregroundStyle(Palette.manila)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(Palette.tagInk)
                        }
                        .disabled(sending)
                        .padding(.top, 6)
                        if !reply.isEmpty {
                            Text(reply)
                                .font(AFont.narratorItalic(18))
                                .foregroundStyle(Palette.tagInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(22)
                    .background(PaperBackground())
                    .rotationEffect(.degrees(-0.6))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func field<Input: View>(_ label: String, @ViewBuilder _ input: () -> Input) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(AFont.label(13))
                .tracking(1.6)
                .foregroundStyle(Palette.tagInkDim)
            input()
                .font(AFont.narrator(21))
                .foregroundStyle(Palette.tagInk)
                .tint(Palette.tagInk)
                .padding(.vertical, 4)
                .overlay(alignment: .bottom) { Rectangle().fill(Palette.tagInk).frame(height: 2) }
        }
        .padding(.top, 6)
    }

    private func intro(_ c: CounterCopy) -> String {
        if let saved = CounterDesk.savedName, !saved.isEmpty {
            return c.returning.replacingOccurrences(of: "{name}", with: saved)
        }
        return c.intro
    }

    private func ring() {
        withAnimation(.linear(duration: 0.5)) { rings += 1 }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    @MainActor
    private func submit(_ c: CounterCopy) async {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if n.isEmpty { reply = c.noName; focus = .name; return }
        let bare = n.lowercased().replacingOccurrences(of: "the ", with: "")
        if bare == "annealer" { reply = c.selfName; name = ""; focus = .name; return }
        if !CounterDesk.looksLikeEmail(e) { reply = c.badEmail; focus = .email; return }

        ring()
        sending = true
        let ok = await CounterDesk.sign(name: n, email: e)
        sending = false
        if ok {
            CounterDesk.savedName = n
            let pool = c.replies ?? [c.thanks ?? "Noted."]
            reply = pool.randomElement() ?? "Noted."
            name = ""
            email = ""
            focus = nil
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            reply = c.failed ?? "The bell didn't ring. Try again in a moment."
        }
    }
}
