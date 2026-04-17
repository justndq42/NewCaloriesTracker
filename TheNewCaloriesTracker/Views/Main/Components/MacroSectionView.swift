import SwiftUI

struct MacroSectionView: View {
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let proteinTarget: Double
    let carbsTarget: Double
    let fatTarget: Double

    var body: some View {
        HStack(spacing: 12) {
            MacroProgressItem(
                symbolName: "bolt.fill",
                label: "Chất đạm",
                current: totalProtein,
                target: proteinTarget,
                color: .green
            )
            MacroProgressItem(
                symbolName: "leaf.fill",
                label: "Tinh bột",
                current: totalCarbs,
                target: carbsTarget,
                color: .blue
            )
            MacroProgressItem(
                symbolName: "drop.fill",
                label: "Chất béo",
                current: totalFat,
                target: fatTarget,
                color: .yellow
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.12))
        )
        .padding(.horizontal)
    }
}
