import Foundation
import SwiftData

/// Popola (e tiene aggiornato) il catalogo esercizi nel database locale.
///
/// Ogni esercizio ha:
/// - `recupero`: secondi di recupero tra le serie per un livello INTERMEDIO.
///   Il valore viene poi adattato al livello dell'utente da `RecuperoCalculator`.
/// - `api`: nome inglese dell'esercizio in free-exercise-db, usato per l'immagine.
enum SampleData {

    private struct Seed {
        let nome: String
        let gruppo: GruppoMuscolare
        let attrezzatura: String
        let composto: Bool
        let livello: LivelloEsperienza
        let recupero: Int
        let api: String
    }

    private static func s(_ nome: String, _ g: GruppoMuscolare, _ att: String,
                          composto: Bool, _ liv: LivelloEsperienza = .principiante,
                          recupero: Int, api: String) -> Seed {
        Seed(nome: nome, gruppo: g, attrezzatura: att, composto: composto,
             livello: liv, recupero: recupero, api: api)
    }

    private static let catalogo: [Seed] = [
        // Petto
        s("Panca piana con bilanciere", .petto, "Bilanciere", composto: true, .intermedio, recupero: 150, api: "Barbell Bench Press - Medium Grip"),
        s("Panca inclinata con manubri", .petto, "Manubri", composto: true, recupero: 120, api: "Incline Dumbbell Press"),
        s("Chest press", .petto, "Macchina", composto: true, recupero: 90, api: "Leverage Chest Press"),
        s("Push-up", .petto, "Corpo libero", composto: true, recupero: 75, api: "Pushups"),
        s("Dip alle parallele", .petto, "Corpo libero", composto: true, .avanzato, recupero: 120, api: "Dips - Chest Version"),
        s("Croci ai cavi", .petto, "Cavi", composto: false, .intermedio, recupero: 60, api: "Cable Crossover"),
        s("Pec deck", .petto, "Macchina", composto: false, recupero: 60, api: "Butterfly"),
        // Schiena
        s("Lat machine", .schiena, "Cavi", composto: true, recupero: 90, api: "Wide-Grip Lat Pulldown"),
        s("Rematore con manubrio", .schiena, "Manubri", composto: true, recupero: 90, api: "One-Arm Dumbbell Row"),
        s("Pulley basso", .schiena, "Cavi", composto: true, recupero: 90, api: "Seated Cable Rows"),
        s("Rematore con bilanciere", .schiena, "Bilanciere", composto: true, .intermedio, recupero: 120, api: "Bent Over Barbell Row"),
        s("Trazioni alla sbarra", .schiena, "Corpo libero", composto: true, .avanzato, recupero: 150, api: "Pullups"),
        s("Stacco da terra", .schiena, "Bilanciere", composto: true, .avanzato, recupero: 180, api: "Barbell Deadlift"),
        s("Pulldown a braccia tese", .schiena, "Cavi", composto: false, .intermedio, recupero: 60, api: "Straight-Arm Pulldown"),
        // Spalle
        s("Military press con manubri", .spalle, "Manubri", composto: true, recupero: 105, api: "Dumbbell Shoulder Press"),
        s("Shoulder press", .spalle, "Macchina", composto: true, recupero: 90, api: "Machine Shoulder (Military) Press"),
        s("Lento avanti con bilanciere", .spalle, "Bilanciere", composto: true, .avanzato, recupero: 150, api: "Standing Military Press"),
        s("Alzate laterali", .spalle, "Manubri", composto: false, recupero: 60, api: "Side Lateral Raise"),
        s("Alzate posteriori", .spalle, "Manubri", composto: false, recupero: 60, api: "Reverse Flyes"),
        s("Face pull", .spalle, "Cavi", composto: false, .intermedio, recupero: 60, api: "Face Pull"),
        // Bicipiti
        s("Curl con manubri", .bicipiti, "Manubri", composto: false, recupero: 60, api: "Dumbbell Bicep Curl"),
        s("Curl con bilanciere EZ", .bicipiti, "Bilanciere", composto: false, recupero: 75, api: "EZ-Bar Curl"),
        s("Curl a martello", .bicipiti, "Manubri", composto: false, recupero: 60, api: "Hammer Curls"),
        s("Curl ai cavi", .bicipiti, "Cavi", composto: false, .intermedio, recupero: 45, api: "Standing Biceps Cable Curl"),
        s("Curl alla panca Scott", .bicipiti, "Bilanciere", composto: false, .intermedio, recupero: 60, api: "Preacher Curl"),
        // Tricipiti
        s("Pushdown ai cavi", .tricipiti, "Cavi", composto: false, recupero: 45, api: "Triceps Pushdown"),
        s("Estensioni sopra la testa", .tricipiti, "Manubri", composto: false, recupero: 60, api: "Standing Dumbbell Triceps Extension"),
        s("Dip su panca", .tricipiti, "Corpo libero", composto: false, recupero: 60, api: "Bench Dips"),
        s("Kickback con manubrio", .tricipiti, "Manubri", composto: false, recupero: 45, api: "Tricep Dumbbell Kickback"),
        s("French press", .tricipiti, "Bilanciere", composto: false, .intermedio, recupero: 75, api: "EZ-Bar Skullcrusher"),
        // Gambe
        s("Squat con bilanciere", .gambe, "Bilanciere", composto: true, .intermedio, recupero: 180, api: "Barbell Squat"),
        s("Leg press", .gambe, "Macchina", composto: true, recupero: 120, api: "Leg Press"),
        s("Goblet squat", .gambe, "Manubri", composto: true, recupero: 90, api: "Goblet Squat"),
        s("Affondi con manubri", .gambe, "Manubri", composto: true, recupero: 90, api: "Dumbbell Lunges"),
        s("Squat bulgaro", .gambe, "Manubri", composto: true, .avanzato, recupero: 105, api: "Split Squat with Dumbbells"),
        s("Leg extension", .gambe, "Macchina", composto: false, recupero: 60, api: "Leg Extensions"),
        s("Leg curl", .gambe, "Macchina", composto: false, recupero: 60, api: "Lying Leg Curls"),
        s("Calf raise", .gambe, "Macchina", composto: false, recupero: 45, api: "Standing Calf Raises"),
        // Glutei
        s("Hip thrust", .glutei, "Bilanciere", composto: true, .intermedio, recupero: 120, api: "Barbell Hip Thrust"),
        s("Glute bridge", .glutei, "Corpo libero", composto: true, recupero: 60, api: "Butt Lift (Bridge)"),
        s("Stacco rumeno con manubri", .glutei, "Manubri", composto: true, .intermedio, recupero: 120, api: "Stiff-Legged Dumbbell Deadlift"),
        s("Step-up", .glutei, "Manubri", composto: true, recupero: 75, api: "Dumbbell Step Ups"),
        s("Kickback ai cavi", .glutei, "Cavi", composto: false, recupero: 45, api: "One-Legged Cable Kickback"),
        s("Abduzioni alla macchina", .glutei, "Macchina", composto: false, recupero: 45, api: "Thigh Abductor"),
        // Core
        s("Plank", .core, "Corpo libero", composto: false, recupero: 45, api: "Plank"),
        s("Crunch", .core, "Corpo libero", composto: false, recupero: 30, api: "Crunches"),
        s("Russian twist", .core, "Corpo libero", composto: false, recupero: 30, api: "Russian Twist"),
        s("Mountain climber", .core, "Corpo libero", composto: false, recupero: 45, api: "Mountain Climbers"),
        s("Leg raise alla sbarra", .core, "Corpo libero", composto: false, .intermedio, recupero: 60, api: "Hanging Leg Raise"),
        s("Crunch ai cavi", .core, "Cavi", composto: false, .intermedio, recupero: 45, api: "Cable Crunch"),
        s("Ab wheel", .core, "Ruota addominale", composto: false, .avanzato, recupero: 60, api: "Ab Roller")
    ]

    /// Inserisce gli esercizi mancanti e aggiorna recuperi / nomi API di quelli esistenti.
    /// È idempotente: si può chiamare a ogni avvio (serve anche come "migrazione"
    /// per i database creati con la versione precedente dell'app).
    static func popolaSeNecessario(context: ModelContext) {
        let esistenti = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let perNome = Dictionary(esistenti.map { ($0.nome, $0) }, uniquingKeysWith: { a, _ in a })

        for seed in catalogo {
            if let e = perNome[seed.nome] {
                if e.nomeAPI != seed.api { e.nomeAPI = seed.api }
                if e.recuperoBaseSecondi != seed.recupero { e.recuperoBaseSecondi = seed.recupero }
            } else {
                context.insert(Exercise(nome: seed.nome,
                                        gruppo: seed.gruppo,
                                        attrezzatura: seed.attrezzatura,
                                        isComposto: seed.composto,
                                        livelloMinimo: seed.livello,
                                        nomeAPI: seed.api,
                                        recuperoBaseSecondi: seed.recupero))
            }
        }
        try? context.save()
    }
}

