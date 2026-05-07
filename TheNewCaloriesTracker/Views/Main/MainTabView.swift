import SwiftUI

struct MainTabView: View {
    let profile: UserProfileModel
    @State private var selectedTab: MainTab = .dashboard
    @State private var isShowingQuickActions = false
    @State private var activeQuickSheet: QuickActionSheet?
    private let tabBarReservedHeight: CGFloat = 64

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView(profile: profile)
                    .tag(MainTab.dashboard)

                DiaryView(profile: profile)
                    .tag(MainTab.diary)

                MealPlanView(profile: profile)
                    .tag(MainTab.mealPlan)

                MoreView(profile: profile)
                    .tag(MainTab.more)
            }
            .toolbar(.hidden, for: .tabBar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear
                    .frame(height: tabBarReservedHeight)
            }

            customTabBar
        }
        .sheet(isPresented: $isShowingQuickActions) {
            QuickActionsSheet { activeQuickSheet = $0 }
        }
        .sheet(item: $activeQuickSheet) { sheet in
            switch sheet {
            case .meal:
                FoodSearchView(entryDate: Date())
            case .waterGoal:
                WaterGoalSheet()
            case .weight:
                UpdateWeightSheet(profile: profile)
            case .customFood:
                CreateCustomFoodSheet()
            }
        }
        .tint(.black)
    }

    private var customTabBar: some View {
        HStack(spacing: 10) {
            tabButton(tab: .dashboard, title: "Tổng quan", systemImage: "square.grid.2x2.fill")
            tabButton(tab: .diary, title: "Nhật ký", systemImage: "book.fill")

            Button {
                isShowingQuickActions = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.black)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.14), radius: 10, y: 4)
            }
            .offset(y: -10)

            tabButton(tab: .mealPlan, title: "Meal Plan", systemImage: "calendar.badge.plus")
            tabButton(tab: .more, title: "Tài khoản", systemImage: "person.crop.circle.fill")
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 14, y: 4)
        )
        .padding(.horizontal, 12)
        .ignoresSafeArea(.container, edges: .bottom)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private func tabButton(tab: MainTab, title: String, systemImage: String) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .black : .secondary)
            .frame(maxWidth: .infinity)
        }
    }

}

private enum MainTab {
    case dashboard
    case diary
    case mealPlan
    case more
}
