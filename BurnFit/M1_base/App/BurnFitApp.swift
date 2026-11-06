import SwiftUI
import SwiftData

@main
struct BurnFitApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for:
                UserProfile.self,
                Exercise.self,
                WorkoutPlan.self,
                WorkoutDay.self,
                ExerciseInPlan.self,
                SessionSummary.self
            )
        } catch {
            fatalError("Impossibile creare il ModelContainer: \(error)")
        }
        SampleData.popolaSeNecessario(context: ModelContext(container))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
