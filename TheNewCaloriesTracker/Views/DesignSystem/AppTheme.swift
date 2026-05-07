import SwiftUI

enum AppTheme {
    enum ColorToken {
        static let screenBackground = Color(red: 0.96, green: 0.95, blue: 0.93)
        static let card = Color.white
        static let primary = Color.black
        static let primarySoft = Color(red: 0.08, green: 0.08, blue: 0.10)
        static let mutedFill = Color.black.opacity(0.06)
        static let divider = Color.black.opacity(0.08)
        static let disabledFill = Color.black.opacity(0.18)
        static let selectedFill = Color.black.opacity(0.05)
        static let protein = Color.green
        static let carb = Color.blue
        static let fat = Color.yellow
        static let calories = Color.red
        static let water = Color.blue
    }

    enum Radius {
        static let card: CGFloat = 24
        static let compactCard: CGFloat = 18
        static let pill: CGFloat = 999
    }

    enum Spacing {
        static let screen: CGFloat = 20
        static let section: CGFloat = 16
        static let card: CGFloat = 16
        static let compact: CGFloat = 10
    }

    enum Shadow {
        static let cardColor = Color.black.opacity(0.045)
        static let cardRadius: CGFloat = 18
        static let cardY: CGFloat = 8
    }
}

extension View {
    func appScreenBackground() -> some View {
        background(AppTheme.ColorToken.screenBackground.ignoresSafeArea())
    }

    func appCard(
        radius: CGFloat = AppTheme.Radius.card,
        shadow: Bool = false
    ) -> some View {
        self
            .background(AppTheme.ColorToken.card)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(
                color: shadow ? AppTheme.Shadow.cardColor : .clear,
                radius: shadow ? AppTheme.Shadow.cardRadius : 0,
                y: shadow ? AppTheme.Shadow.cardY : 0
            )
    }

    func appPrimaryButtonStyle(radius: CGFloat = AppTheme.Radius.compactCard) -> some View {
        self
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.ColorToken.primary)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    func appCompactPrimaryButtonStyle(radius: CGFloat = AppTheme.Radius.compactCard) -> some View {
        self
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AppTheme.ColorToken.primary)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    func appSecondaryButtonStyle(radius: CGFloat = AppTheme.Radius.compactCard) -> some View {
        self
            .font(.headline.weight(.semibold))
            .foregroundStyle(AppTheme.ColorToken.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.ColorToken.mutedFill)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

struct AppIconBadge: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 34

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.12))
            .clipShape(Circle())
    }
}
