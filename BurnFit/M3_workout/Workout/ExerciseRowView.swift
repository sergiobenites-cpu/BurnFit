import SwiftUI

/// Riga di un esercizio: pallini serie (tocca per completare e avviare il recupero),
/// sostituzione e modifica di serie/reps. Modifica direttamente `ExerciseInPlan`.
struct ExerciseRowView: View {
    let item: ExerciseInPlan
    /// Chiamata ogni volta che una serie viene completata (parte il recupero)
    var onSerieCompletata: () -> Void
    var onSostituisci: () -> Void

    private var gruppo: GruppoMuscolare? { item.exercise?.gruppo }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Button(action: toggleTutto) {
                    Image(systemName: item.completato ? "checkmark.circle.fill" : "circle")
                        .font(.title)
                        .foregroundStyle(item.completato ? Color.green : Color.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.completato ? "Azzera le serie" : "Segna tutte le serie come fatte")

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.exercise?.nome ?? "Esercizio")
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    if let g = gruppo, let e = item.exercise {
                        Label("\(g.rawValue) · \(e.attrezzatura)", systemImage: g.icona)
                            .font(.caption.bold())
                            .foregroundStyle(g.colore)
                    }
                }
                Spacer(minLength: 0)

                Button(action: onSostituisci) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.subheadline.bold())
                        .padding(10)
                        .background(Color.orange.opacity(0.15), in: Circle())
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sostituisci esercizio")
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    ForEach(0..<item.serie, id: \.self) { i in
                        pallino(i)
                    }
                }
                Text("Serie \(item.serieCompletate)/\(item.serie) · tocca una serie per completarla e avviare il recupero")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                stepper("Serie", valore: item.serie, minimo: 1, massimo: 10) { nuova in
                    item.serie = nuova
                    item.serieCompletate = min(item.serieCompletate, nuova)
                    aggiornaStato()
                }
                stepper("Reps", valore: item.reps, minimo: 1, massimo: 50) { item.reps = $0 }
                VStack(spacing: 4) {
                    Text("Recupero").font(.caption2).foregroundStyle(.secondary)
                    Text(item.recuperoSecondi.durataBreve)
                        .font(.subheadline.bold())
                        .frame(height: 30)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(item.completato ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.2), value: item.serieCompletate)
    }

    // MARK: - Serie

    private func pallino(_ i: Int) -> some View {
        let fatta = i < item.serieCompletate
        return Button { tocca(i) } label: {
            Text("\(i + 1)")
                .font(.subheadline.bold())
                .frame(width: 38, height: 38)
                .background(fatta ? Color.green : Color.orange.opacity(0.15), in: Circle())
                .foregroundStyle(fatta ? Color.white : Color.orange)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Serie \(i + 1)")
    }

    /// Tocca una serie non fatta: la completa (e tutte le precedenti) e avvia il recupero.
    /// Tocca una serie già fatta: la annulla (e quelle successive), senza recupero.
    private func tocca(_ i: Int) {
        if i < item.serieCompletate {
            item.serieCompletate = i
            aggiornaStato()
        } else {
            item.serieCompletate = i + 1
            aggiornaStato()
            onSerieCompletata()
        }
    }

    private func toggleTutto() {
        item.serieCompletate = item.completato ? 0 : item.serie
        aggiornaStato()
    }

    private func aggiornaStato() {
        item.completato = item.serie > 0 && item.serieCompletate >= item.serie
    }

    private func stepper(_ titolo: String,
                         valore: Int,
                         minimo: Int,
                         massimo: Int,
                         imposta: @escaping (Int) -> Void) -> some View {
        VStack(spacing: 4) {
            Text(titolo).font(.caption2).foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Button { imposta(max(minimo, valore - 1)) } label: {
                    Image(systemName: "minus.circle.fill")
                }
                .disabled(valore <= minimo)

                Text("\(valore)")
                    .font(.system(.body, design: .rounded).bold())
                    .monospacedDigit()
                    .frame(minWidth: 26)

                Button { imposta(min(massimo, valore + 1)) } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(valore >= massimo)
            }
            .font(.title3)
            .foregroundStyle(.orange)
            .buttonStyle(.plain)
            .frame(height: 30)
        }
        .frame(maxWidth: .infinity)
    }
}
