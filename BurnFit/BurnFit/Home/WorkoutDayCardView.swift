import SwiftUI

struct WorkoutDayCardView: View {
    let day: WorkoutDay

    private var colore: Color { day.completato ? .green : .orange }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Text("GIORNO").font(.system(size: 9, weight: .bold))
                Text("\(day.indice)").font(.system(size: 28, weight: .bold, design: .rounded))
            }
            .foregroundStyle(colore)
            .frame(width: 60, height: 60)
            .background(colore.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 8) {
                Text(day.nome)
                    .font(.headline)
                    .multilineTextAlignment(.leading)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(day.gruppi) { g in
                            Label(g.rawValue, systemImage: g.icona)
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(g.colore.opacity(0.18), in: Capsule())
                                .foregroundStyle(g.colore)
                        }
                    }
                }

                Text("\(day.esercizi.count) esercizi · ~\(day.durataStimataMinuti) min")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack {
                    statoPill
                    if day.completato, let data = day.dataCompletamento {
                        Text(data.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.bold())
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(day.completato ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
    }

    private var statoPill: some View {
        Text(day.completato ? "Completato ✓" : "Da fare")
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(day.completato ? Color.green : Color.orange.opacity(0.2), in: Capsule())
            .foregroundStyle(day.completato ? Color.white : Color.orange)
    }
}
