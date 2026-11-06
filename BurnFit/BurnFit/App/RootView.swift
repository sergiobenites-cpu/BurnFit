import SwiftUI
import SwiftData

/// Flusso dell'app:
/// 1. nessun utente loggato           -> AuthView (login / registrazione)
/// 2. utente senza scheda             -> OnboardingView
/// 3. utente con scheda               -> MainTabView
struct RootView: View {
    @AppStorage("utenteCorrente") private var utenteCorrente = ""

    var body: some View {
        Group {
            if utenteCorrente.isEmpty {
                AuthView()
                    .transition(.opacity)
            } else {
                ContenutoUtenteView(email: utenteCorrente)
                    .id(utenteCorrente)   // cambiando utente le @Query si ricreano
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: utenteCorrente)
    }
}

/// Mostra onboarding o app principale per l'utente indicato.
struct ContenutoUtenteView: View {
    let email: String
    @Query private var piani: [WorkoutPlan]

    init(email: String) {
        self.email = email
        _piani = Query(filter: #Predicate<WorkoutPlan> { $0.proprietario == email })
    }

    var body: some View {
        if piani.isEmpty {
            OnboardingView(email: email)
        } else {
            MainTabView(email: email)
        }
    }
}

struct MainTabView: View {
    let email: String

    var body: some View {
        TabView {
            DashboardView(email: email)
                .tabItem { Label("Home", systemImage: "house.fill") }
            ProgressiView(email: email)
                .tabItem { Label("Progressi", systemImage: "chart.bar.fill") }
        }
        .tint(.orange)
    }
}
