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

