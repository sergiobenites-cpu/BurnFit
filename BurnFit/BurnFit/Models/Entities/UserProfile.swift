import Foundation
import SwiftData


// MARK: - UserProfile

@Model
final class UserProfile {
    /// Email dell'account a cui appartiene il profilo
    var proprietario: String = ""
    var giorniSettimana: Int
    var gruppiFocusRaw: [String]
    var livelloRaw: String
    var durataMinuti: Int
    var pesoKg: Double
    var createdAt: Date

    init(giorniSettimana: Int,
         gruppiFocus: [GruppoMuscolare],
         livello: LivelloEsperienza,
         durataMinuti: Int,
         pesoKg: Double = 70,
         proprietario: String,
         createdAt: Date = .now) {
        self.proprietario = proprietario
        self.giorniSettimana = giorniSettimana
        self.gruppiFocusRaw = gruppiFocus.map(\.rawValue)
        self.livelloRaw = livello.rawValue
        self.durataMinuti = durataMinuti
        self.pesoKg = pesoKg
        self.createdAt = createdAt
    }

    var gruppiFocus: [GruppoMuscolare] {
        get { gruppiFocusRaw.compactMap { GruppoMuscolare(rawValue: $0) } }
        set { gruppiFocusRaw = newValue.map(\.rawValue) }
    }

    var livello: LivelloEsperienza {
        get { LivelloEsperienza(rawValue: livelloRaw) ?? .principiante }
        set { livelloRaw = newValue.rawValue }
    }
}
