import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var piani: [WorkoutPlan]
    @Query private var profili: [UserProfile]

    @State private var giornoInCorso: WorkoutDay?
    @State private var giornoDaRipetere: WorkoutDay?
    @State private var mostraRipeti = false
    @State private var mostraConfermaRicrea = false

    private var piano: WorkoutPlan? { piani.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let piano {
                        riepilogo(piano)
                        ForEach(piano.giorniOrdinati) { day in
                            Button { avvia(day) } label: {
                                WorkoutDayCardView(day: day)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        ContentUnavailableView("Nessuna scheda",
                                               systemImage: "figure.walk",
                                               description: Text("Crea la tua scheda dall'onboarding."))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("La tua settimana")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { nuovaSettimana() } label: {
                            Label("Nuova settimana", systemImage: "arrow.counterclockwise")
                        }
                        Button(role: .destructive) { mostraConfermaRicrea = true } label: {
                            Label("Ricrea la scheda", systemImage: "wand.and.stars")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .fullScreenCover(item: $giornoInCorso) { day in
                NavigationStack {
                    InGymWorkoutView(day: day) { giornoInCorso = nil }
                }
            }
            .alert("Ripetere l'allenamento?", isPresented: $mostraRipeti, presenting: giornoDaRipetere) { day in
                Button("Ripeti") { giornoInCorso = day }
                Button("Annulla", role: .cancel) {}
            } message: { day in
                Text("\(day.nome) è già stato completato. Vuoi rifarlo?")
            }
            .confirmationDialog("Ricreare la scheda?",
                                isPresented: $mostraConfermaRicrea,
                                titleVisibility: .visible) {
                Button("Elimina e ricrea", role: .destructive) { ricreaScheda() }
                Button("Annulla", role: .cancel) {}
            } message: {
                Text("La scheda attuale verrà eliminata. Lo storico dei progressi resta salvato.")
            }
        }
    }

    // MARK: - Componenti

    private func riepilogo(_ piano: WorkoutPlan) -> some View {
        let totale = max(piano.giorni.count, 1)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Questa settimana").font(.headline)
                Spacer()
                Text("\(piano.completati)/\(piano.giorni.count)")
                    .font(.title3.bold())
                    .foregroundStyle(.orange)
            }
            ProgressView(value: Double(piano.completati), total: Double(totale))
                .tint(.orange)
            if let p = profili.first {
                Text("\(p.giorniSettimana) giorni · \(p.livello.rawValue) · \(p.durataMinuti) min")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Azioni

    private func avvia(_ day: WorkoutDay) {
        if day.completato {
            giornoDaRipetere = day
            mostraRipeti = true
        } else {
            giornoInCorso = day
        }
    }

    private func nuovaSettimana() {
        guard let piano else { return }
        for d in piano.giorni {
            d.completato = false
            d.dataCompletamento = nil
        }
        try? context.save()
    }

    private func ricreaScheda() {
        for p in piani { context.delete(p) }
        for pr in profili { context.delete(pr) }
        try? context.save()   // RootView torna all'onboarding
    }
}
