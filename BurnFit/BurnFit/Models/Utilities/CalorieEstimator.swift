import Foundation

enum CalorieEstimator {
    /// Stima semplice: MET 5.0 (allenamento con i pesi, intensità moderata)
    static func stima(durataSecondi: Int, pesoKg: Double) -> Int {
        let ore = Double(max(0, durataSecondi)) / 3600.0
        return Int((5.0 * pesoKg * ore).rounded())
    }
}

