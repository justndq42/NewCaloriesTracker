import SwiftUI
import SwiftData

@main
struct CaloriesTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [UserProfileModel.self, DiaryEntryModel.self])
    }
}
