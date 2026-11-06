import SwiftUI
import SwiftData

/// Tab "Progressi": statistiche globali, calendario, grafici e ultime sessioni.
/// Si chiama ProgressiView (non ProgressView) per non scontrarsi con il componente SwiftUI.
struct ProgressiView: View {
    let email: String
    @Query private var sessioni: [SessionSummary]

    @State private var mese = Date.now

    init(email: String) {
        self.email = email
        // Solo le sessioni dell'utente loggato
        _sessioni = Query(filter: #Predicate<SessionSummary> { $0.proprietario == email },
                          sort: \SessionSummary.dataFine, order: .reverse)
    }

    private var cal: Calendar { .italiano }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if sessioni.isEmpty {
                        ContentUnavailableView("Ancora nessun allenamento",
                                               systemImage: "chart.bar",
                                               description: Text("Completa il tuo primo allenamento per vedere i progressi."))
                            .padding(.top, 40)
                    } else {
                        statistiche
                        calendario
                        card("Frequenza settimanale") { WeeklyBarChartView(sessioni: sessioni) }
                        card("Ripartizione muscolare") { DonutChartView(quote: MuscoloQuota.aggrega(sessioni)) }
                        recenti
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progressi")
        }
    }

    // MARK: - Statistiche

    private var statistiche: some View {
        let durataTotale = sessioni.reduce(0) { $0 + $1.durataSecondi }
        let calorie = sessioni.reduce(0) { $0 + $1.calorie }
        let serie = sessioni.reduce(0) { $0 + $1.serieCompletate }
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
            stat("figure.strengthtraining.traditional", "Allenamenti", "\(sessioni.count)")
            stat("clock.fill", "Tempo totale", durataTotale.durataBreve)
            stat("flame.fill", "Calorie", "\(calorie) kcal")
            stat("repeat", "Serie", "\(serie)")
        }
    }

    private func stat(_ icona: String, _ titolo: String, _ valore: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icona).font(.title3).foregroundStyle(.orange)
            Text(valore)
                .font(.system(.title3, design: .rounded).bold())
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(titolo).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Calendario

    private var giorniConAllenamento: Set<Date> {
        Set(sessioni.map { cal.startOfDay(for: $0.dataFine) })
    }

    private var celle: [Date?] {
        guard let primo = cal.date(from: cal.dateComponents([.year, .month], from: mese)),
              let range = cal.range(of: .day, in: .month, for: primo) else { return [] }
        let offset = (cal.component(.weekday, from: primo) - cal.firstWeekday + 7) % 7
        var out: [Date?] = Array(repeating: nil, count: offset)
        for giorno in range {
            out.append(cal.date(byAdding: .day, value: giorno - 1, to: primo))
        }
        return out
    }

    private var titoloMese: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "LLLL yyyy"
        return f.string(from: mese).capitalized
    }

    private var eMeseCorrente: Bool {
        cal.isDate(mese, equalTo: .now, toGranularity: .month)
    }

    private var calendario: some View {
        let attivi = giorniConAllenamento
        let nomiGiorni = ["L", "M", "M", "G", "V", "S", "D"]
        return card("Calendario") {
            VStack(spacing: 12) {
                HStack {
                    Button { cambiaMese(-1) } label: { Image(systemName: "chevron.left") }
                    Spacer()
                    Text(titoloMese).font(.subheadline.bold())
                    Spacer()
                    Button { cambiaMese(1) } label: { Image(systemName: "chevron.right") }
                        .disabled(eMeseCorrente)
                }
                .foregroundStyle(.orange)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                    ForEach(Array(nomiGiorni.enumerated()), id: \.offset) { _, n in
                        Text(n).font(.caption2.bold()).foregroundStyle(.secondary)
                    }
                    ForEach(Array(celle.enumerated()), id: \.offset) { _, data in
                        if let data {
                            cella(data, attivo: attivi.contains(cal.startOfDay(for: data)))
                        } else {
                            Color.clear.frame(height: 34)
                        }
                    }
                }
            }
        }
    }

    private func cella(_ data: Date, attivo: Bool) -> some View {
        let oggi = cal.isDateInToday(data)
        return Text("\(cal.component(.day, from: data))")
            .font(.footnote.weight(attivo ? .bold : .regular))
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(attivo ? Color.orange : Color.clear, in: Circle())
            .overlay(Circle().stroke(oggi ? Color.orange : Color.clear, lineWidth: 1.5))
            .foregroundStyle(attivo ? Color.white : Color.primary)
    }

    private func cambiaMese(_ delta: Int) {
        if let nuovo = cal.date(byAdding: .month, value: delta, to: mese) {
            mese = nuovo
        }
    }

    // MARK: - Ultime sessioni

    private var recenti: some View {
        card("Ultimi allenamenti") {
            VStack(spacing: 0) {
                ForEach(Array(sessioni.prefix(5))) { s in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.nomeGiorno).font(.subheadline.bold()).lineLimit(1)
                            Text(s.dataFine.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(s.durataSecondi.durataBreve) · \(s.calorie) kcal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    if s.id != sessioni.prefix(5).last?.id { Divider() }
                }
            }
        }
    }

    // MARK: - Card generica

    private func card<Content: View>(_ titolo: String, @ViewBuilder contenuto: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(titolo).font(.headline)
            contenuto()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }
}
