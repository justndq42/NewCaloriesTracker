import SwiftUI
import UIKit

struct DiaryLogView: View {
    let entries: [DiaryEntryModel]
    let totalCal: Int
    let targetCalories: Double
    let onDelete: (DiaryEntryModel) -> Void

    private let meals = ["Sáng", "Trưa", "Snack", "Tối"]

    var progress: Double {
        min(Double(totalCal) / targetCalories, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            content
        }
        .appCard(radius: AppTheme.Radius.card)
        .padding(.horizontal)
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Nhật ký hôm nay")
                    .font(.headline.bold())
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(totalCal)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("/ \(Int(targetCalories)) kcal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            miniRing
        }
        .padding(15)
    }

    // MARK: - Mini Ring
    private var miniRing: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                .frame(width: 72, height: 72)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.black,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 72, height: 72)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
            Text("\(Int(progress * 100))%")
                .font(.system(size: 18, weight: .bold))
        }
    }

    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        if entries.isEmpty {
            emptyState
        } else {
            ForEach(meals, id: \.self) { meal in
                let mealEntries = entries.filter { $0.meal == meal }
                if !mealEntries.isEmpty {
                    MealGroupView(
                        meal: meal,
                        entries: mealEntries,
                        onDelete: onDelete
                    )
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife.circle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Chưa có bữa ăn nào")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }
}

// MARK: - Meal Group
private struct MealGroupView: View {
    let meal: String
    let entries: [DiaryEntryModel]
    let onDelete: (DiaryEntryModel) -> Void

    var mealIcon: String {
        switch meal {
        case "Sáng":  return "sunrise.fill"
        case "Trưa":  return "sun.max.fill"
        case "Snack": return "carrot.fill"
        case "Tối":   return "moon.stars.fill"
        default:      return "fork.knife"
        }
    }

    var mealColor: Color {
        switch meal {
        case "Sáng":  return .orange
        case "Trưa":  return .yellow
        case "Snack": return .green
        case "Tối":   return .indigo
        default:      return .gray
        }
    }

    var totalCal: Int { entries.reduce(0) { $0 + $1.calories } }

    var body: some View {
        VStack(spacing: 0) {
            // Meal header
            HStack {
                Image(systemName: mealIcon)
                    .font(.caption.bold())
                    .foregroundColor(mealColor)
                Text(meal)
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(totalCal) kcal")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 9)
            .background(AppTheme.ColorToken.mutedFill)

            // Entries
            ForEach(entries) { entry in
                MealEntrySwipeRow(entry: entry) {
                    onDelete(entry)
                }

                if entry.id != entries.last?.id {
                    Divider().padding(.leading, 16)
                }
            }

            Divider()
        }
    }
}

private struct MealEntrySwipeRow: View {
    let entry: DiaryEntryModel
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var panStartOffset: CGFloat?

    private let deleteButtonWidth: CGFloat = 118
    private let rowHeight: CGFloat = 62

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                rowContent
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(AppTheme.ColorToken.card)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard offset != 0 else { return }
                        closeSwipe()
                    }
                    .overlay {
                        HorizontalSwipeGestureOverlay(
                            onTap: closeSwipe,
                            onBegan: {
                                panStartOffset = offset
                            },
                            onChanged: { translationX in
                                let startOffset = panStartOffset ?? offset
                                offset = min(0, max(-deleteButtonWidth, startOffset + translationX))
                            },
                            onEnded: { translationX, velocityX in
                                let startOffset = panStartOffset ?? offset
                                let projectedOffset = startOffset + translationX + velocityX * 0.12
                                offset = projectedOffset < -deleteButtonWidth * 0.45 ? -deleteButtonWidth : 0
                                panStartOffset = nil
                            }
                        )
                    }

                Button(role: .destructive) {
                    withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.86)) {
                        offset = 0
                    }
                    onDelete()
                } label: {
                    Text("Xoá bữa ăn")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: deleteButtonWidth, height: geometry.size.height)
                        .background(AppTheme.ColorToken.calories)
                }
                .buttonStyle(.plain)
            }
            .offset(x: offset)
            .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.86), value: offset)
        }
        .frame(height: rowHeight)
        .clipped()
    }

    private var rowContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.foodName)
                    .font(.subheadline.bold())
                Text(entry.unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(entry.calories) kcal")
                .font(.subheadline.bold())
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
    }

    private func closeSwipe() {
        guard offset != 0 else { return }

        withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.86)) {
            offset = 0
        }
    }
}

private struct HorizontalSwipeGestureOverlay: UIViewRepresentable {
    let onTap: () -> Void
    let onBegan: () -> Void
    let onChanged: (CGFloat) -> Void
    let onEnded: (CGFloat, CGFloat) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear

        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        panGesture.delegate = context.coordinator
        panGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(panGesture)

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap)
        )
        tapGesture.delegate = context.coordinator
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onTap = onTap
        context.coordinator.onBegan = onBegan
        context.coordinator.onChanged = onChanged
        context.coordinator.onEnded = onEnded
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onTap: onTap,
            onBegan: onBegan,
            onChanged: onChanged,
            onEnded: onEnded
        )
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onTap: () -> Void
        var onBegan: () -> Void
        var onChanged: (CGFloat) -> Void
        var onEnded: (CGFloat, CGFloat) -> Void

        init(
            onTap: @escaping () -> Void,
            onBegan: @escaping () -> Void,
            onChanged: @escaping (CGFloat) -> Void,
            onEnded: @escaping (CGFloat, CGFloat) -> Void
        ) {
            self.onTap = onTap
            self.onBegan = onBegan
            self.onChanged = onChanged
            self.onEnded = onEnded
        }

        @objc func handleTap() {
            onTap()
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            let translation = recognizer.translation(in: recognizer.view)
            let velocity = recognizer.velocity(in: recognizer.view)

            switch recognizer.state {
            case .began:
                onBegan()
            case .changed:
                onChanged(translation.x)
            case .ended, .cancelled, .failed:
                onEnded(translation.x, velocity.x)
            default:
                break
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
                return true
            }

            let velocity = panGesture.velocity(in: panGesture.view)
            return abs(velocity.x) > abs(velocity.y) * 1.15
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}
