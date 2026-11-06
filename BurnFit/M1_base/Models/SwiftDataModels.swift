import Foundation
import SwiftData

// MARK: - UserProfile

@Model
final class UserProfile {
    var giorniSettimana: Int
    var gruppiFocusRaw: [String]
    var livelloRaw: String
    var durataMinuti: Int
    var pesoKg: Double
    var createdAt: Date

    init(giorniSettimana: Int,
         gruppiFocus: [GruppoMuscolare],
         livello: LivelloEsperienza,
         durataMinuti: Int,
         pesoKg: Double = 70,
         createdAt: Date = .now) {
        self.giorniSettimana = giorniSettimana
        self.gruppiFocusRaw = gruppiFocus.map(\.rawValue)
        self.livelloRaw = livello.rawValue
        self.durataMinuti = durataMinuti
        self.pesoKg = pesoKg
        self.createdAt = createdAt
    }

    var gruppiFocus: [GruppoMuscolare] {
        get { gruppiFocusRaw.compactMap { GruppoMuscolare(rawValue: $0) } }
        set { gruppiFocusRaw = newValue.map(\.rawValue) }
    }

    var livello: LivelloEsperienza {
        get { LivelloEsperienza(rawValue: livelloRaw) ?? .principiante }
        set { livelloRaw = newValue.rawValue }
    }
}

// MARK: - Exercise (catalogo)

@Model
final class Exercise {
    @Attribute(.unique) var nome: String
    var gruppoRaw: String
    var attrezzatura: String
    var isComposto: Bool
    var livelloMinimoRaw: String

    init(nome: String,
         gruppo: GruppoMuscolare,
         attrezzatura: String,
         isComposto: Bool,
         livelloMinimo: LivelloEsperienza = .principiante) {
        self.nome = nome
        self.gruppoRaw = gruppo.rawValue
        self.attrezzatura = attrezzatura
        self.isComposto = isComposto
        self.livelloMinimoRaw = livelloMinimo.rawValue
    }

    var gruppo: GruppoMuscolare {
        get { GruppoMuscolare(rawValue: gruppoRaw) ?? .core }
        set { gruppoRaw = newValue.rawValue }
    }

    var livelloMinimo: LivelloEsperienza {
        get { LivelloEsperienza(rawValue: livelloMinimoRaw) ?? .principiante }
        set { livelloMinimoRaw = newValue.rawValue }
    }
}

// MARK: - WorkoutPlan

@Model
final class WorkoutPlan {
    var createdAt: Date
    var giorniSettimana: Int

    @Relationship(deleteRule: .cascade, inverse: \WorkoutDay.plan)
    var giorni: [WorkoutDay] = []

    init(giorniSettimana: Int, createdAt: Date = .now) {
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

    /// Durata stimata in minuti (esecuzione 45s a serie + recuperi)
    var durataStimataMinuti: Int {
        let secondi = esercizi.reduce(0) { $0 + $1.serie * (45 + $1.recuperoSecondi) }
        return max(1, Int((Double(secondi) / 60.0).rounded()))
    }
}

// MARK: - ExerciseInPlan

@Model
final class ExerciseInPlan {
    var ordine: Int
    var serie: Int
    var reps: Int
    var recuperoSecondi: Int
    var completato: Bool
    /// Serie già svolte (0...serie): serve per il recupero tra le singole serie
    var serieCompletate: Int = 0
    var exercise: Exercise?
    var day: WorkoutDay?

    init(ordine: Int, serie: Int, reps: Int, recuperoSecondi: Int) {
        self.ordine = ordine
        self.serie = serie
        self.reps = reps
        self.recuperoSecondi = recuperoSecondi
        self.completato = false
        self.serieCompletate = 0
    }
}

// MARK: - SessionSummary

@Model
final class SessionSummary {
    var dataFine: Date
    var inizio: Date
    var durataSecondi: Int
    var calorie: Int
    var nomeGiorno: String
    var eserciziCompletati: Int
    var eserciziTotali: Int
    var serieCompletate: Int
    var distribuzioneKeys: [String]
    var distribuzioneValori: [Int]

    init(dataFine: Date = .now,
         inizio: Date,
         durataSecondi: Int,
         calorie: Int,
         nomeGiorno: String,
         eserciziCompletati: Int,
         eserciziTotali: Int,
         serieCompletate: Int,
         distribuzione: [GruppoMuscolare: Int]) {
        self.dataFine = dataFine
        self.inizio = inizio
        self.durataSecondi = durataSecondi
        self.calorie = calorie
        self.nomeGiorno = nomeGiorno
        self.eserciziCompletati = eserciziCompletati
        self.eserciziTotali = eserciziTotali
        self.serieCompletate = serieCompletate
        let ordinati = GruppoMuscolare.allCases.filter { (distribuzione[$0] ?? 0) > 0 }
        self.distribuzioneKeys = ordinati.map(\.rawValue)
        self.distribuzioneValori = ordinati.map { distribuzione[$0] ?? 0 }
    }

    /// Serie svolte per gruppo muscolare in questa sessione
    var distribuzione: [MuscoloQuota] {
        zip(distribuzioneKeys, distribuzioneValori).compactMap { chiave, valore in
            guard let g = GruppoMuscolare(rawValue: chiave) else { return nil }
            return MuscoloQuota(gruppo: g, valore: valore)
        }
    }
}

extension MuscoloQuota {
    /// Somma la ripartizione muscolare di più sessioni (per il grafico globale in Progressi)
    static func aggrega(_ sessioni: [SessionSummary]) -> [MuscoloQuota] {
        var totali: [GruppoMuscolare: Int] = [:]
        for s in sessioni {
            for q in s.distribuzione { totali[q.gruppo, default: 0] += q.valore }
        }
        return GruppoMuscolare.allCases.compactMap { g in
            guard let v = totali[g], v > 0 else { return nil }
            return MuscoloQuota(gruppo: g, valore: v)
        }
    }
}
