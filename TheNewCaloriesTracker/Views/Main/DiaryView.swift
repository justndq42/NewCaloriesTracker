import SwiftUI
import SwiftData

struct DiaryView: View {
    let profile: UserProfileModel
    @Environment(\.modelContext) private var context
    @Environment(AuthSessionStore.self) private var authStore
    @Query(sort: \DiaryEntryModel.date, order: .reverse) private var allEntries: [DiaryEntryModel]
    @State private var selectedDate: Date = Date()
    @State private var activeSlot: DiaryLogSlot?

    private let timelineHours = Array(7...23)
    private let calendar = Calendar.current
    private static let vietnameseDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "d 'tháng' M"
        return formatter
    }()

    var selectedEntries: [DiaryEntryModel] {
        allEntries.filter {
            $0.userID == profile.userID && calendar.isDate($0.date, inSameDayAs: selectedDate)
        }
    }
    var totalCal: Int { selectedEntries.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double { selectedEntries.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Double { selectedEntries.reduce(0) { $0 + $1.carbs } }
    var totalFat: Double { selectedEntries.reduce(0) { $0 + $1.fat } }
    var nutrition: NutritionProfile { NutritionProfile(profile: profile) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.section) {
                    dateNavigator
                        .padding(.horizontal)

                    summaryCard
                        .padding(.horizontal)

                    LazyVStack(spacing: 10) {
                        ForEach(timelineHours, id: \.self) { hour in
                            DiaryHourSection(
                                hour: hour,
                                entries: entries(for: hour),
                                onAdd: {
                                    activeSlot = DiaryLogSlot(date: dateForHour(hour))
                                },
                                onDelete: { entry in
                                    deleteEntry(entry)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 4)
                .padding(.bottom, 92)
            }
            .appScreenBackground()
            .navigationTitle("Nhật ký")
            .sheet(item: $activeSlot) { slot in
                FoodSearchView(entryDate: slot.date)
            }
        }
    }

    private var dateNavigator: some View {
        HStack {
            Button(action: goToPreviousDay) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 34, height: 34)
                    .background(AppTheme.ColorToken.card)
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text(displayTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                if let subtitle = displaySubtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: goToNextDay) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 34, height: 34)
                    .background(AppTheme.ColorToken.card)
                    .clipShape(Circle())
            }
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 8) {
            diaryMetric(
                icon: "flame.fill",
                value: "\(totalCal)/\(Int(nutrition.targetCalories.rounded()))",
                progress: progress(current: Double(totalCal), target: nutrition.targetCalories),
                color: .red
            )

            diaryMetric(
                icon: "bolt.fill",
                value: "\(valueText(totalProtein))/\(valueText(nutrition.proteinGrams))",
                progress: progress(current: totalProtein, target: nutrition.proteinGrams),
                color: .green
            )

            diaryMetric(
                icon: "leaf.fill",
                value: "\(valueText(totalCarbs))/\(valueText(nutrition.carbsGrams))",
                progress: progress(current: totalCarbs, target: nutrition.carbsGrams),
                color: .blue
            )

            diaryMetric(
                icon: "drop.fill",
                value: "\(valueText(totalFat))/\(valueText(nutrition.fatGrams))",
                progress: progress(current: totalFat, target: nutrition.fatGrams),
                color: .yellow
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .appCard(radius: AppTheme.Radius.card)
    }

    private func diaryMetric(
        icon: String,
        value: String,
        progress: CGFloat,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }

            GeometryReader { geometry in
                let width = geometry.size.width * progress

                Capsule()
                    .fill(Color.gray.opacity(0.14))
                    .overlay(alignment: .leading) {
                        if width > 0 {
                            Capsule()
                                .fill(color)
                                .frame(width: max(width, 8))
                        }
                    }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
    }

    private func entries(for hour: Int) -> [DiaryEntryModel] {
        selectedEntries.filter {
            calendar.component(.hour, from: $0.date) == hour
        }
    }

    private func deleteEntry(_ entry: DiaryEntryModel) {
        Task {
            guard let userID = profile.userID else {
                return
            }

            let accessToken = await authStore.accessToken()
            try? await DiaryEntrySyncService.shared.delete(
                entry: entry,
                userID: userID,
                context: context,
                accessToken: accessToken
            )
        }
    }

    private func dateForHour(_ hour: Int) -> Date {
        calendar.date(
            bySettingHour: hour,
            minute: 0,
            second: 0,
            of: selectedDate
        ) ?? selectedDate
    }

    private var displayTitle: String {
        if calendar.isDateInToday(selectedDate) { return "Hôm nay" }
        if calendar.isDateInYesterday(selectedDate) { return "Hôm qua" }
        if calendar.isDateInTomorrow(selectedDate) { return "Ngày mai" }
        return Self.vietnameseDayFormatter.string(from: selectedDate)
    }

    private var displaySubtitle: String? {
        if calendar.isDateInToday(selectedDate)
            || calendar.isDateInYesterday(selectedDate)
            || calendar.isDateInTomorrow(selectedDate) {
            return Self.vietnameseDayFormatter.string(from: selectedDate)
        }

        return nil
    }

    private func goToPreviousDay() {
        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: selectedDate) else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            selectedDate = previousDay
        }
    }

    private func goToNextDay() {
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            selectedDate = nextDay
        }
    }

    private func valueText(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }

    private func progress(current: Double, target: Double) -> CGFloat {
        guard target > 0 else { return 0 }
        return min(max(current / target, 0), 1)
    }
}

private struct DiaryLogSlot: Identifiable {
    let date: Date

    var id: String {
        date.ISO8601Format()
    }
}

private struct DiaryHourSection: View {
    let hour: Int
    let entries: [DiaryEntryModel]
    let onAdd: () -> Void
    let onDelete: (DiaryEntryModel) -> Void

    private var mealPeriod: MealPeriod {
        MealPeriod.from(hour: hour)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(hourLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(mealPeriod.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 24, height: 24)
                        .background(AppTheme.ColorToken.primary)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
            }

            if entries.isEmpty {
                Text("Chưa có món")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 2)
            } else {
                VStack(spacing: 8) {
                    ForEach(entries) { entry in
                        HStack(alignment: .center, spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.foodName)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                Text(entry.unit)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("\(entry.calories) kcal")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.primary)

                            Button(role: .destructive) {
                                onDelete(entry)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption2.weight(.bold))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .appCard(radius: AppTheme.Radius.compactCard)
    }

    private var hourLabel: String {
        String(format: "%02d:00", hour)
    }
}
