import SwiftUI
import SwiftData

@main
struct BurnFitApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for:
                UserAccount.self,
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
        // Inserisce / aggiorna il catalogo (recuperi per esercizio, nomi per l'API immagini)
        SampleData.popolaSeNecessario(context: ModelContext(container))

        // Cache più capiente per le immagini degli esercizi scaricate dall'API
        URLCache.shared = URLCache(memoryCapacity: 20 * 1024 * 1024,
                                   diskCapacity: 150 * 1024 * 1024)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
