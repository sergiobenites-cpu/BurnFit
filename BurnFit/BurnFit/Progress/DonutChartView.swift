import SwiftUI
import Charts

/// Grafico a ciambella della ripartizione muscolare (serie per gruppo).
struct DonutChartView: View {
    let quote: [MuscoloQuota]

    private var totale: Int { quote.reduce(0) { $0 + $1.valore } }
    private var ordinate: [MuscoloQuota] { quote.sorted { $0.valore > $1.valore } }

    var body: some View {
        if quote.isEmpty || totale == 0 {
            Text("Nessun dato da mostrare")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 120)
        } else {
            VStack(spacing: 16) {
                ZStack {
                    Chart(ordinate) { q in
                        SectorMark(angle: .value("Serie", q.valore),
                                   innerRadius: .ratio(0.62),
                                   angularInset: 2)
                            .cornerRadius(4)
                            .foregroundStyle(q.gruppo.colore)
                    }
                    .chartLegend(.hidden)

                    VStack(spacing: 0) {
                        Text("\(totale)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("serie").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(height: 220)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                    ForEach(ordinate) { q in
                        HStack(spacing: 8) {
                            Circle().fill(q.gruppo.colore).frame(width: 10, height: 10)
                            Text(q.gruppo.rawValue).font(.footnote.bold())
                            Spacer(minLength: 0)
                            Text("\(q.valore) · \(percentuale(q))%")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
    }

    private func percentuale(_ q: MuscoloQuota) -> Int {
        Int((Double(q.valore) / Double(max(totale, 1)) * 100).rounded())
    }
}

#Preview {
    DonutChartView(quote: [
        MuscoloQuota(gruppo: .petto, valore: 8),
        MuscoloQuota(gruppo: .spalle, valore: 5),
        MuscoloQuota(gruppo: .tricipiti, valore: 4)
    ])
    .padding()
}
