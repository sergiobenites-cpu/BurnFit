import SwiftUI
import Charts

/// Grafico a barre: numero di allenamenti per settimana (settimana da lunedì).
struct WeeklyBarChartView: View {
    let sessioni: [SessionSummary]
    var settimane: Int = 8

    private struct Barra: Identifiable {
        let id: Date          // lunedì della settimana
        let etichetta: String
        let conteggio: Int
    }

    private var barre: [Barra] {
        let cal = Calendar.italiano
        guard let corrente = cal.dateInterval(of: .weekOfYear, for: .now)?.start else { return [] }
        return (0..<settimane).reversed().compactMap { i in
            guard let inizio = cal.date(byAdding: .weekOfYear, value: -i, to: corrente),
                  let fine = cal.date(byAdding: .weekOfYear, value: 1, to: inizio) else { return nil }
            let n = sessioni.filter { $0.dataFine >= inizio && $0.dataFine < fine }.count
            let etichetta = inizio.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "it_IT")))
            return Barra(id: inizio, etichetta: etichetta, conteggio: n)
        }
    }

    var body: some View {
        let dati = barre
        let massimo = max(3, (dati.map(\.conteggio).max() ?? 0) + 1)
        let ultima = dati.last?.id

        Chart(dati) { b in
            BarMark(x: .value("Settimana", b.etichetta),
                    y: .value("Allenamenti", b.conteggio))
                .cornerRadius(6)
                .foregroundStyle(b.id == ultima ? Color.orange : Color.orange.opacity(0.45))
                .annotation(position: .top) {
                    if b.conteggio > 0 {
                        Text("\(b.conteggio)").font(.caption2.bold()).foregroundStyle(.secondary)
                    }
                }
        }
        .chartYScale(domain: 0...massimo)
        .chartYAxis {
            AxisMarks(values: .stride(by: 1))
        }
        .frame(height: 200)
    }
}

#Preview {
    WeeklyBarChartView(sessioni: [])
        .padding()
}
