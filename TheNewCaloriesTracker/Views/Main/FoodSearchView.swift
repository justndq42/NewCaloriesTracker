import SwiftUI
import SwiftData

struct FoodSearchView: View {
    @Environment(\.modelContext) private var context
    @Environment(AuthSessionStore.self) private var authStore
    @Query(sort: \CustomFoodModel.createdAt, order: .reverse) private var customFoods: [CustomFoodModel]
    @StateObject private var vm = FoodSearchViewModel()
    @State private var selectedFood: FoodItem?
    @State private var selectedCustomFood: CustomFoodModel?
    @State private var hasSyncedCustomFoods = false
    @State private var syncErrorMessage: String?
    let entryDate: Date

    init(entryDate: Date = Date()) {
        self.entryDate = entryDate
    }

    private var currentUserID: String? {
        authStore.user?.id
    }

    private var accountCustomFoods: [CustomFoodModel] {
        guard let currentUserID else { return [] }
        return customFoods.filter { $0.userID == currentUserID }
    }

    private var matchingCustomFoods: [CustomFoodModel] {
        let trimmedQuery = vm.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return accountCustomFoods }

        return accountCustomFoods.filter {
            SearchQueryNormalizer.localMatches(text: $0.name, query: trimmedQuery)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                    if !matchingCustomFoods.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                            FoodSectionTitle("Món tự tạo")

                            ForEach(matchingCustomFoods) { food in
                                CustomFoodSwipeRow(
                                    food: food,
                                    onSelect: { selectedCustomFood = food },
                                    onDelete: {
                                        Task {
                                            await deleteCustomFood(food)
                                        }
                                    }
                                )
                            }
                        }
                    }

                    if let syncErrorMessage {
                        Text(syncErrorMessage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.ColorToken.calories)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.ColorToken.calories.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
                    }

                    FoodSearchContent(
                        state: vm.searchState,
                        onSelectFood: { selectedFood = $0 },
                        onRetry: { vm.onSearchQueryChanged() }
                    )
                }
                .padding(AppTheme.Spacing.screen)
            }
            .appScreenBackground()
            .searchable(text: $vm.searchQuery, prompt: "Tìm món ăn (vd: pho, banh mi...)")
            .onChange(of: vm.searchQuery) { vm.onSearchQueryChanged() }
            .navigationTitle("Tra cứu calo")
            .onAppear { vm.loadRecommended() }
            .task {
                await syncCustomFoodsIfNeeded()
            }
            .sheet(item: $selectedFood) { food in
                FoodDetailSheet(food: food, entryDate: entryDate) { portionedFood in
                    guard let currentUserID else { return }
                    let entry = vm.addEntry(
                        food: portionedFood,
                        date: entryDate,
                        context: context,
                        userID: currentUserID
                    )
                    Task {
                        await syncDiaryEntry(entry, remoteCustomFoodID: nil, userID: currentUserID)
                    }
                    selectedFood = nil
                }
            }
            .sheet(item: $selectedCustomFood) { food in
                FoodDetailSheet(
                    food: food.foodItem,
                    entryDate: entryDate,
                    customFoodToEdit: food
                ) { portionedFood in
                    guard let currentUserID else { return }
                    let entry = vm.addEntry(
                        food: portionedFood,
                        date: entryDate,
                        context: context,
                        customFoodID: food.resolvedCustomFoodID(),
                        userID: currentUserID
                    )
                    Task {
                        await syncCustomFoodIfNeeded(food, userID: currentUserID)
                        await syncDiaryEntry(entry, remoteCustomFoodID: food.remoteID, userID: currentUserID)
                    }
                    selectedCustomFood = nil
                }
            }
        }
    }

    private func syncCustomFoodsIfNeeded() async {
        guard !hasSyncedCustomFoods else {
            return
        }

        hasSyncedCustomFoods = true
        syncErrorMessage = nil

        guard let currentUserID, let accessToken = await authStore.accessToken() else {
            return
        }

        do {
            try await CustomFoodSyncService.shared.syncAll(
                for: currentUserID,
                context: context,
                accessToken: accessToken
            )
        } catch {
            syncErrorMessage = "Chưa đồng bộ được món tự tạo. Dữ liệu local vẫn dùng được."
        }
    }

    private func deleteCustomFood(_ food: CustomFoodModel) async {
        syncErrorMessage = nil

        do {
            guard let currentUserID else { return }
            let accessToken = await authStore.accessToken()
            try await CustomFoodSyncService.shared.delete(
                food: food,
                userID: currentUserID,
                context: context,
                accessToken: accessToken
            )
        } catch {
            syncErrorMessage = "Chưa xoá được món này trên tài khoản. Vui lòng thử lại."
        }
    }

    private func syncCustomFoodIfNeeded(_ food: CustomFoodModel, userID: String) async {
        guard food.remoteID == nil, let accessToken = await authStore.accessToken() else {
            return
        }

        do {
            try await CustomFoodSyncService.shared.push(food: food, userID: userID, accessToken: accessToken)
            try context.save()
        } catch {
            syncErrorMessage = "Món tự tạo đã log local nhưng chưa đồng bộ được lên tài khoản."
        }
    }

    private func syncDiaryEntry(_ entry: DiaryEntryModel, remoteCustomFoodID: String?, userID: String) async {
        guard let accessToken = await authStore.accessToken() else {
            return
        }

        do {
            try await DiaryEntrySyncService.shared.push(
                entry: entry,
                remoteCustomFoodID: remoteCustomFoodID,
                userID: userID,
                context: context,
                accessToken: accessToken
            )
        } catch {
            syncErrorMessage = "Đã ghi nhật ký local nhưng chưa đồng bộ được lên tài khoản."
        }
    }
}

private struct CustomFoodSwipeRow: View {
    let food: CustomFoodModel
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var dragStartOffset: CGFloat?

    private let deleteButtonWidth: CGFloat = 118
    private let rowHeight: CGFloat = 76

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Button(action: {
                    if offset == 0 {
                        onSelect()
                    } else {
                        closeSwipe()
                    }
                }) {
                    rowContent
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .buttonStyle(.plain)
                .background(AppTheme.ColorToken.card)

                Button(role: .destructive) {
                    withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.86)) {
                        offset = 0
                    }
                    onDelete()
                } label: {
                    Text("Xoá thực phẩm")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: deleteButtonWidth, height: geometry.size.height)
                        .background(AppTheme.ColorToken.calories)
                }
                .buttonStyle(.plain)
            }
            .offset(x: offset)
            .gesture(dragGesture)
            .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.86), value: offset)
        }
        .frame(height: rowHeight)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
        .shadow(color: AppTheme.Shadow.cardColor, radius: AppTheme.Shadow.cardRadius, y: AppTheme.Shadow.cardY)
    }

    private var rowContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(food.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.ColorToken.primary)
                    .lineLimit(1)
                Text(food.unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(food.calories)")
                    .font(.subheadline.bold())
                Text("kcal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(AppTheme.Spacing.card)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }

                if dragStartOffset == nil {
                    dragStartOffset = offset
                }

                let startOffset = dragStartOffset ?? 0
                offset = min(0, max(-deleteButtonWidth, startOffset + value.translation.width))
            }
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else {
                    dragStartOffset = nil
                    return
                }

                let startOffset = dragStartOffset ?? offset
                let projectedOffset = startOffset + value.predictedEndTranslation.width
                offset = projectedOffset < -deleteButtonWidth * 0.45 ? -deleteButtonWidth : 0
                dragStartOffset = nil
            }
    }

    private func closeSwipe() {
        withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.86)) {
            offset = 0
        }
    }
}
