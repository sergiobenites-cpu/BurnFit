import Foundation

/// Calcola i tempi di recupero di UN esercizio in base a:
/// - l'esercizio stesso (`Exercise.recuperoBaseSecondi`: uno squat pesante non recupera come un curl)
/// - il tipo (multiarticolare / isolamento)
/// - il livello dell'utente.
///
/// Logica: i multiarticolari risentono molto del livello (un avanzato usa carichi vicini al massimale
/// e ha bisogno di più recupero), gli esercizi di isolamento molto meno.
enum RecuperoCalculator {

    struct Recuperi {
        /// Tra una serie e l'altra dello stesso esercizio
        let traSerie: Int
        /// Dopo l'ultima serie, prima dell'esercizio successivo (include il cambio postazione)
        let cambioEsercizio: Int
    }

    static func calcola(per esercizio: Exercise, livello: LivelloEsperienza) -> Recuperi {
        let base = esercizio.recuperoBaseSecondi > 0
            ? esercizio.recuperoBaseSecondi
            : esercizio.gruppo.recuperoDefault + (esercizio.isComposto ? 15 : 0)

        let fattore: Double
        switch (livello, esercizio.isComposto) {
        case (.principiante, true):  fattore = 0.75
        case (.principiante, false): fattore = 0.85
        case (.intermedio, _):       fattore = 1.0
        case (.avanzato, true):      fattore = 1.25
        case (.avanzato, false):     fattore = 1.1
        }

        let traSerie = arrotonda(Double(base) * fattore, min: 30, max: 240)

        // Cambio esercizio: un po' più lungo del recupero tra le serie
        // (tempo per spostarsi, preparare carico/macchina), più ampio per chi è alle prime armi.
        let extraCambio: Double
        switch livello {
        case .principiante: extraCambio = 45
        case .intermedio:   extraCambio = 30
        case .avanzato:     extraCambio = 30
        }
        let cambio = arrotonda(Double(traSerie) * 1.2 + extraCambio, min: 60, max: 300)

        return Recuperi(traSerie: traSerie, cambioEsercizio: cambio)
    }

    /// Arrotonda a multipli di 5 secondi dentro un intervallo
    private static func arrotonda(_ valore: Double, min minimo: Int, max massimo: Int) -> Int {
        let r = Int((valore / 5).rounded()) * 5
        return Swift.min(massimo, Swift.max(minimo, r))
    }
}
