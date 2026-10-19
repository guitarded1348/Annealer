import SwiftUI

/// Found behind the Boltzmann constant: a note whose letters untangle themselves by real
/// simulated annealing. Swap two letters; keep it if it's better, and sometimes keep it anyway
/// while it's still hot enough not to know better (Metropolis); cool a little; repeat.
struct TangleView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State var letters: [Character] = []
    @State var temperature = 4.0
    @State var keptWorse = 0
    @State var running = false
    @State var done = false

    let target = Array("COOL IT SLOWLY AND IT FORGETS IT WAS EVER ANGRY")

    private var slots: [Int] { target.indices.filter { target[$0] != " " } }
    private var wrong: Int { letters.isEmpty ? slots.count : slots.filter { letters[$0] != target[$0] }.count }

    var body: some View {
        ZStack {
            SootBackground(glowStrength: 0.1)
            VStack(alignment: .leading, spacing: 18) {
                Eyebrow("Fig. ∞ · Found in a drawer", color: Temper.ink(0.8))
                Text("A NOTE, TANGLED")
                    .font(AFont.display(36))
                    .foregroundStyle(Palette.bone)
                styledLetters
                    .font(AFont.display(30))
                    .tracking(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 90, alignment: .topLeading)
                    .accessibilityLabel(done ? String(target) : "Tangled letters")
                Text("T = \(String(format: "%.2f", temperature)) · wrong letters: \(wrong) · kept worse: \(keptWorse)")
                    .font(AFont.label(14))
                    .monospacedDigit()
                    .foregroundStyle(Palette.boneDim)
                HStack(spacing: 12) {
                    Button(done ? "Heat it again" : "Lower the temperature") {
                        Task { await anneal() }
                    }
                    .font(AFont.label(16))
                    .foregroundStyle(Palette.soot)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Temper.ink(0.8))
                    .disabled(running)
                    Button("Put it back") { dismiss() }
                        .font(AFont.label(16))
                        .foregroundStyle(Palette.bone)
                }
                if done {
                    Text("Mathematicians call this simulated annealing (Kirkpatrick, Gelatt & Vecchi, 1983). I call it Tuesday.")
                        .font(AFont.narratorItalic(18))
                        .foregroundStyle(Palette.boneDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(24)
        }
        .onAppear { scramble() }
        .presentationDragIndicator(.visible)
    }

    private var styledLetters: Text {
        guard !letters.isEmpty else { return Text("") }
        return letters.indices.reduce(Text("")) { text, i in
            text + Text(String(letters[i]))
                .foregroundColor(letters[i] == target[i] ? Palette.bone : Temper.ink(0.8))
        }
    }

    private func scramble() {
        var l = target
        let s = slots
        for k in stride(from: s.count - 1, to: 0, by: -1) {
            let j = Int.random(in: 0...k)
            l.swapAt(s[k], s[j])
        }
        letters = l
        temperature = 4
        keptWorse = 0
        done = false
    }

    /// One Metropolis step: returns 1 if it kept a worse arrangement.
    private func step(_ t: Double) -> Int {
        let s = slots
        let a = s[Int.random(in: 0..<s.count)], b = s[Int.random(in: 0..<s.count)]
        guard a != b, letters[a] != letters[b] else { return 0 }
        let before = (letters[a] != target[a] ? 1 : 0) + (letters[b] != target[b] ? 1 : 0)
        let after = (letters[b] != target[a] ? 1 : 0) + (letters[a] != target[b] ? 1 : 0)
        let dE = Double(after - before)
        if dE <= 0 || Double.random(in: 0..<1) < exp(-dE / t) {
            letters.swapAt(a, b)
            return dE > 0 ? 1 : 0
        }
        return 0
    }

    @MainActor
    private func anneal() async {
        if done { scramble() }
        running = true
        var frames = 0
        while wrong > 0 && frames < 900 {
            var kept = 0
            for _ in 0..<30 { kept += step(max(temperature, 0.01)) }
            keptWorse += kept
            temperature *= 0.985
            frames += 1
            if !reduceMotion { try? await Task.sleep(nanoseconds: 33_000_000) }
        }
        letters = target
        running = false
        done = true
    }
}
