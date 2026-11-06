import SwiftUI
import SwiftData

/// Anteprima di un giorno della scheda: elenco compatto degli esercizi
/// (immagine, nome, serie × ripetizioni, recupero). Entrare qui NON avvia il timer:
/// l'allenamento parte solo con il tasto "Avvia allenamento" in fondo.
struct WorkoutDayDetailView: View {
    let day: WorkoutDay

    @State private var inCorso = false
    @State private var mostraRipeti = false

    private var esercizi: [ExerciseInPlan] { day.eserciziOrdinati }

    var body: some View {
        List {
            Section {
                intestazione
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }

            Section("\(esercizi.count) esercizi") {
                ForEach(Array(esercizi.enumerated()), id: \.element.id) { indice, item in
                    riga(item, numero: indice + 1)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Giorno \(day.indice)")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { pulsanteAvvia }
        .alert("Ripetere l'allenamento?", isPresented: $mostraRipeti) {
            Button("Ripeti") { inCorso = true }
            Button("Annulla", role: .cancel) {}
        } message: {
            Text("\(day.nome) è già stato completato. Vuoi rifarlo?")
        }
        .fullScreenCover(isPresented: $inCorso) {
            NavigationStack {
                InGymWorkoutView(day: day) { inCorso = false }
            }
        }
    }

    // MARK: - Componenti

    private var intestazione: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(day.nome).font(.title3.bold())
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(day.gruppi) { g in
                        Label(g.rawValue, systemImage: g.icona)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(g.colore.opacity(0.18), in: Capsule())
                            .foregroundStyle(g.colore)
                    }
                }
            }
            HStack(spacing: 14) {
                Label("~\(day.durataStimataMinuti) min", systemImage: "clock")
                if day.completato {
                    Label("Completato", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    private func riga(_ item: ExerciseInPlan, numero: Int) -> some View {
        HStack(spacing: 12) {
            ExerciseImageView(exercise: item.exercise)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topLeading) {
                    Text("\(numero)")
                        .font(.caption2.bold())
                        .frame(width: 18, height: 18)
                        .background(Color.orange, in: Circle())
                        .foregroundStyle(.white)
                        .offset(x: -5, y: -5)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.exercise?.nome ?? "Esercizio")
                    .font(.subheadline.bold())
                    .lineLimit(2)
                Text("\(item.serie) serie × \(item.reps) reps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("Recupero \(item.recuperoSecondi.mmss)", systemImage: "timer")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private var pulsanteAvvia: some View {
        Button {
            if day.completato { mostraRipeti = true } else { inCorso = true }
        } label: {
            Label(day.completato ? "Ripeti allenamento" : "Avvia allenamento", systemImage: "play.fill")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(esercizi.isEmpty)
        .padding()
        .background(.bar)
    }
}
