import Foundation

/// Recupera le immagini degli esercizi da **free-exercise-db**
/// (https://github.com/yuhonas/free-exercise-db): dataset pubblico (licenza Unlicense)
/// di 800+ esercizi con foto, servito via HTTPS da GitHub. Nessuna API key necessaria.
///
/// Funzionamento:
/// 1. scarica una volta il catalogo JSON (~1 MB) e lo salva nella cartella Caches
///    (viene riscaricato dopo 30 giorni; se manca la rete si usa la copia salvata);
/// 2. cerca l'esercizio per nome inglese (`Exercise.nomeAPI`), con un confronto "fuzzy"
///    così piccole differenze di nome non rompono il collegamento;
/// 3. restituisce gli URL delle foto (di solito 2: posizione iniziale e finale).
/// Se qualcosa va storto restituisce un array vuoto e la UI mostra l'icona SF Symbol del gruppo.
actor ExerciseImageService {
    static let shared = ExerciseImageService()

    struct Voce: Decodable, Sendable {
        let id: String
        let name: String
        let images: [String]
    }

    private let catalogoURL = URL(string: "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json")!
    private let baseImmagini = URL(string: "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/")!
    private let validitaCache: TimeInterval = 30 * 24 * 3600

    private var catalogo: [Voce]?
    private var caricamento: Task<[Voce], Never>?
    private var risolti: [String: [URL]] = [:]

    // MARK: - API pubblica

    /// URL delle immagini per il nome inglese dell'esercizio (vuoto se non trovato / offline)
    func immagini(per nomeInglese: String) async -> [URL] {
        let chiave = nomeInglese.trimmingCharacters(in: .whitespaces)
        guard !chiave.isEmpty else { return [] }
        if let r = risolti[chiave] { return r }

        let voci = await caricaCatalogo()
        guard let voce = Self.migliorCorrispondenza(per: chiave, in: voci) else { return [] }

        let urls = voce.images.compactMap { URL(string: $0, relativeTo: baseImmagini)?.absoluteURL }
        risolti[chiave] = urls
        return urls
    }

    // MARK: - Catalogo

    private func caricaCatalogo() async -> [Voce] {
        if let catalogo { return catalogo }
        if let caricamento { return await caricamento.value }

        let task = Task { await Self.scaricaOCache(url: catalogoURL, validita: validitaCache) }
        caricamento = task
        let voci = await task.value
        caricamento = nil
        // Se il download fallisce (offline) non memorizziamo il vuoto: si riprova alla prossima richiesta
        if !voci.isEmpty { catalogo = voci }
        return voci
    }

    private static var fileCache: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("free-exercise-db.json")
    }

    private static func scaricaOCache(url: URL, validita: TimeInterval) async -> [Voce] {
        let decoder = JSONDecoder()
        var datiSalvati: Data?

        if let file = fileCache,
           let attributi = try? FileManager.default.attributesOfItem(atPath: file.path),
           let data = try? Data(contentsOf: file) {
            datiSalvati = data
            let modifica = attributi[.modificationDate] as? Date ?? .distantPast
            if Date.now.timeIntervalSince(modifica) < validita,
               let voci = try? decoder.decode([Voce].self, from: data) {
                return voci
            }
        }

        do {
            let (data, risposta) = try await URLSession.shared.data(from: url)
            if let http = risposta as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }
            let voci = try decoder.decode([Voce].self, from: data)
            if let file = fileCache { try? data.write(to: file, options: .atomic) }
            return voci
        } catch {
            // Offline: meglio una copia vecchia che niente
            if let datiSalvati, let voci = try? decoder.decode([Voce].self, from: datiSalvati) {
                return voci
            }
            return []
        }
    }

    // MARK: - Ricerca per nome

    private static let paroleVuote: Set<String> = ["with", "the", "a", "on", "and", "version"]

    private static func parole(_ testo: String) -> Set<String> {
        let pulito = testo.lowercased().map { $0.isLetter || $0.isNumber ? $0 : " " }
        return Set(String(pulito).split(separator: " ").map(String.init)).subtracting(paroleVuote)
    }

    /// Prima cerca il nome identico, poi l'esercizio con più parole in comune (indice di Jaccard).
    static func migliorCorrispondenza(per nome: String, in voci: [Voce]) -> Voce? {
        let cercato = nome.lowercased()
        if let esatta = voci.first(where: { $0.name.lowercased() == cercato && !$0.images.isEmpty }) {
            return esatta
        }

        let q = parole(nome)
        guard !q.isEmpty else { return nil }

        var migliore: (voce: Voce, punteggio: Double)?
        for v in voci where !v.images.isEmpty {
            let n = parole(v.name)
            let comuni = q.intersection(n).count
            guard comuni > 0 else { continue }
            let punteggio = Double(comuni) / Double(q.union(n).count)
            if punteggio > (migliore?.punteggio ?? 0) {
                migliore = (v, punteggio)
            }
        }
        guard let migliore, migliore.punteggio >= 0.5 else { return nil }
        return migliore.voce
    }
}
