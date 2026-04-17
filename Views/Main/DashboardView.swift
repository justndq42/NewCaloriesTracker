import SwiftUI
import SwiftData

struct DashboardView: View {
    let profile: UserProfileModel
    @Environment(AppViewModel.self) private var vm
    @Environment(\.modelContext) private var context
    @Query private var allEntries: [DiaryEntryModel]
    @State private var selectedDate: Date = Date()
    @State private var showNavTitle = false

    var todayEntries: [DiaryEntryModel] {
        allEntries.filter {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
    }
    var totalCal: Int        { todayEntries.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double { todayEntries.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Double   { todayEntries.reduce(0) { $0 + $1.carbs } }
    var totalFat: Double     { todayEntries.reduce(0) { $0 + $1.fat } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                        .opacity(showNavTitle ? 0 : 1)
                        .animation(.easeInOut(duration: 0.2), value: showNavTitle)

                    WeekCalendarView(selectedDate: $selectedDate)
                        .padding(.horizontal)

                    CalorieRingCard(
                        totalCal: totalCal,
                        targetCalories: profile.targetCalories,
                        totalProtein: totalProtein,
                        totalCarbs: totalCarbs,
                        totalFat: totalFat
                    )

                    MacroSectionView(
                        totalProtein: totalProtein,
                        totalCarbs: totalCarbs,
                        totalFat: totalFat,
                        proteinTarget: profile.proteinGrams,
                        carbsTarget: profile.carbsGrams,
                        fatTarget: profile.fatGrams
                    )

                    DiaryLogView(
                        entries: todayEntries,
                        totalCal: totalCal,
                        targetCalories: profile.targetCalories,
                        onDelete: deleteEntry
                    )
                }
                .padding(.top, 8)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: geo.frame(in: .named("scroll")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                showNavTitle = value < -10
            }
            .background(Color.gray.opacity(0.07))
            .navigationTitle("Tổng Quan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Tổng Quan")
                        .font(.headline.bold())
                        .opacity(showNavTitle ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: showNavTitle)
                }
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedDate.formatted(.dateTime.weekday(.wide).day().month()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Tổng Quan")
                    .font(.largeTitle.bold())
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, -40)
    }
    // MARK: - Delete
    private func deleteEntry(_ entry: DiaryEntryModel) {
        vm.removeEntry(entry, context: context)
    }
}

// MARK: - Scroll Offset Key
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
