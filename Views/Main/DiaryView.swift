import SwiftUI
import SwiftData

struct DiaryView: View {
    let profile: UserProfileModel
    @Environment(AppViewModel.self) private var vm
    @Environment(\.modelContext) private var context
    @Query(sort: \DiaryEntryModel.date, order: .reverse) private var allEntries: [DiaryEntryModel]
    
    var todayEntries: [DiaryEntryModel] {
        allEntries.filter { Calendar.current.isDateInToday($0.date) }
    }
    var totalCal: Int { todayEntries.reduce(0) { $0 + $1.calories } }
    var progress: Double { min(Double(totalCal) / profile.targetCalories, 1.0) }
    let meals = ["Sáng", "Trưa", "Snack", "Tối"]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Đã ăn hôm nay").font(.caption).foregroundStyle(.secondary)
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("\(totalCal)").font(.largeTitle.bold())
                                Text("/ \(Int(profile.targetCalories)) kcal")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        ZStack {
                            Circle().stroke(Color.gray.opacity(0.2), lineWidth: 6).frame(width: 56, height: 56)
                            Circle().trim(from: 0, to: progress)
                                .stroke(Color.black, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .rotationEffect(.degrees(-90)).frame(width: 56, height: 56)
                                .animation(.easeInOut, value: progress)
                            Text("\(Int(progress * 100))%").font(.caption2.bold())
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                ForEach(meals, id: \.self) { meal in
                    let entries = todayEntries.filter { $0.meal == meal }
                    if !entries.isEmpty {
                        Section {
                            ForEach(entries) { entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.foodName).font(.subheadline.bold())
                                        Text(entry.unit).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("\(entry.calories) kcal").font(.subheadline.bold())
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        vm.removeEntry(entry, context: context)
                                    } label: { Label("Xoá", systemImage: "trash") }
                                }
                            }
                        } header: {
                            HStack {
                                Text(entries.first?.mealIcon ?? "")
                                Text(meal).textCase(nil)
                                Spacer()
                                Text("\(entries.reduce(0) { $0 + $1.calories }) kcal")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline.bold())
                        }
                    }
                }
            }
            .navigationTitle("Nhật ký hôm nay")
        }
    }
}
