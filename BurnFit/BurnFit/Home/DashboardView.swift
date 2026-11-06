import SwiftUI
import SwiftData

struct DashboardView: View {
    let email: String

    @Environment(\.modelContext) private var context
    @AppStorage("utenteCorrente") private var utenteCorrente = ""
    @Query private var piani: [WorkoutPlan]
    @Query private var profili: [UserProfile]
    @Query private var account: [UserAccount]

    @State private var mostraConfermaRicrea = false
    @State private var mostraConfermaLogout = false

    init(email: String) {
        self.email = email
        _piani = Query(filter: #Predicate<WorkoutPlan> { $0.proprietario == email },
                       sort: \WorkoutPlan.createdAt, order: .reverse)
        _profili = Query(filter: #Predicate<UserProfile> { $0.proprietario == email })
        _account = Query(filter: #Predicate<UserAccount> { $0.email == email })
    }

    private var piano: WorkoutPlan? { piani.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let nome = account.first?.nome {
                        Text("Ciao, \(nome) 👋")
                            .font(.title3.bold())
                    }
                    if let piano {
                        riepilogo(piano)
                        ForEach(piano.giorniOrdinati) { day in
                            // Apre l'anteprima del giorno: il timer NON parte qui
                            NavigationLink {
                                WorkoutDayDetailView(day: day)
                            } label: {
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
                        Divider()
                        Button(role: .destructive) { mostraConfermaLogout = true } label: {
                            Label("Esci dall'account", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .confirmationDialog("Ricreare la scheda?",
                                isPresented: $mostraConfermaRicrea,
                                titleVisibility: .visible) {
                Button("Elimina e ricrea", role: .destructive) { ricreaScheda() }
                Button("Annulla", role: .cancel) {}
            } message: {
                Text("La scheda attuale verrà eliminata. Lo storico dei progressi resta salvato.")
            }
            .confirmationDialog("Uscire dall'account?",
                                isPresented: $mostraConfermaLogout,
                                titleVisibility: .visible) {
                Button("Esci", role: .destructive) { utenteCorrente = "" }
                Button("Annulla", role: .cancel) {}
            } message: {
                Text("La tua scheda e i tuoi progressi restano salvati su questo dispositivo.")
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
