import SwiftUI

struct MainTabView: View {
    let profile: UserProfileModel

    var body: some View {
        TabView {
            DashboardView(profile: profile)
                .tabItem { Label("Tổng quan", systemImage: "square.grid.2x2") }
            TDEEView(profile: profile)
                .tabItem { Label("TDEE", systemImage: "flame") }
            FoodSearchView()
                .tabItem { Label("Đồ ăn", systemImage: "magnifyingglass") }
            MealPlanView(profile: profile)
                .tabItem { Label("Meal Plan", systemImage: "calendar.badge.plus") }
            DiaryView(profile: profile)
                .tabItem { Label("Nhật ký", systemImage: "book") }
            ProgressChartView()
                .tabItem { Label("Tiến độ", systemImage: "chart.bar") }
        }
        .tint(.black)
    }
}
