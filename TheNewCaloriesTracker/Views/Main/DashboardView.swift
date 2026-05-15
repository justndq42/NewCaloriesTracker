import SwiftUI
import SwiftData

struct DashboardView: View {
    let profile: UserProfileModel
    @Environment(\.modelContext) private var context
    @Environment(AuthSessionStore.self) private var authStore
    @Query private var allEntries: [DiaryEntryModel]
    @State private var selectedDate: Date = Date()

    var todayEntries: [DiaryEntryModel] {
        allEntries.filter {
            $0.userID == profile.userID && Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
    }
    var totalCal: Int        { todayEntries.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double { todayEntries.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Double   { todayEntries.reduce(0) { $0 + $1.carbs } }
    var totalFat: Double     { todayEntries.reduce(0) { $0 + $1.fat } }
    var nutrition: NutritionProfile { NutritionProfile(profile: profile) }
    private static let vietnameseDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, 'ngày' d 'tháng' M 'năm' yyyy"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.section) {
                    headerSection

                    WeekCalendarView(selectedDate: $selectedDate)
                        .padding(.horizontal)

                    CalorieRingCard(
                        totalCal: totalCal,
                        targetCalories: nutrition.targetCalories,
                        totalProtein: totalProtein,
                        totalCarbs: totalCarbs,
                        totalFat: totalFat
                    )

                    MacroSectionView(
                        totalProtein: totalProtein,
                        totalCarbs: totalCarbs,
                        totalFat: totalFat,
                        proteinTarget: nutrition.proteinGrams,
                        carbsTarget: nutrition.carbsGrams,
                        fatTarget: nutrition.fatGrams
                    )

                    WaterIntakeCard(date: selectedDate)

                    DiaryLogView(
                        entries: todayEntries,
                        totalCal: totalCal,
                        targetCalories: nutrition.targetCalories,
                        onDelete: deleteEntry
                    )
                }
                .padding(.top, 6)
                .padding(.bottom, 92)
            }
            .appScreenBackground()
            .navigationTitle("Tổng quan")
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Text(Self.vietnameseDateFormatter.string(from: selectedDate).capitalized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal)
    }
    // MARK: - Delete
    private func deleteEntry(_ entry: DiaryEntryModel) {
        Task {
            await deleteEntryFromAccount(entry)
        }
    }

    private func deleteEntryFromAccount(_ entry: DiaryEntryModel) async {
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
