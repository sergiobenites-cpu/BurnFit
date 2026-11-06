import SwiftUI
import SwiftData

/// Prima schermata dell'app: accesso o registrazione.
/// Quando l'utente entra, salva la sua email in `@AppStorage("utenteCorrente")`
/// e `RootView` passa da sola all'onboarding (se non ha una scheda) o alla Home.
struct AuthView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("utenteCorrente") private var utenteCorrente = ""

    enum Modalita: String, CaseIterable, Identifiable {
        case accedi = "Accedi"
        case registrati = "Registrati"
        var id: String { rawValue }
    }

    private enum Campo: Hashable { case nome, email, password, conferma }

    @State private var modalita: Modalita = .accedi
    @State private var nome = ""
    @State private var email = ""
    @State private var password = ""
    @State private var conferma = ""
    @State private var mostraPassword = false
    @State private var errore: String?
    @FocusState private var campoAttivo: Campo?

    private var isRegistrazione: Bool { modalita == .registrati }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                logo
                    .padding(.top, 40)

                Picker("Modalità", selection: $modalita) {
                    ForEach(Modalita.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                VStack(spacing: 14) {
                    if isRegistrazione {
                        campo("person.fill") {
                            TextField("Nome", text: $nome)
                                .textContentType(.givenName)
                                .focused($campoAttivo, equals: .nome)
                                .submitLabel(.next)
                                .onSubmit { campoAttivo = .email }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    campo("envelope.fill") {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($campoAttivo, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { campoAttivo = .password }
                    }

                    campo("lock.fill") {
                        HStack {
                            campoPassword("Password", testo: $password)
                                .focused($campoAttivo, equals: .password)
                                .submitLabel(isRegistrazione ? .next : .go)
                                .onSubmit {
                                    if isRegistrazione { campoAttivo = .conferma } else { invia() }
                                }
                            Button { mostraPassword.toggle() } label: {
                                Image(systemName: mostraPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(mostraPassword ? "Nascondi password" : "Mostra password")
                        }
                    }

                    if isRegistrazione {
                        campo("lock.rotation") {
                            campoPassword("Conferma password", testo: $conferma)
                                .focused($campoAttivo, equals: .conferma)
                                .submitLabel(.go)
                                .onSubmit { invia() }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))

                        Text("Almeno \(AuthService.lunghezzaMinima) caratteri.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if let errore {
                    Label(errore, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity)
                }

                Button(action: invia) {
                    Text(isRegistrazione ? "Crea account" : "Accedi")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation { modalita = isRegistrazione ? .accedi : .registrati }
                } label: {
                    Text(LocalizedStringKey(isRegistrazione
                                            ? "Hai già un account? **Accedi**"
                                            : "Non hai un account? **Registrati**"))
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .animation(.easeInOut(duration: 0.2), value: modalita)
            .animation(.easeInOut(duration: 0.2), value: errore)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
        .onChange(of: modalita) { _, _ in
            errore = nil
            conferma = ""
        }
    }

    // MARK: - Componenti

    private var logo: some View {
        VStack(spacing: 10) {
            Image(systemName: "flame.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
                .frame(width: 100, height: 100)
                .background(Color.orange.opacity(0.15), in: Circle())
            Text("BurnFit").font(.largeTitle.bold())
            Text(isRegistrazione ? "Crea il tuo account per iniziare" : "Bentornato! Accedi per continuare")
                .foregroundStyle(.secondary)
        }
    }

    private func campo<Content: View>(_ icona: String, @ViewBuilder contenuto: () -> Content) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icona)
                .foregroundStyle(.orange)
                .frame(width: 22)
            contenuto()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func campoPassword(_ titolo: String, testo: Binding<String>) -> some View {
        if mostraPassword {
            TextField(titolo, text: testo)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        } else {
            SecureField(titolo, text: testo)
        }
    }

    // MARK: - Azioni

    private func invia() {
        campoAttivo = nil
        do {
            let account: UserAccount
            if isRegistrazione {
                account = try AuthService.registra(nome: nome, email: email,
                                                   password: password, conferma: conferma,
                                                   context: context)
            } else {
                account = try AuthService.accedi(email: email, password: password, context: context)
            }
            errore = nil
            password = ""
            conferma = ""
            utenteCorrente = account.email   // RootView cambia schermata
        } catch {
            errore = error.localizedDescription
        }
    }
}

#Preview {
    AuthView()
        .modelContainer(for: UserAccount.self, inMemory: true)
}
