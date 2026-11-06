import SwiftUI

/// Timer di recupero: card in overlay che parte dopo la spunta di un esercizio.
/// Usa una data di fine (non un contatore), così resta preciso anche se l'app va in background.
struct RestTimerView: View {
    let titolo: String
    let secondi: Int
    var onFine: () -> Void

    @State private var fine: Date
    @State private var rimanenti: Int
    @State private var totale: Int
    @State private var terminato = false

    private let tick = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    init(titolo: String, secondi: Int, onFine: @escaping () -> Void) {
        self.titolo = titolo
        self.secondi = secondi
        self.onFine = onFine
        _fine = State(initialValue: Date.now.addingTimeInterval(TimeInterval(secondi)))
        _rimanenti = State(initialValue: secondi)
        _totale = State(initialValue: max(1, secondi))
    }

    private var progresso: Double {
        min(1, max(0, Double(rimanenti) / Double(max(1, totale))))
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Color.orange.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progresso)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: progresso)
                Text(terminato ? "Via!" : rimanenti.mmss)
                    .font(.system(.title3, design: .rounded).bold())
                    .monospacedDigit()
            }
            .frame(width: 84, height: 84)

            VStack(alignment: .leading, spacing: 8) {
                Text("Recupero").font(.headline)
                Text(titolo)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    piccoloBottone("−15") { regola(-15) }
                    piccoloBottone("+15") { regola(15) }
                    Button("Salta") { chiudi() }
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        .onReceive(tick) { _ in aggiorna() }
        .sensoryFeedback(.success, trigger: terminato)
    }

    private func piccoloBottone(_ testo: String, azione: @escaping () -> Void) -> some View {
        Button(testo, action: azione)
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.15), in: Capsule())
            .foregroundStyle(.orange)
    }

    // MARK: - Logica

    private func regola(_ delta: Int) {
        guard !terminato else { return }
        fine = fine.addingTimeInterval(TimeInterval(delta))
        aggiorna()
        totale = max(totale, rimanenti)
    }

    private func aggiorna() {
        guard !terminato else { return }
        let r = max(0, Int(ceil(fine.timeIntervalSinceNow)))
        rimanenti = r
        if r == 0 {
            terminato = true
            Task {
                try? await Task.sleep(for: .seconds(0.8))
                onFine()
            }
        }
    }

    private func chiudi() {
        terminato = true
        onFine()
    }
}

#Preview {
    RestTimerView(titolo: "Panca piana con bilanciere", secondi: 90) {}
        .padding()
}
