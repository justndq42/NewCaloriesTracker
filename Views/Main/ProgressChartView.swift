import SwiftUI
import Charts
import SwiftData

struct ProgressChartView: View {
    @Query(sort: \DiaryEntryModel.date) private var allEntries: [DiaryEntryModel]
    
    var weekData: [(day: String, calories: Int)] {
        let calendar = Calendar.current
        let days = ["T2","T3","T4","T5","T6","T7","CN"]
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: -(6 - offset), to: Date())!
            let cal = allEntries
                .filter { calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + Int($1.calories) }
            return (days[offset], cal)
        }
    }
    
    var avgCalories: Int {
        let nonZero = weekData.filter { $0.calories > 0 }
        guard !nonZero.isEmpty else { return 0 }
        return nonZero.reduce(0) { $0 + $1.calories } / nonZero.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Calo 7 ngày qua").font(.subheadline.bold())
                        Chart(weekData, id: \.day) { item in
                            BarMark(x: .value("Ngày", item.day),
                                    y: .value("Calo", item.calories))
                            .foregroundStyle(Color.black).cornerRadius(6)
                        }
                        .frame(height: 180).chartYAxis(.hidden)
                    }
                    .padding().background(Color.white).cornerRadius(20)
                    
                    // Stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(icon: "📊", value: "\(avgCalories)", unit: "kcal/ngày", label: "Trung bình")
                        StatCard(icon: "📅", value: "\(weekData.filter { $0.calories > 0 }.count)", unit: "ngày", label: "Có ghi nhận")
                        StatCard(icon: "🔥", value: "\(weekData.last?.calories ?? 0)", unit: "kcal", label: "Hôm nay")
                        StatCard(icon: "📈", value: "\(weekData.reduce(0) { $0 + $1.calories })", unit: "kcal", label: "Tổng tuần")
                    }
                }
                .padding()
            }
            .navigationTitle("Tiến độ")
            .background(Color.gray.opacity(0.07))
        }
    }
}

struct StatCard: View {
    let icon: String; let value: String; let unit: String; let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(icon).font(.title2)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value).font(.title2.bold())
                Text(unit).font(.caption).foregroundStyle(.secondary)
            }
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18).background(Color.white).cornerRadius(20)
    }
}
