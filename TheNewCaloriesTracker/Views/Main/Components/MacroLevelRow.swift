import SwiftUI

struct MacroLevelRow: View {
    let level: String
    let description: String
    let protein: Double
    let carbs: Double
    let fat: Double
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(level).font(.subheadline.bold())
                    if isSelected {
                        Text("Của bạn")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                Text(description).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 8) {
                    MacroTag(label: "P", value: Int(protein), color: .orange)
                    MacroTag(label: "C", value: Int(carbs),   color: .blue)
                    MacroTag(label: "F", value: Int(fat),     color: .green)
                }
            }
        }
        .padding(14)
        .background(isSelected ? Color.black.opacity(0.05) : Color.gray.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.black : Color.clear, lineWidth: 1.5)
        )
        .cornerRadius(14)
    }
}

struct MacroTag: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label).font(.caption2.bold()).foregroundColor(color)
            Text("\(value)g").font(.caption.bold())
        }
    }
}

struct MacroBar: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    let totalCalories: Double

    var proteinCal: Double { protein * 4 }
    var carbsCal: Double   { carbs * 4 }
    var fatCal: Double     { fat * 9 }
    var total: Double      { proteinCal + carbsCal + fatCal }

    var body: some View {
        VStack(spacing: 12) {
            // Bar
            GeometryReader { geo in
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange)
                        .frame(width: geo.size.width * (proteinCal / total))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: geo.size.width * (carbsCal / total))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green)
                        .frame(width: geo.size.width * (fatCal / total))
                }
            }
            .frame(height: 12)

            // Labels
            HStack {
                MacroLabel(color: .orange, name: "Protein", grams: Int(protein), cal: Int(proteinCal))
                Spacer()
                MacroLabel(color: .blue,   name: "Carbs",   grams: Int(carbs),   cal: Int(carbsCal))
                Spacer()
                MacroLabel(color: .green,  name: "Fat",     grams: Int(fat),     cal: Int(fatCal))
            }
        }
    }
}

struct MacroLabel: View {
    let color: Color
    let name: String
    let grams: Int
    let cal: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(name).font(.caption).foregroundColor(.white)
            }
            Text("\(grams)g · \(cal)kcal")
                .font(.caption2).foregroundColor(.white.opacity(0.7))
        }
    }
}
