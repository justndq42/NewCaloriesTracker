import SwiftUI

enum QuickActionSheet: String, Identifiable {
    case meal
    case waterGoal
    case weight
    case customFood

    var id: String { rawValue }
}

struct QuickActionsSheet: View {
    let onSelect: (QuickActionSheet) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chọn thao tác bạn muốn thêm")
                            .font(.headline.bold())
                        Text("Các thay đổi sẽ được lưu vào nhật ký hoặc hồ sơ hiện tại.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 2)

                    VStack(spacing: AppTheme.Spacing.compact) {
                        QuickActionRow(
                            icon: "fork.knife.circle.fill",
                            color: AppTheme.ColorToken.calories,
                            title: "Ghi lại bữa ăn",
                            subtitle: "Mở tìm kiếm thức ăn để thêm vào nhật ký"
                        ) {
                            dismiss()
                            onSelect(.meal)
                        }

                        QuickActionRow(
                            icon: "drop.circle.fill",
                            color: AppTheme.ColorToken.water,
                            title: "Mục tiêu nước",
                            subtitle: "Chọn mức nước uống mỗi ngày"
                        ) {
                            dismiss()
                            onSelect(.waterGoal)
                        }

                        QuickActionRow(
                            icon: "scalemass.fill",
                            color: AppTheme.ColorToken.primary,
                            title: "Cập nhật cân nặng",
                            subtitle: "Lưu lại cân nặng hiện tại của bạn"
                        ) {
                            dismiss()
                            onSelect(.weight)
                        }

                        QuickActionRow(
                            icon: "square.and.pencil.circle.fill",
                            color: AppTheme.ColorToken.protein,
                            title: "Tạo thực phẩm",
                            subtitle: "Thêm món tự custom với đủ dinh dưỡng"
                        ) {
                            dismiss()
                            onSelect(.customFood)
                        }
                    }
                }
                .padding(AppTheme.Spacing.screen)
            }
            .appScreenBackground()
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: AppTheme.Spacing.compact)
            }
            .navigationTitle("Thêm nhanh")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium, .large])
            .presentationBackground(AppTheme.ColorToken.screenBackground)
        }
    }
}

private struct QuickActionRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                AppIconBadge(systemName: icon, color: color, size: 38)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.ColorToken.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary.opacity(0.75))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .appCard(radius: AppTheme.Radius.compactCard, shadow: true)
        }
        .buttonStyle(.plain)
    }
}
