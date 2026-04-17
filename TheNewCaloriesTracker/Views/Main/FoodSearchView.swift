import SwiftUI
import SwiftData

struct FoodSearchView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var vm = FoodSearchViewModel()
    @State private var selectedFood: FoodItem?
    @State private var selectedMeal: String = "Trưa"

    var body: some View {
        NavigationStack {
            List {
                switch vm.searchState {
                case .idle(let recommended):
                    idleSection(recommended)
                case .loading:
                    loadingSection
                case .success(let foods):
                    resultsSection(foods)
                case .error(let msg):
                    errorSection(msg)
                }
            }
            .searchable(text: $vm.searchQuery, prompt: "Tìm món ăn (vd: pho, banh mi...)")
            .onChange(of: vm.searchQuery) { vm.onSearchQueryChanged() }
            .navigationTitle("Tra cứu calo")
            .onAppear { vm.loadRecommended() }
            .sheet(item: $selectedFood) { food in
                FoodDetailSheet(food: food, selectedMeal: $selectedMeal) {
                    vm.addEntry(food: food, meal: selectedMeal, context: context)
                    selectedFood = nil
                }
            }
        }
    }

    // MARK: - Idle
    @ViewBuilder
    func idleSection(_ items: [FoodItem]) -> some View {
        if items.isEmpty {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView().scaleEffect(1.1)
                        Text("Đang tải gợi ý...")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 40)
            }
            .listRowBackground(Color.clear)
        } else {
            Section {
                ForEach(items) { food in
                    Button { selectedFood = food } label: {
                        FoodRow(food: food)
                    }
                }
            } header: {
                HStack {
                    Text("⭐ Gợi ý phổ biến")
                    Spacer()
                    Text("Powered by Spoonacular")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Loading
    var loadingSection: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 10) {
                    ProgressView().scaleEffect(1.1)
                    Text("Đang tìm kiếm...")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 30)
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Results
    func resultsSection(_ foods: [FoodItem]) -> some View {
        Section {
            ForEach(foods) { food in
                Button { selectedFood = food } label: {
                    FoodRow(food: food)
                }
            }
        } header: {
            Text("Kết quả (\(foods.count) món)")
        }
    }

    // MARK: - Error
    func errorSection(_ msg: String) -> some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40)).foregroundStyle(.secondary)
                Text(msg)
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button {
                    vm.onSearchQueryChanged()
                } label: {
                    Label("Thử lại", systemImage: "arrow.clockwise")
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(Color.black).foregroundColor(.white)
                        .cornerRadius(12).font(.subheadline.bold())
                }
            }
            .frame(maxWidth: .infinity).padding(.vertical, 40)
        }
        .listRowBackground(Color.clear)
    }
}

// MARK: - Food Row
struct FoodRow: View {
    let food: FoodItem
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(food.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
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
        .padding(.vertical, 4)
    }
}

// MARK: - Food Detail Sheet
struct FoodDetailSheet: View {
    let food: FoodItem
    @Binding var selectedMeal: String
    let onAdd: () -> Void
    @Environment(\.dismiss) var dismiss
    let meals = ["Sáng", "Trưa", "Snack", "Tối"]
    let mealIcons = ["☀️", "🌤️", "🍎", "🌙"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Calories hero
                    VStack(spacing: 6) {
                        Text("\(food.calories)")
                            .font(.system(size: 80, weight: .bold, design: .rounded))
                        Text("kcal")
                            .font(.title3).foregroundStyle(.secondary)
                        Text(food.unit)
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(24)

                    // Macros
                    HStack(spacing: 12) {
                        MacroDetailCard(
                            icon: "🥩",
                            label: "Protein",
                            value: food.protein,
                            color: .orange
                        )
                        MacroDetailCard(
                            icon: "🍞",
                            label: "Carbs",
                            value: food.carbs,
                            color: .blue
                        )
                        MacroDetailCard(
                            icon: "🫒",
                            label: "Chất béo",
                            value: food.fat,
                            color: .green
                        )
                    }

                    // Meal picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Thêm vào bữa")
                            .font(.subheadline.bold())
                        HStack(spacing: 8) {
                            ForEach(Array(meals.enumerated()), id: \.0) { i, meal in
                                Button { selectedMeal = meal } label: {
                                    VStack(spacing: 4) {
                                        Text(mealIcons[i]).font(.title3)
                                        Text(meal).font(.caption.bold())
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(selectedMeal == meal ? Color.black : Color.gray.opacity(0.08))
                                    .foregroundColor(selectedMeal == meal ? .white : .primary)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(selectedMeal == meal ? Color.black : Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }

                    // Add button
                    Button(action: onAdd) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Thêm vào nhật ký")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                }
                .padding()
            }
            .navigationTitle(food.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Macro Detail Card
struct MacroDetailCard: View {
    let icon: String
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(icon).font(.title2)
            Text("\(value, specifier: "%.1f")g")
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.08))
        .cornerRadius(16)
    }
}
