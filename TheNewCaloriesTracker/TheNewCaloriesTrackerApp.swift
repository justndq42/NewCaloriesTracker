import SwiftUI
import SwiftData

@main
struct CaloriesTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [UserProfileModel.self, DiaryEntryModel.self, CustomFoodModel.self])
    }
}
