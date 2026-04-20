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
            List {
                Section {
                    QuickActionRow(
                        icon: "fork.knife.circle.fill",
                        title: "Ghi lại bữa ăn",
                        subtitle: "Mở tìm kiếm thức ăn để thêm vào nhật ký"
                    ) {
                        dismiss()
                        onSelect(.meal)
                    }

                    QuickActionRow(
                        icon: "drop.circle.fill",
                        title: "Mục tiêu nước",
                        subtitle: "Chọn mức nước uống mỗi ngày"
                    ) {
                        dismiss()
                        onSelect(.waterGoal)
                    }

                    QuickActionRow(
                        icon: "scalemass.fill",
                        title: "Cập nhật cân nặng",
                        subtitle: "Lưu lại cân nặng hiện tại của bạn"
                    ) {
                        dismiss()
                        onSelect(.weight)
                    }

                    QuickActionRow(
                        icon: "square.and.pencil.circle.fill",
                        title: "Tạo thực phẩm",
                        subtitle: "Thêm món tự custom với đủ dinh dưỡng"
                    ) {
                        dismiss()
                        onSelect(.customFood)
                    }
                }
            }
            .navigationTitle("Thêm nhanh")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium, .large])
        }
    }
}

private struct QuickActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.black)
                    .frame(width: 34)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 6)
        }
    }
}
