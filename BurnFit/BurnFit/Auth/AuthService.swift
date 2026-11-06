import Foundation
import SwiftData
import CryptoKit

/// Login / registrazione LOCALI (gli account vivono nel database SwiftData del dispositivo).
/// La password non viene mai salvata in chiaro: si salva SHA-256(salt + password).
///
/// Nota: per un'app reale andrebbe sostituito con un backend (es. Firebase Auth o Sign in with Apple)
/// e la sessione andrebbe salvata nel Keychain.
enum AuthService {

    enum Errore: LocalizedError {
        case nomeVuoto
        case emailNonValida
        case passwordCorta
        case passwordDiverse
        case emailGiaRegistrata
        case credenzialiErrate

        var errorDescription: String? {
            switch self {
            case .nomeVuoto: return "Inserisci il tuo nome."
            case .emailNonValida: return "Inserisci un indirizzo email valido."
            case .passwordCorta: return "La password deve avere almeno \(AuthService.lunghezzaMinima) caratteri."
            case .passwordDiverse: return "Le due password non coincidono."
            case .emailGiaRegistrata: return "Esiste già un account con questa email. Prova ad accedere."
            case .credenzialiErrate: return "Email o password non corretti."
            }
        }
    }

    static let lunghezzaMinima = 6

    // MARK: - API

    @discardableResult
    static func registra(nome: String,
                         email: String,
                         password: String,
                         conferma: String,
                         context: ModelContext) throws -> UserAccount {
        let nomePulito = nome.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailPulita = normalizza(email)

        guard !nomePulito.isEmpty else { throw Errore.nomeVuoto }
        guard emailValida(emailPulita) else { throw Errore.emailNonValida }
        guard password.count >= lunghezzaMinima else { throw Errore.passwordCorta }
        guard password == conferma else { throw Errore.passwordDiverse }
        guard trova(email: emailPulita, context: context) == nil else { throw Errore.emailGiaRegistrata }

        let salt = UUID().uuidString
        let account = UserAccount(email: emailPulita,
                                  nome: nomePulito,
                                  passwordHash: hash(password, salt: salt),
                                  salt: salt)
        context.insert(account)
        try context.save()
        return account
    }

    static func accedi(email: String, password: String, context: ModelContext) throws -> UserAccount {
        let emailPulita = normalizza(email)
        guard emailValida(emailPulita) else { throw Errore.emailNonValida }
        guard let account = trova(email: emailPulita, context: context),
              account.passwordHash == hash(password, salt: account.salt) else {
            throw Errore.credenzialiErrate
        }
        return account
    }

    static func trova(email: String, context: ModelContext) -> UserAccount? {
        let e = normalizza(email)
        var descrittore = FetchDescriptor<UserAccount>(predicate: #Predicate<UserAccount> { $0.email == e })
        descrittore.fetchLimit = 1
        return try? context.fetch(descrittore).first
    }

    // MARK: - Utility

    static func normalizza(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func emailValida(_ email: String) -> Bool {
        email.range(of: #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#,
                    options: .regularExpression) != nil
    }

    static func hash(_ password: String, salt: String) -> String {
        let dati = Data((salt + password).utf8)
        return SHA256.hash(data: dati).map { String(format: "%02x", $0) }.joined()
    }
}
