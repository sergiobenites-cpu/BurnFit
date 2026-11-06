import SwiftUI

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

    /// Serie / ripetizioni finali per livello.
    /// I recuperi sono calcolati per singolo esercizio in `RecuperoCalculator`.
    func parametri(per livello: LivelloEsperienza, isComposto: Bool) -> (serie: Int, reps: Int) {
        let serie = min(5, max(2, serieDefault + livello.serieDelta))
        let reps = min(20, max(6, repsDefault + livello.repsDelta))
        return (serie, reps)
    }
}

