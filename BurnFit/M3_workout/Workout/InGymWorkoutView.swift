import SwiftUI
import SwiftData

/// Allenamento attivo. Va presentata dentro un NavigationStack (lo fa la Dashboard).
/// Il recupero parte dopo OGNI serie completata. A fine sessione salva un `SessionSummary`,
/// segna il giorno come completato e mostra `SummaryView` al posto della lista esercizi.
struct InGymWorkoutView: View {
    let day: WorkoutDay
    var onClose: () -> Void

    @Environment(\.modelContext) private var context
    @Query private var profili: [UserProfile]

    @State private var inizio = Date.now
    @State private var riposo: Riposo?
    @State private var daSostituire: ExerciseInPlan?
    @State private var mostraUscita = false
    @State private var riepilogo: SessionSummary?
    @State private var inizializzato = false

    private struct Riposo: Identifiable {
        let id = UUID()
        let titolo: String
        let secondi: Int
    }

    private var pesoKg: Double { profili.first?.pesoKg ?? 70 }
    private var esercizi: [ExerciseInPlan] { day.eserciziOrdinati }
    private var eserciziCompletati: Int { day.esercizi.filter { $0.completato }.count }
    private var eserciziTotali: Int { day.esercizi.count }
    private var serieFatte: Int { day.esercizi.reduce(0) { $0 + $1.serieCompletate } }
    private var serieTotali: Int { day.esercizi.reduce(0) { $0 + $1.serie } }

    var body: some View {
        if let riepilogo {
            SummaryView(summary: riepilogo, onClose: onClose)
        } else {
            workout
        }
    }

    // MARK: - Schermata allenamento

    private var workout: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                ForEach(esercizi) { item in
                    ExerciseRowView(item: item,
                                    onSerieCompletata: { avviaRiposo(item) },
                                    onSostituisci: { daSostituire = item })
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(day.nome)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Chiudi") { mostraUscita = true }
            }
        }
        .safeAreaInset(edge: .bottom) { barraInferiore }
        .sheet(item: $daSostituire) { item in
            ReplaceExerciseSheet(item: item)
        }
        .confirmationDialog("Terminare l'allenamento?",
                            isPresented: $mostraUscita,
                            titleVisibility: .visible) {
            if serieFatte > 0 {
                Button("Termina e salva") { terminaESalva() }
            }
            Button("Esci senza salvare", role: .destructive) { onClose() }
            Button("Continua", role: .cancel) {}
        } message: {
            Text(serieFatte > 0
                 ? "Hai completato \(serieFatte) serie su \(serieTotali)."
                 : "Non hai ancora completato nessuna serie: uscendo non verrà salvato nulla.")
        }
        .onAppear {
            // Se si ripete un giorno già completato si riparte da zero
            guard !inizializzato else { return }
            inizializzato = true
            for e in day.esercizi {
                e.completato = false
                e.serieCompletate = 0
            }
        }
    }

    private var header: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let secondi = max(0, Int(ctx.date.timeIntervalSince(inizio)))
            let kcal = CalorieEstimator.stima(durataSecondi: secondi, pesoKg: pesoKg)

            VStack(spacing: 14) {
                HStack {
                    metrica("clock", "Inizio", inizio.formatted(date: .omitted, time: .shortened))
                    Divider().frame(height: 36)
                    metrica("timer", "Durata", secondi.mmss)
                    Divider().frame(height: 36)
                    metrica("flame.fill", "Calorie", "\(kcal) kcal")
                }
                ProgressView(value: Double(serieFatte), total: Double(max(serieTotali, 1)))
                    .tint(.orange)
                Text("\(serieFatte) di \(serieTotali) serie · \(eserciziCompletati)/\(eserciziTotali) esercizi")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private func metrica(_ icona: String, _ titolo: String, _ valore: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icona).foregroundStyle(.orange)
            Text(valore)
                .font(.system(.subheadline, design: .rounded).bold())
                .monospacedDigit()
            Text(titolo).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var barraInferiore: some View {
        VStack(spacing: 10) {
            if let riposo {
                RestTimerView(titolo: riposo.titolo, secondi: riposo.secondi) {
                    withAnimation { self.riposo = nil }
                }
                .id(riposo.id)   // ogni serie fa ripartire il timer da capo
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            Button { mostraUscita = true } label: {
                Text("Termina allenamento")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .background(.bar)
    }

    // MARK: - Azioni

    private func avviaRiposo(_ item: ExerciseInPlan) {
        let nome = item.exercise?.nome ?? "Esercizio"
        withAnimation {
            riposo = Riposo(titolo: "\(nome) · serie \(item.serieCompletate)/\(item.serie)",
                            secondi: item.recuperoSecondi)
        }
    }

    private func terminaESalva() {
        let fine = Date.now
        let durata = max(0, Int(fine.timeIntervalSince(inizio)))

        var distribuzione: [GruppoMuscolare: Int] = [:]
        for e in day.esercizi where e.serieCompletate > 0 {
            if let g = e.exercise?.gruppo { distribuzione[g, default: 0] += e.serieCompletate }
        }

        let sommario = SessionSummary(
            dataFine: fine,
            inizio: inizio,
            durataSecondi: durata,
            calorie: CalorieEstimator.stima(durataSecondi: durata, pesoKg: pesoKg),
            nomeGiorno: day.nome,
            eserciziCompletati: eserciziCompletati,
            eserciziTotali: eserciziTotali,
            serieCompletate: serieFatte,
            distribuzione: distribuzione
        )
        context.insert(sommario)
        day.completato = true
        day.dataCompletamento = fine
        try? context.save()

        riposo = nil
        riepilogo = sommario
    }
}
