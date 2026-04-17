import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [UserProfileModel]
    @State private var vm = AppViewModel()
    
    var body: some View {
        if let profile = profiles.first, profile.isOnboardingDone {
            MainTabView(profile: profile)
                .environment(vm)
        } else {
            OnboardingView()
        }
    }
}
