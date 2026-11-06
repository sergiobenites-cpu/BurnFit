import SwiftUI
import SwiftData

/// Modale per scambiare un esercizio con un altro dello stesso gruppo muscolare.
/// Cambia il riferimento `ExerciseInPlan.exercise` (non crea mai nuovi `Exercise`,
/// il nome è `@Attribute(.unique)`) e ricalcola i recuperi per il nuovo esercizio.
struct ReplaceExerciseSheet: View {
    let item: ExerciseInPlan
    var livello: LivelloEsperienza = .intermedio

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.nome) private var catalogo: [Exercise]

    private var attuale: Exercise? { item.exercise }

    private var alternative: [Exercise] {
        guard let attuale else { return [] }
        return catalogo.filter { $0.gruppo == attuale.gruppo && $0.nome != attuale.nome }
    }

    /// Nomi già presenti nello stesso allenamento (per evitare doppioni)
    private var giaInGiorno: Set<String> {
        Set((item.day?.esercizi ?? []).compactMap { $0.exercise?.nome })
    }

    var body: some View {
        NavigationStack {
            List {
                if let attuale {
                    Section("Esercizio attuale") {
                        riga(attuale, selezionabile: false, corrente: true)
                    }
                }

                Section(alternative.isEmpty
                        ? "Alternative"
                        : "Alternative · \(attuale?.gruppo.rawValue ?? "")") {
                    if alternative.isEmpty {
                        ContentUnavailableView("Nessuna alternativa",
                                               systemImage: "arrow.triangle.2.circlepath",
                                               description: Text("Non ci sono altri esercizi per questo gruppo muscolare."))
                    } else {
                        ForEach(alternative) { e in
                            let presente = giaInGiorno.contains(e.nome)
                            Button { scegli(e) } label: {
                                riga(e, selezionabile: !presente, corrente: false)
                            }
                            .disabled(presente)
                        }
                    }
                }
            }
            .navigationTitle("Sostituisci")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annulla") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func riga(_ e: Exercise, selezionabile: Bool, corrente: Bool) -> some View {
        HStack(spacing: 12) {
            ExerciseImageView(exercise: e)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(e.nome).font(.headline).foregroundStyle(.primary)
                Text("\(e.attrezzatura) · \(e.isComposto ? "Multiarticolare" : "Isolamento") · \(e.livelloMinimo.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !corrente && !selezionabile {
                    Text("Già presente in questo allenamento")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            if corrente {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.orange)
            } else if selezionabile {
                Image(systemName: "chevron.right").font(.footnote.bold()).foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle())
    }

    private func scegli(_ nuovo: Exercise) {
        item.exercise = nuovo
        // Ogni esercizio ha i suoi tempi di recupero
        let r = RecuperoCalculator.calcola(per: nuovo, livello: livello)
        item.recuperoSecondi = r.traSerie
        item.recuperoCambioSecondi = r.cambioEsercizio
        try? context.save()
        dismiss()
    }
}
