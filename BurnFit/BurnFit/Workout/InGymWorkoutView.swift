import SwiftUI
import SwiftData

/// Allenamento attivo. Va presentata dentro un NavigationStack (lo fa `WorkoutDayDetailView`).
///
/// - Il timer di allenamento parte quando questa schermata si apre, cioè SOLO dopo
///   aver premuto "Avvia allenamento" nell'anteprima del giorno.
/// - Si vede UN esercizio alla volta; "Esercizio successivo" passa al prossimo.
/// - Recuperi specifici dell'esercizio: dopo ogni serie parte il recupero "tra le serie",
///   dopo l'ultima serie parte il recupero di "cambio esercizio".
/// - "Termina allenamento" è sempre visibile (infortuni, imprevisti...).
/// A fine sessione salva un `SessionSummary`, segna il giorno come completato e mostra `SummaryView`.
struct InGymWorkoutView: View {
    let day: WorkoutDay
    var onClose: () -> Void

    @Environment(\.modelContext) private var context
    @Query private var profili: [UserProfile]

    @State private var inizio = Date.now
    @State private var indice = 0
    @State private var avanti = true          // direzione dell'animazione tra esercizi
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

    init(day: WorkoutDay, onClose: @escaping () -> Void) {
        self.day = day
        self.onClose = onClose
        let proprietario = day.plan?.proprietario ?? ""
        _profili = Query(filter: #Predicate<UserProfile> { $0.proprietario == proprietario })
    }

    private var proprietario: String { day.plan?.proprietario ?? "" }
    private var pesoKg: Double { profili.first?.pesoKg ?? 70 }
    private var livello: LivelloEsperienza { profili.first?.livello ?? .intermedio }
    private var esercizi: [ExerciseInPlan] { day.eserciziOrdinati }
    private var eserciziCompletati: Int { day.esercizi.filter { $0.completato }.count }
    private var eserciziTotali: Int { day.esercizi.count }
    private var serieFatte: Int { day.esercizi.reduce(0) { $0 + $1.serieCompletate } }
    private var serieTotali: Int { day.esercizi.reduce(0) { $0 + $1.serie } }

    private var corrente: ExerciseInPlan? {
        esercizi.indices.contains(indice) ? esercizi[indice] : nil
    }
    private var isUltimo: Bool { indice >= esercizi.count - 1 }

    var body: some View {
        if let riepilogo {
            SummaryView(summary: riepilogo, onClose: onClose)
        } else {
            workout
        }
    }

    // MARK: - Schermata allenamento

    private var workout: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 14) {
                    header.id("inizio")

                    // Solo l'esercizio corrente: gli altri non sono visibili
                    if let item = corrente {
                        ExerciseRowView(item: item,
                                        onSerieCompletata: { avviaRiposo(item) },
                                        onSostituisci: { daSostituire = item })
                            .id(item.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: avanti ? .trailing : .leading).combined(with: .opacity),
                                removal: .move(edge: avanti ? .leading : .trailing).combined(with: .opacity)))
                    }
                }
                .padding()
            }
            .onChange(of: indice) { _, _ in
                withAnimation { proxy.scrollTo("inizio", anchor: .top) }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(day.nome)
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
        .safeAreaInset(edge: .bottom) { barraInferiore }
        .sheet(item: $daSostituire) { item in
            ReplaceExerciseSheet(item: item, livello: livello)
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
            inizio = .now
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
                HStack {
                    Text("Esercizio \(min(indice + 1, eserciziTotali)) di \(eserciziTotali)")
                        .bold()
                    Spacer()
                    Text("\(serieFatte)/\(serieTotali) serie")
                }
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

            HStack(spacing: 10) {
                Button { vai(a: indice - 1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 52, height: 52)
                        .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
                .disabled(indice == 0)
                .opacity(indice == 0 ? 0.4 : 1)
                .accessibilityLabel("Esercizio precedente")

                Button(action: successivo) {
                    Label(isUltimo ? "Concludi allenamento" : "Esercizio successivo",
                          systemImage: isUltimo ? "flag.checkered" : "forward.fill")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.orange, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }

            Button { mostraUscita = true } label: {
                Label("Termina allenamento", systemImage: "xmark.octagon")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.6), lineWidth: 1.5))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.bar)
    }

    // MARK: - Azioni

    private func vai(a nuovo: Int) {
        guard esercizi.indices.contains(nuovo) else { return }
        avanti = nuovo > indice
        withAnimation(.easeInOut(duration: 0.3)) { indice = nuovo }
    }

    private func successivo() {
        if isUltimo {
            // Tutto fatto: salva subito. Altrimenti chiede conferma.
            if serieFatte >= serieTotali && serieTotali > 0 {
                terminaESalva()
            } else {
                mostraUscita = true
            }
        } else {
            vai(a: indice + 1)
        }
    }

    private func avviaRiposo(_ item: ExerciseInPlan) {
        let nome = item.exercise?.nome ?? "Esercizio"
        let pos = esercizi.firstIndex(where: { $0.id == item.id }) ?? indice

        withAnimation {
            if item.serieCompletate < item.serie {
                // Recupero tra una serie e l'altra
                riposo = Riposo(titolo: "\(nome) · serie \(item.serieCompletate)/\(item.serie)",
                                secondi: item.recuperoSecondi)
            } else if pos < esercizi.count - 1 {
                // Ultima serie fatta: recupero di cambio esercizio
                let prossimo = esercizi[pos + 1].exercise?.nome ?? "prossimo esercizio"
                riposo = Riposo(titolo: "Cambio esercizio · poi \(prossimo)",
                                secondi: item.recuperoCambioSecondi)
            } else {
                // Ultima serie dell'ultimo esercizio: niente recupero
                riposo = nil
            }
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
            distribuzione: distribuzione,
            proprietario: proprietario
        )
        context.insert(sommario)
        day.completato = true
        day.dataCompletamento = fine
        try? context.save()

        riposo = nil
        riepilogo = sommario
    }
}
