import SwiftUI

struct MacroProgressItem: View {
    let symbolName: String
    let label: String
    let current: Double
    let target: Double
    let color: Color

    var progress: Double {
        guard target > 0 else { return 0 }
        return current / target
    }

    var isOverTarget: Bool { current > target }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: symbolName)
                    .font(.caption.bold())
                    .foregroundColor(isOverTarget ? .red : color)
                Text(label)
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.8))
            }

            // Progress bar
            GeometryReader { geo in
                let totalWidth = geo.size.width
                let milestoneX = totalWidth * 0.9
                let fillWidth = min(progress * milestoneX, totalWidth)

                ZStack(alignment: .leading) {
                    // Background (80% chiều rộng)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: milestoneX, height: 6)

                    // Vùng vượt quá (20% còn lại) — màu nhạt hơn
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: totalWidth - milestoneX, height: 6)
                        .offset(x: milestoneX)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isOverTarget ? Color.red : color)
                        .frame(width: max(0, fillWidth), height: 6)
                        .animation(.easeInOut(duration: 0.6), value: progress)

                    // Dấu mốc 100%
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 2.5, height: 12)
                        .offset(x: milestoneX - 1, y: -3)
                }
            }
            .frame(height: 6)

            // Value
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("\(Int(current))")
                    .font(.title3.bold())
                    .foregroundColor(isOverTarget ? .red : .white)
                Text("/ \(Int(target))g")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
