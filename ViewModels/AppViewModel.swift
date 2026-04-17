import Foundation
import SwiftData

@Observable
class AppViewModel {
    
    func removeEntry(_ entry: DiaryEntryModel, context: ModelContext) {
        context.delete(entry)
        try? context.save()
    }
    
    func todayEntries(from entries: [DiaryEntryModel]) -> [DiaryEntryModel] {
        entries.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    func totalCalories(from entries: [DiaryEntryModel]) -> Int {
        entries.reduce(0) { $0 + $1.calories }
    }
    
    func totalProtein(from entries: [DiaryEntryModel]) -> Double {
        entries.reduce(0) { $0 + $1.protein }
    }
    
    func totalCarbs(from entries: [DiaryEntryModel]) -> Double {
        entries.reduce(0) { $0 + $1.carbs }
    }
    
    func totalFat(from entries: [DiaryEntryModel]) -> Double {
        entries.reduce(0) { $0 + $1.fat }
    }
    
    func calorieProgress(entries: [DiaryEntryModel], target: Double) -> Double {
        let total = Double(totalCalories(from: entries))
        return min(total / target, 1.0)
    }
}
