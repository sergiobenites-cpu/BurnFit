import Foundation
import SwiftData

/// Popola il database locale con il catalogo esercizi (eseguito una sola volta).
enum SampleData {

    private struct Seed {
        let nome: String
        let gruppo: GruppoMuscolare
        let attrezzatura: String
        let composto: Bool
        let livello: LivelloEsperienza
    }

    private static func s(_ nome: String, _ g: GruppoMuscolare, _ att: String,
                          composto: Bool, _ liv: LivelloEsperienza = .principiante) -> Seed {
        Seed(nome: nome, gruppo: g, attrezzatura: att, composto: composto, livello: liv)
    }

    private static let catalogo: [Seed] = [
        // Petto
        s("Panca piana con bilanciere", .petto, "Bilanciere", composto: true, .intermedio),
        s("Panca inclinata con manubri", .petto, "Manubri", composto: true),
        s("Chest press", .petto, "Macchina", composto: true),
        s("Push-up", .petto, "Corpo libero", composto: true),
        s("Dip alle parallele", .petto, "Corpo libero", composto: true, .avanzato),
        s("Croci ai cavi", .petto, "Cavi", composto: false, .intermedio),
        s("Pec deck", .petto, "Macchina", composto: false),
        // Schiena
        s("Lat machine", .schiena, "Cavi", composto: true),
        s("Rematore con manubrio", .schiena, "Manubri", composto: true),
        s("Pulley basso", .schiena, "Cavi", composto: true),
        s("Rematore con bilanciere", .schiena, "Bilanciere", composto: true, .intermedio),
        s("Trazioni alla sbarra", .schiena, "Corpo libero", composto: true, .avanzato),
        s("Stacco da terra", .schiena, "Bilanciere", composto: true, .avanzato),
        s("Pulldown a braccia tese", .schiena, "Cavi", composto: false, .intermedio),
        // Spalle
        s("Military press con manubri", .spalle, "Manubri", composto: true),
        s("Shoulder press", .spalle, "Macchina", composto: true),
        s("Lento avanti con bilanciere", .spalle, "Bilanciere", composto: true, .avanzato),
        s("Alzate laterali", .spalle, "Manubri", composto: false),
        s("Alzate posteriori", .spalle, "Manubri", composto: false),
        s("Face pull", .spalle, "Cavi", composto: false, .intermedio),
        // Bicipiti
        s("Curl con manubri", .bicipiti, "Manubri", composto: false),
        s("Curl con bilanciere EZ", .bicipiti, "Bilanciere", composto: false),
        s("Curl a martello", .bicipiti, "Manubri", composto: false),
        s("Curl ai cavi", .bicipiti, "Cavi", composto: false, .intermedio),
        s("Curl alla panca Scott", .bicipiti, "Bilanciere", composto: false, .intermedio),
        // Tricipiti
        s("Pushdown ai cavi", .tricipiti, "Cavi", composto: false),
        s("Estensioni sopra la testa", .tricipiti, "Manubri", composto: false),
        s("Dip su panca", .tricipiti, "Corpo libero", composto: false),
        s("Kickback con manubrio", .tricipiti, "Manubri", composto: false),
        s("French press", .tricipiti, "Bilanciere", composto: false, .intermedio),
        // Gambe
        s("Squat con bilanciere", .gambe, "Bilanciere", composto: true, .intermedio),
        s("Leg press", .gambe, "Macchina", composto: true),
        s("Goblet squat", .gambe, "Manubri", composto: true),
        s("Affondi con manubri", .gambe, "Manubri", composto: true),
        s("Squat bulgaro", .gambe, "Manubri", composto: true, .avanzato),
        s("Leg extension", .gambe, "Macchina", composto: false),
        s("Leg curl", .gambe, "Macchina", composto: false),
        s("Calf raise", .gambe, "Macchina", composto: false),
        // Glutei
        s("Hip thrust", .glutei, "Bilanciere", composto: true, .intermedio),
        s("Glute bridge", .glutei, "Corpo libero", composto: true),
        s("Stacco rumeno con manubri", .glutei, "Manubri", composto: true, .intermedio),
        s("Step-up", .glutei, "Manubri", composto: true),
        s("Kickback ai cavi", .glutei, "Cavi", composto: false),
        s("Abduzioni alla macchina", .glutei, "Macchina", composto: false),
        // Core
        s("Plank", .core, "Corpo libero", composto: false),
        s("Crunch", .core, "Corpo libero", composto: false),
        s("Russian twist", .core, "Corpo libero", composto: false),
        s("Mountain climber", .core, "Corpo libero", composto: false),
        s("Leg raise alla sbarra", .core, "Corpo libero", composto: false, .intermedio),
        s("Crunch ai cavi", .core, "Cavi", composto: false, .intermedio),
        s("Ab wheel", .core, "Ruota addominale", composto: false, .avanzato)
    ]

    /// Inserisce il catalogo solo se il database è vuoto (idempotente).
    static func popolaSeNecessario(context: ModelContext) {
        let esistenti = (try? context.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        guard esistenti == 0 else { return }
        for seed in catalogo {
            context.insert(Exercise(nome: seed.nome,
                                    gruppo: seed.gruppo,
                                    attrezzatura: seed.attrezzatura,
                                    isComposto: seed.composto,
                                    livelloMinimo: seed.livello))
        }
        try? context.save()
    }
}
