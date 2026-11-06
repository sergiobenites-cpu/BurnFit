import SwiftUI

/// Immagine di un esercizio presa dall'API (`ExerciseImageService`).
/// - `animata: true` alterna le due foto (posizione iniziale / finale) per mostrare il movimento.
/// - Mentre carica, o se l'immagine non c'è / manca la rete, mostra l'icona del gruppo muscolare.
struct ExerciseImageView: View {
    let exercise: Exercise?
    var animata = false

    @State private var urls: [URL] = []
    @State private var fotogramma = 0

    private var gruppo: GruppoMuscolare? { exercise?.gruppo }

    var body: some View {
        ZStack {
            if urls.isEmpty {
                segnaposto
            } else {
                Color.white   // le foto del dataset hanno sfondo bianco
                AsyncImage(url: urls[fotogramma % urls.count], transaction: Transaction(animation: .easeInOut)) { fase in
                    switch fase {
                    case .success(let img):
                        img.resizable().scaledToFit()
                    case .failure:
                        segnaposto.background(Color(.secondarySystemGroupedBackground))
                    default:
                        ProgressView().tint(.orange)
                    }
                }
            }
        }
        .task(id: exercise?.nomeAPI) {
            fotogramma = 0
            urls = await ExerciseImageService.shared.immagini(per: exercise?.nomeAPI ?? "")
        }
        .task(id: animata && urls.count > 1) {
            guard animata, urls.count > 1 else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.2))
                withAnimation(.easeInOut(duration: 0.3)) { fotogramma += 1 }
            }
        }
        .accessibilityLabel(exercise?.nome ?? "Esercizio")
    }

    private var segnaposto: some View {
        ZStack {
            (gruppo?.colore ?? .orange).opacity(0.15)
            Image(systemName: gruppo?.icona ?? "dumbbell.fill")
                .font(.title2)
                .foregroundStyle(gruppo?.colore ?? .orange)
        }
    }
}
