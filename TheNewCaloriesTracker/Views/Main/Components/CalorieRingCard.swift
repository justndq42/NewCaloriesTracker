import SwiftUI

struct CalorieRingCard: View {
    let totalCal: Int
    let targetCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double

    var progress: Double {
        min(Double(totalCal) / targetCalories, 1.0)
    }
    var remaining: Int { Int(targetCalories) - totalCal }
    var isOver: Bool { totalCal > Int(targetCalories) }

    var body: some View {
        VStack(spacing: 18) {
            ring
            stats
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                .fill(AppTheme.ColorToken.primarySoft.gradient)
        )
        .padding(.horizontal)
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 20)
                .frame(width: 168, height: 168)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    isOver
                    ? AngularGradient(colors: [.red, .orange], center: .center)
                    : AngularGradient(colors: [.orange, .yellow, .orange], center: .center),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: 168, height: 168)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progress)

            VStack(spacing: 4) {
                Text("\(isOver ? abs(remaining) : totalCal)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(isOver ? .red : .white)
                Text(isOver ? "kcal dư thừa" : "kcal")
                    .font(.subheadline)
                    .foregroundColor(isOver ? .red.opacity(0.7) : .white.opacity(0.6))
            }
        }
        .padding(.top, 4)
    }

    private var stats: some View {
        HStack(spacing: 0) {
            StatItem(
                value: "\(Int(targetCalories))",
                label: "Mục tiêu",
                color: .white
            )

            Divider()
                .frame(height: 36)
                .background(Color.white.opacity(0.15))

            StatItem(
                value: isOver ? "+\(abs(remaining))" : "\(remaining)",
                label: isOver ? "Dư thừa" : "Còn lại",
                color: isOver ? .red : .green
            )

            Divider()
                .frame(height: 36)
                .background(Color.white.opacity(0.15))

            StatItem(
                value: "\(totalCal)",
                label: "Đã nạp",
                color: .white
            )
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Stat Item
private struct StatItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}
