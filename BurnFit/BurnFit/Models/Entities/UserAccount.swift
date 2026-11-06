import Foundation
import SwiftData

// MARK: - UserAccount (login / registrazione)

@Model
final class UserAccount {
    @Attribute(.unique) var email: String
    var nome: String
    /// SHA-256 di (salt + password): la password in chiaro non viene mai salvata
    var passwordHash: String
    var salt: String
    var createdAt: Date

    init(email: String, nome: String, passwordHash: String, salt: String, createdAt: Date = .now) {
        self.email = email
        self.nome = nome
        self.passwordHash = passwordHash
        self.salt = salt
        self.createdAt = createdAt
    }
}
