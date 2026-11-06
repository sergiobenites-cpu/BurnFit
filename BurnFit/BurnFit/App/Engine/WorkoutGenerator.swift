import Foundation
import SwiftData

/// Motore a regole DETERMINISTICO: a parità di input produce sempre la stessa scheda.
enum WorkoutGenerator {

    struct GiornoTemplate {
        let nome: String
        let gruppi: [GruppoMuscolare]
    }

    // MARK: API pubblica

    /// Genera e salva la scheda settimanale. Sostituisce eventuali schede precedenti.
    @discardableResult
    static func genera(profilo: UserProfile, catalogo: [Exercise], context: ModelContext) -> WorkoutPlan {
        // Elimina solo le schede dello stesso utente
        let proprietario = profilo.proprietario
        let descrittore = FetchDescriptor<WorkoutPlan>(predicate: #Predicate<WorkoutPlan> { $0.proprietario == proprietario })
        if let vecchi = try? context.fetch(descrittore) {
            for p in vecchi { context.delete(p) }
        }

        let piano = WorkoutPlan(giorniSettimana: profilo.giorniSettimana, proprietario: proprietario)
        context.insert(piano)

        let livello = profilo.livello
        let focus = profilo.gruppiFocus
        let slot = eserciziPerGiorno(durataMinuti: profilo.durataMinuti, livello: livello)
        var usati = Set<String>()

        for (i, template) in struttura(giorni: profilo.giorniSettimana, focus: focus).enumerated() {
            let conteggi = ripartisci(gruppi: template.gruppi, focus: focus, slot: slot)

            var scelti: [(exercise: Exercise, base: Int)] = []
            for g in template.gruppi {
                let n = conteggi[g] ?? 0
                guard n > 0 else { continue }
                for e in seleziona(gruppo: g, quanti: n, catalogo: catalogo, livello: livello, usati: &usati) {
                    scelti.append((e, scelti.count))
                }
            }

            // Prima i multiarticolari e i gruppi grandi, poi l'isolamento
            let ordinati = scelti.sorted { a, b in
                if a.exercise.isComposto != b.exercise.isComposto { return a.exercise.isComposto }
                if a.exercise.gruppo.isGrande != b.exercise.gruppo.isGrande { return a.exercise.gruppo.isGrande }
                return a.base < b.base
            }

            let gruppiEffettivi = template.gruppi.filter { (conteggi[$0] ?? 0) > 0 }
            let giorno = WorkoutDay(indice: i + 1, nome: template.nome, gruppi: gruppiEffettivi)
            context.insert(giorno)
            giorno.plan = piano

            for (ordine, voce) in ordinati.enumerated() {
                let p = voce.exercise.gruppo.parametri(per: livello, isComposto: voce.exercise.isComposto)
                let r = RecuperoCalculator.calcola(per: voce.exercise, livello: livello)
                let item = ExerciseInPlan(ordine: ordine,
                                          serie: p.serie,
                                          reps: p.reps,
                                          recuperoSecondi: r.traSerie,
                                          recuperoCambioSecondi: r.cambioEsercizio)
                context.insert(item)
                item.exercise = voce.exercise
                item.day = giorno
            }
        }

        try? context.save()
        return piano
    }

    // MARK: Regole

    /// Split in base ai giorni disponibili
    static func struttura(giorni: Int, focus: [GruppoMuscolare]) -> [GiornoTemplate] {
        switch giorni {
        case ...2:
            return [
                GiornoTemplate(nome: "Full Body A", gruppi: [.gambe, .petto, .schiena, .core]),
                GiornoTemplate(nome: "Full Body B", gruppi: [.glutei, .spalle, .schiena, .bicipiti, .tricipiti])
            ]
        case 3:
            return [
                GiornoTemplate(nome: "Push · Petto, Spalle, Tricipiti", gruppi: [.petto, .spalle, .tricipiti]),
                GiornoTemplate(nome: "Pull · Schiena, Bicipiti, Core", gruppi: [.schiena, .bicipiti, .core]),
                GiornoTemplate(nome: "Legs · Gambe, Glutei, Core", gruppi: [.gambe, .glutei, .core])
            ]
        case 4:
            return [
                GiornoTemplate(nome: "Petto + Tricipiti", gruppi: [.petto, .tricipiti]),
                GiornoTemplate(nome: "Schiena + Bicipiti", gruppi: [.schiena, .bicipiti]),
                GiornoTemplate(nome: "Gambe + Glutei", gruppi: [.gambe, .glutei]),
                GiornoTemplate(nome: "Spalle + Core", gruppi: [.spalle, .core])
            ]
        default:
            // 5 giorni: il quinto giorno è dedicato ai muscoli in focus.
            // Se l'utente ne sceglie tanti, il giorno extra ne prende al massimo 4
            // (prima i gruppi grandi), altrimenti ogni gruppo avrebbe un solo esercizio.
            let gruppiFocus = Array(focus.sorted { a, b in
                if a.isGrande != b.isGrande { return a.isGrande }
                return (GruppoMuscolare.allCases.firstIndex(of: a) ?? 0) < (GruppoMuscolare.allCases.firstIndex(of: b) ?? 0)
            }.prefix(4))
            let tuttiSelezionati = focus.count == GruppoMuscolare.allCases.count
            let quinto: GiornoTemplate = (gruppiFocus.isEmpty || tuttiSelezionati)
                ? GiornoTemplate(nome: "Spalle + Braccia", gruppi: [.spalle, .bicipiti, .tricipiti])
                : GiornoTemplate(nome: "Focus · " + gruppiFocus.map(\.rawValue).joined(separator: " + "), gruppi: gruppiFocus)
            return [
                GiornoTemplate(nome: "Petto + Tricipiti", gruppi: [.petto, .tricipiti]),
                GiornoTemplate(nome: "Schiena + Bicipiti", gruppi: [.schiena, .bicipiti]),
                GiornoTemplate(nome: "Gambe + Glutei", gruppi: [.gambe, .glutei]),
                GiornoTemplate(nome: "Spalle + Core", gruppi: [.spalle, .core]),
                quinto
            ]
        }
    }

    /// Quanti esercizi entrano nella durata scelta (5 min di riscaldamento esclusi)
    static func eserciziPerGiorno(durataMinuti: Int, livello: LivelloEsperienza) -> Int {
        let serieMedia = Double(3 + livello.serieDelta)
        let minutiPerEsercizio = serieMedia * (45.0 + 75.0) / 60.0 + 1.5
        let n = Int(Double(max(0, durataMinuti - 5)) / minutiPerEsercizio)
        return min(8, max(3, n))
    }

    /// Distribuisce gli slot tra i gruppi del giorno: i gruppi in focus e quelli grandi hanno la priorità
    static func ripartisci(gruppi: [GruppoMuscolare], focus: [GruppoMuscolare], slot: Int) -> [GruppoMuscolare: Int] {
        let ordinati = gruppi.enumerated().sorted { a, b in
            let fa = focus.contains(a.element)
            let fb = focus.contains(b.element)
            if fa != fb { return fa }
            if a.element.isGrande != b.element.isGrande { return a.element.isGrande }
            return a.offset < b.offset
        }.map { $0.element }

        var conteggi: [GruppoMuscolare: Int] = [:]
        var rimanenti = slot

        for g in ordinati where rimanenti > 0 {
            conteggi[g] = 1
            rimanenti -= 1
        }

        // I gruppi in focus compaiono due volte nel giro => ricevono più volume
        let giro = ordinati + ordinati.filter { focus.contains($0) }
        var i = 0
        var tentativi = 0
        while rimanenti > 0 && tentativi < 200 && !giro.isEmpty {
            let g = giro[i % giro.count]
            if conteggi[g, default: 0] < g.maxEserciziPerGiorno {
                conteggi[g, default: 0] += 1
                rimanenti -= 1
            }
            i += 1
            tentativi += 1
        }
        return conteggi
    }

    /// Sceglie gli esercizi di un gruppo evitando ripetizioni nella settimana (se possibile)
    static func seleziona(gruppo: GruppoMuscolare,
                          quanti: Int,
                          catalogo: [Exercise],
                          livello: LivelloEsperienza,
                          usati: inout Set<String>) -> [Exercise] {
        let candidati = catalogo
            .filter { $0.gruppo == gruppo }
            .sorted { a, b in
                if a.isComposto != b.isComposto { return a.isComposto }
                if a.livelloMinimo.rank != b.livelloMinimo.rank { return a.livelloMinimo.rank > b.livelloMinimo.rank }
                return a.nome < b.nome
            }
        let adatti = candidati.filter { $0.livelloMinimo.rank <= livello.rank }
        let pool = adatti.isEmpty ? candidati : adatti

        var scelti: [Exercise] = []
        for e in pool where !usati.contains(e.nome) && scelti.count < quanti {
            scelti.append(e)
            usati.insert(e.nome)
        }
        // Se il catalogo è troppo piccolo si riutilizzano esercizi già scelti
        if scelti.count < quanti {
            for e in pool where scelti.count < quanti && !scelti.contains(where: { $0.nome == e.nome }) {
                scelti.append(e)
            }
        }
        return scelti
    }
}
