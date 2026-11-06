import Foundation
import SwiftData
// MARK: - WorkoutPlan

@Model
final class WorkoutPlan {
    var proprietario: String = ""
    var createdAt: Date
    var giorniSettimana: Int

    @Relationship(deleteRule: .cascade, inverse: \WorkoutDay.plan)
    var giorni: [WorkoutDay] = []

    init(giorniSettimana: Int, proprietario: String, createdAt: Date = .now) {
        self.proprietario = proprietario
        self.giorniSettimana = giorniSettimana
        self.createdAt = createdAt
    }

    var giorniOrdinati: [WorkoutDay] { giorni.sorted { $0.indice < $1.indice } }
    var completati: Int { giorni.filter { $0.completato }.count }
}

// MARK: - WorkoutDay

@Model
final class WorkoutDay {
    var indice: Int
    var nome: String
    var gruppiRaw: [String]
    var completato: Bool
    var dataCompletamento: Date?
    var plan: WorkoutPlan?

    @Relationship(deleteRule: .cascade, inverse: \ExerciseInPlan.day)
    var esercizi: [ExerciseInPlan] = []

    init(indice: Int, nome: String, gruppi: [GruppoMuscolare]) {
        self.indice = indice
        self.nome = nome
        self.gruppiRaw = gruppi.map(\.rawValue)
        self.completato = false
        self.dataCompletamento = nil
    }

    var gruppi: [GruppoMuscolare] { gruppiRaw.compactMap { GruppoMuscolare(rawValue: $0) } }
    var eserciziOrdinati: [ExerciseInPlan] { esercizi.sorted { $0.ordine < $1.ordine } }

    /// Durata stimata in minuti: 45s di esecuzione a serie, recupero tra le serie
    /// e recupero di cambio esercizio (l'ultimo esercizio non ha recupero finale)
    var durataStimataMinuti: Int {
        let ordinati = eserciziOrdinati
        var secondi = 0
        for (i, e) in ordinati.enumerated() {
            secondi += e.serie * 45 + max(0, e.serie - 1) * e.recuperoSecondi
            if i < ordinati.count - 1 { secondi += e.recuperoCambioSecondi }
        }
        return max(1, Int((Double(secondi) / 60.0).rounded()))
    }
}
