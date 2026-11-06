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

