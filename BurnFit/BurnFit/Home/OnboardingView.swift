import SwiftUI
import SwiftData

struct OnboardingView: View {
    /// Email dell'utente loggato: profilo e scheda vengono salvati a suo nome
    let email: String

    @Environment(\.modelContext) private var context
    @AppStorage("utenteCorrente") private var utenteCorrente = ""

    @State private var step = 0
    @State private var giorni = 3
    @State private var focus: Set<GruppoMuscolare> = []
    @State private var livello: LivelloEsperienza = .principiante
    @State private var durata: Double = 60
    @State private var peso: Double = 70
    @State private var errore: String?

    private let ultimoStep = 3
    private var tuttiSelezionati: Bool { focus.count == GruppoMuscolare.allCases.count }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                Group {
                    switch step {
                    case 0: giorniStep
                    case 1: focusStep
                    case 2: livelloStep
                    default: durataStep
                    }
                }
                .padding()
            }

            footer
        }
        .background(Color(.systemGroupedBackground))
        .animation(.easeInOut(duration: 0.2), value: step)
        .alert("Errore", isPresented: Binding(get: { errore != nil }, set: { if !$0 { errore = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errore ?? "")
        }
    }

    // MARK: - Struttura

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flame.fill").foregroundStyle(.orange)
                Text("BurnFit").font(.title2.bold())
                Spacer()
                Text("Passo \(step + 1) di \(ultimoStep + 1)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Menu {
                    Button(role: .destructive) { utenteCorrente = "" } label: {
                        Label("Esci dall'account", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.title3)
                        .foregroundStyle(.orange)
                }
            }
            ProgressView(value: Double(step + 1), total: Double(ultimoStep + 1))
                .tint(.orange)
        }
        .padding()
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button { step -= 1 } label: {
                    Text("Indietro").frame(maxWidth: .infinity).padding()
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.primary)
            }
            Button {
                if step < ultimoStep { step += 1 } else { creaScheda() }
            } label: {
                Text(step < ultimoStep ? "Avanti" : "Crea la mia scheda")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(Color.orange, in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
        }
        .padding()
        .background(.bar)
    }

    private func titolo(_ testo: String, _ sottotitolo: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(testo).font(.title.bold())
            Text(sottotitolo).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Step 1: giorni

    private var giorniStep: some View {
        VStack(spacing: 24) {
            titolo("Quanti giorni vuoi allenarti?", "Scegli da 2 a 5 giorni a settimana.")
            HStack(spacing: 12) {
                ForEach(2...5, id: \.self) { n in
                    Button { giorni = n } label: {
                        VStack(spacing: 4) {
                            Text("\(n)").font(.system(size: 40, weight: .bold, design: .rounded))
                            Text("giorni").font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                        .background(giorni == n ? Color.orange : Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(giorni == n ? Color.white : Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Step 2: focus muscolare

    private var focusStep: some View {
        VStack(spacing: 24) {
            titolo("Su cosa vuoi puntare?", "Scegli tutti i gruppi muscolari che vuoi enfatizzare (facoltativo).")

            HStack {
                Spacer()
                Button(tuttiSelezionati ? "Deseleziona tutti" : "Seleziona tutti") {
                    focus = tuttiSelezionati ? [] : Set(GruppoMuscolare.allCases)
                }
                .font(.subheadline.bold())
                .foregroundStyle(.orange)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                ForEach(GruppoMuscolare.allCases) { g in
                    let selezionato = focus.contains(g)
                    Button {
                        if selezionato {
                            focus.remove(g)
                        } else {
                            focus.insert(g)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: g.icona)
                            Text(g.rawValue).bold()
                            Spacer(minLength: 0)
                            if selezionato { Image(systemName: "checkmark.circle.fill") }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(selezionato ? g.colore.opacity(0.2) : Color(.secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selezionato ? g.colore : Color.clear, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(testoFocus)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var testoFocus: String {
        if focus.isEmpty { return "Nessun focus: scheda bilanciata." }
        if tuttiSelezionati { return "Tutti i gruppi selezionati: la scheda sarà bilanciata su tutto il corpo." }
        return "Selezionati: \(focus.count) di \(GruppoMuscolare.allCases.count). I gruppi scelti riceveranno più esercizi."
    }

    // MARK: - Step 3: livello

    private var livelloStep: some View {
        VStack(spacing: 20) {
            titolo("Qual è la tua esperienza?", "Adatteremo serie, ripetizioni e recuperi.")
            ForEach(LivelloEsperienza.allCases) { l in
                Button { livello = l } label: {
                    HStack(spacing: 14) {
                        Image(systemName: l.icona)
                            .font(.title2)
                            .frame(width: 44)
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(l.rawValue).font(.headline)
                            Text(l.descrizione).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: livello == l ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(livello == l ? Color.orange : Color.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(livello == l ? Color.orange : Color.clear, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(Color.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Step 4: durata + riepilogo

    private var durataStep: some View {
        VStack(spacing: 24) {
            titolo("Quanto tempo hai a sessione?", "Useremo questo dato per decidere quanti esercizi inserire.")

            VStack(spacing: 8) {
                Text("\(Int(durata)) min")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
                Slider(value: $durata, in: 30...90, step: 5)
                    .tint(.orange)
                HStack {
                    Text("30 min"); Spacer(); Text("90 min")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 8) {
                Text("Peso corporeo").font(.headline)
                Text("Serve per stimare le calorie bruciate.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Stepper(value: $peso, in: 35...200, step: 1) {
                    Text("\(Int(peso)) kg")
                        .font(.system(.title2, design: .rounded).bold())
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 10) {
                Text("Riepilogo").font(.headline)
                riga("calendar", "\(giorni) giorni a settimana")
                riga("target", focus.isEmpty ? "Scheda bilanciata" : GruppoMuscolare.allCases.filter { focus.contains($0) }.map(\.rawValue).joined(separator: ", "))
                riga(livello.icona, livello.rawValue)
                riga("clock", "\(Int(durata)) minuti per sessione")
                riga("scalemass", "\(Int(peso)) kg")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func riga(_ icona: String, _ testo: String) -> some View {
        Label(testo, systemImage: icona).foregroundStyle(.primary)
    }

    // MARK: - Salvataggio e generazione scheda

    private func creaScheda() {
        // Sostituisce solo il profilo dell'utente corrente
        let proprietario = email
        let descrittore = FetchDescriptor<UserProfile>(predicate: #Predicate<UserProfile> { $0.proprietario == proprietario })
        if let vecchi = try? context.fetch(descrittore) {
            for p in vecchi { context.delete(p) }
        }

        let profilo = UserProfile(
            giorniSettimana: giorni,
            gruppiFocus: GruppoMuscolare.allCases.filter { focus.contains($0) },
            livello: livello,
            durataMinuti: Int(durata),
            pesoKg: peso,
            proprietario: email
        )
        context.insert(profilo)

        SampleData.popolaSeNecessario(context: context)
        let catalogo = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        guard !catalogo.isEmpty else {
            errore = "Il catalogo esercizi è vuoto."
            return
        }

        WorkoutGenerator.genera(profilo: profilo, catalogo: catalogo, context: context)
        do {
            try context.save()   // RootView passa da solo alla Dashboard
        } catch {
            errore = error.localizedDescription
        }
    }
}
