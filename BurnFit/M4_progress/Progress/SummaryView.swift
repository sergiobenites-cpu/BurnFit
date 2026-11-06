import SwiftUI

/// Schermata finale "Ottimo lavoro!" mostrata a fine allenamento.
struct SummaryView: View {
    let summary: SessionSummary
    var onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                    metrica("timer", "Durata", summary.durataSecondi.durataBreve)
                    metrica("flame.fill", "Calorie", "\(summary.calorie) kcal")
                    metrica("checkmark.circle.fill", "Esercizi", "\(summary.eserciziCompletati)/\(summary.eserciziTotali)")
                    metrica("repeat", "Serie", "\(summary.serieCompletate)")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Muscoli allenati").font(.headline)
                    DonutChartView(quote: summary.distribuzione)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Riepilogo")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            Button(action: onClose) {
                Text("Fine")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .padding()
            .background(.bar)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 54))
                .foregroundStyle(.orange)
            Text("Ottimo lavoro!").font(.largeTitle.bold())
            Text(summary.nomeGiorno)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text(summary.dataFine.formatted(date: .long, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private func metrica(_ icona: String, _ titolo: String, _ valore: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icona).font(.title3).foregroundStyle(.orange)
            Text(valore)
                .font(.system(.title3, design: .rounded).bold())
                .monospacedDigit()
            Text(titolo).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }
}
