import SwiftUI

struct MoreView: View {
    let profile: UserProfileModel

    var body: some View {
        AccountView(profile: profile)
    }
}
