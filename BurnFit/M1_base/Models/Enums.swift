import SwiftUI

// MARK: - Livello di esperienza

enum LivelloEsperienza: String, Codable, CaseIterable, Identifiable {
    case principiante = "Principiante"
    case intermedio = "Intermedio"
    case avanzato = "Avanzato"

    var id: String { rawValue }

    /// Ordine crescente di difficoltà (0...2)
    var rank: Int {
        switch self {
        case .principiante: return 0
        case .intermedio: return 1
        case .avanzato: return 2
        }
    }

    /// Variazione delle serie rispetto al default del gruppo muscolare
    var serieDelta: Int {
        switch self {
        case .principiante: return -1
        case .intermedio: return 0
        case .avanzato: return 1
        }
    }

    /// Variazione delle ripetizioni (principianti: più reps e carichi leggeri; avanzati: meno reps e più carico)
    var repsDelta: Int {
        switch self {
        case .principiante: return 2
        case .intermedio: return 0
        case .avanzato: return -2
        }
    }

    var descrizione: String {
        switch self {
        case .principiante: return "Meno di 6 mesi di allenamento"
        case .intermedio: return "Da 6 mesi a 2 anni di allenamento"
        case .avanzato: return "Oltre 2 anni di allenamento costante"
        }
    }

    var icona: String {
        switch self {
        case .principiante: return "leaf.fill"
        case .intermedio: return "bolt.fill"
        case .avanzato: return "flame.fill"
        }
    }
}

// MARK: - Gruppo muscolare

enum GruppoMuscolare: String, Codable, CaseIterable, Identifiable {
    case petto = "Petto"
    case schiena = "Schiena"
    case spalle = "Spalle"
    case bicipiti = "Bicipiti"
    case tricipiti = "Tricipiti"
    case gambe = "Gambe"
    case glutei = "Glutei"
    case core = "Core"

    var id: String { rawValue }

    // Parametri di default
    var serieDefault: Int {
        switch self {
        case .petto, .schiena, .gambe: return 4
        case .glutei, .spalle, .bicipiti, .tricipiti, .core: return 3
        }
    }

    var repsDefault: Int {
        switch self {
        case .petto, .schiena, .gambe: return 10
        case .glutei, .spalle, .bicipiti, .tricipiti: return 12
        case .core: return 15
        }
    }

    /// Recupero di default in secondi
    var recuperoDefault: Int {
        switch self {
        case .gambe: return 120
        case .petto, .schiena, .glutei: return 90
        case .spalle: return 75
        case .bicipiti, .tricipiti: return 60
        case .core: return 45
        }
    }

    /// Gruppi "grandi" hanno priorità nella scheda e più esercizi massimi per sessione
    var isGrande: Bool {
        switch self {
        case .petto, .schiena, .gambe, .glutei: return true
        case .spalle, .bicipiti, .tricipiti, .core: return false
        }
    }

    var maxEserciziPerGiorno: Int { isGrande ? 5 : 4 }

    var icona: String {
        switch self {
        case .petto: return "figure.strengthtraining.traditional"
        case .schiena: return "figure.rower"
        case .spalle: return "figure.arms.open"
        case .bicipiti: return "dumbbell.fill"
        case .tricipiti: return "figure.strengthtraining.functional"
        case .gambe: return "figure.run"
        case .glutei: return "figure.step.training"
        case .core: return "figure.core.training"
        }
    }

    var colore: Color {
        switch self {
        case .petto: return .red
        case .schiena: return .blue
        case .spalle: return .orange
        case .bicipiti: return .purple
        case .tricipiti: return .pink
        case .gambe: return .green
        case .glutei: return .teal
        case .core: return .yellow
        }
    }

    /// Serie / ripetizioni / recupero finali per livello e tipo di esercizio
    func parametri(per livello: LivelloEsperienza, isComposto: Bool) -> (serie: Int, reps: Int, recupero: Int) {
        let serie = min(5, max(2, serieDefault + livello.serieDelta))
        let reps = min(20, max(6, repsDefault + livello.repsDelta))
        let recupero = recuperoDefault + (isComposto ? 15 : 0)
        return (serie, reps, recupero)
    }
}

// MARK: - Tipo condiviso per i grafici (usato da Membro 4)

struct MuscoloQuota: Identifiable, Hashable {
    let gruppo: GruppoMuscolare
    let valore: Int
    var id: String { gruppo.rawValue }
}

// MARK: - Utility condivise

enum CalorieEstimator {
    /// Stima semplice: MET 5.0 (allenamento con i pesi, intensità moderata)
    static func stima(durataSecondi: Int, pesoKg: Double) -> Int {
        let ore = Double(max(0, durataSecondi)) / 3600.0
        return Int((5.0 * pesoKg * ore).rounded())
    }
}

extension Int {
    /// 75 -> "01:15"
    var mmss: String {
        let s = Swift.max(0, self)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    /// 45 -> "45 s", 1500 -> "25 min", 3725 -> "1h 02m"
    var durataBreve: String {
        let s = Swift.max(0, self)
        if s < 60 { return "\(s) s" }
        let ore = s / 3600
        let minuti = (s % 3600) / 60
        if ore > 0 { return "\(ore)h \(String(format: "%02d", minuti))m" }
        return "\(minuti) min"
    }
}

extension Calendar {
    /// Calendario gregoriano italiano, settimana che parte da lunedì
    static let italiano: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "it_IT")
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        return c
    }()
}
