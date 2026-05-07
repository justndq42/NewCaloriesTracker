import SwiftUI

struct DiaryLogView: View {
    let entries: [DiaryEntryModel]
    let totalCal: Int
    let targetCalories: Double
    let onDelete: (DiaryEntryModel) -> Void

    private let meals = ["Sáng", "Trưa", "Snack", "Tối"]

    var progress: Double {
        min(Double(totalCal) / targetCalories, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            content
        }
        .appCard(radius: AppTheme.Radius.card)
        .padding(.horizontal)
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Nhật ký hôm nay")
                    .font(.headline.bold())
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(totalCal)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("/ \(Int(targetCalories)) kcal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            miniRing
        }
        .padding(15)
    }

    // MARK: - Mini Ring
    private var miniRing: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                .frame(width: 72, height: 72)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.black,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 72, height: 72)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
            Text("\(Int(progress * 100))%")
                .font(.system(size: 18, weight: .bold))
        }
    }

    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        if entries.isEmpty {
            emptyState
        } else {
            ForEach(meals, id: \.self) { meal in
                let mealEntries = entries.filter { $0.meal == meal }
                if !mealEntries.isEmpty {
                    MealGroupView(
                        meal: meal,
                        entries: mealEntries,
                        onDelete: onDelete
                    )
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife.circle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Chưa có bữa ăn nào")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }
}

// MARK: - Meal Group
private struct MealGroupView: View {
    let meal: String
    let entries: [DiaryEntryModel]
    let onDelete: (DiaryEntryModel) -> Void

    var mealIcon: String {
        switch meal {
        case "Sáng":  return "sunrise.fill"
        case "Trưa":  return "sun.max.fill"
        case "Snack": return "carrot.fill"
        case "Tối":   return "moon.stars.fill"
        default:      return "fork.knife"
        }
    }

    var mealColor: Color {
        switch meal {
        case "Sáng":  return .orange
        case "Trưa":  return .yellow
        case "Snack": return .green
        case "Tối":   return .indigo
        default:      return .gray
        }
    }

    var totalCal: Int { entries.reduce(0) { $0 + $1.calories } }

    var body: some View {
        VStack(spacing: 0) {
            // Meal header
            HStack {
                Image(systemName: mealIcon)
                    .font(.caption.bold())
                    .foregroundColor(mealColor)
                Text(meal)
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(totalCal) kcal")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 9)
            .background(AppTheme.ColorToken.mutedFill)

            // Entries
            ForEach(entries) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.foodName)
                            .font(.subheadline.bold())
                        Text(entry.unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(entry.calories) kcal")
                        .font(.subheadline.bold())
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .swipeActions {
                    Button(role: .destructive) {
                        onDelete(entry)
                    } label: {
                        Label("Xoá", systemImage: "trash")
                    }
                }

                if entry.id != entries.last?.id {
                    Divider().padding(.leading, 16)
                }
            }

            Divider()
        }
    }
}
