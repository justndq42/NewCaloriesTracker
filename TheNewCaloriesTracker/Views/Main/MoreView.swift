import SwiftUI

struct MoreView: View {
    let profile: UserProfileModel

    var body: some View {
        NavigationStack {
            List {
                Section("Khám phá") {
                    NavigationLink {
                        TDEEView(profile: profile)
                    } label: {
                        Label("TDEE", systemImage: "flame.fill")
                    }

                    NavigationLink {
                        ProgressChartView()
                    } label: {
                        Label("Tiến độ", systemImage: "chart.bar.fill")
                    }

                    NavigationLink {
                        FoodSearchView()
                    } label: {
                        Label("Tra cứu đồ ăn", systemImage: "magnifyingglass")
                    }
                }
            }
            .navigationTitle("More")
        }
    }
}
