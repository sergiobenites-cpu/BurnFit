import Foundation
import SwiftData
// MARK: - ExerciseInPlan

@Model
final class ExerciseInPlan {
    var ordine: Int
    var serie: Int
    var reps: Int
    /// Recupero tra una serie e l'altra dello stesso esercizio
    var recuperoSecondi: Int
    /// Recupero dopo l'ultima serie, prima di passare all'esercizio successivo
    var recuperoCambioSecondi: Int = 90
    var completato: Bool
    /// Serie già svolte (0...serie): serve per il recupero tra le singole serie
    var serieCompletate: Int = 0
    var exercise: Exercise?
    var day: WorkoutDay?

    init(ordine: Int, serie: Int, reps: Int, recuperoSecondi: Int, recuperoCambioSecondi: Int) {
        self.ordine = ordine
        self.serie = serie
        self.reps = reps
        self.recuperoSecondi = recuperoSecondi
        self.recuperoCambioSecondi = recuperoCambioSecondi
        self.completato = false
        self.serieCompletate = 0
    }
}


