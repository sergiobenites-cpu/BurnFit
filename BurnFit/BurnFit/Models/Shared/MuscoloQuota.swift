import Foundation
// MARK: - Tipo condiviso per i grafici

struct MuscoloQuota: Identifiable, Hashable {
    let gruppo: GruppoMuscolare
    let valore: Int
    var id: String { gruppo.rawValue }
}


