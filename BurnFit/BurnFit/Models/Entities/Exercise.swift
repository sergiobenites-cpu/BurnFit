import Foundation
import SwiftData

// MARK: - Exercise (catalogo)

@Model
final class Exercise {
    @Attribute(.unique) var nome: String
    var gruppoRaw: String
    var attrezzatura: String
    var isComposto: Bool
    var livelloMinimoRaw: String
    /// Nome inglese usato per trovare l'immagine nell'API esercizi (free-exercise-db)
    var nomeAPI: String = ""
    /// Recupero "di riferimento" tra le serie per un intermedio, specifico dell'esercizio
    var recuperoBaseSecondi: Int = 0

    init(nome: String,
         gruppo: GruppoMuscolare,
         attrezzatura: String,
         isComposto: Bool,
         livelloMinimo: LivelloEsperienza = .principiante,
         nomeAPI: String = "",
         recuperoBaseSecondi: Int = 0) {
        self.nome = nome
        self.gruppoRaw = gruppo.rawValue
        self.attrezzatura = attrezzatura
        self.isComposto = isComposto
        self.livelloMinimoRaw = livelloMinimo.rawValue
        self.nomeAPI = nomeAPI
        self.recuperoBaseSecondi = recuperoBaseSecondi
    }

    var gruppo: GruppoMuscolare {
        get { GruppoMuscolare(rawValue: gruppoRaw) ?? .core }
        set { gruppoRaw = newValue.rawValue }
    }

    var livelloMinimo: LivelloEsperienza {
        get { LivelloEsperienza(rawValue: livelloMinimoRaw) ?? .principiante }
        set { livelloMinimoRaw = newValue.rawValue }
    }
}


