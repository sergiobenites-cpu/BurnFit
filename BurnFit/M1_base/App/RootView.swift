import SwiftUI
import SwiftData

/// Se non esiste una scheda mostra l'onboarding, altrimenti l'app principale.
struct RootView: View {
    @Query private var piani: [WorkoutPlan]

    var body: some View {
        if piani.isEmpty {
            OnboardingView()
        } else {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            ProgressiView()
                .tabItem { Label("Progressi", systemImage: "chart.bar.fill") }
        }
        .tint(.orange)
    }
}
