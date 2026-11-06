// MARK: - SessionSummary

@Model
final class SessionSummary {
    var proprietario: String = ""
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
         distribuzione: [GruppoMuscolare: Int],
         proprietario: String) {
        self.proprietario = proprietario
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
