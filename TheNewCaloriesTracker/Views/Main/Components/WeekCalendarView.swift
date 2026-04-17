import SwiftUI

struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    private let calendar = Calendar.current
    private let weekDays = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]

    var currentWeekDates: [Date] {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let offset = (weekday == 1) ? -6 : -(weekday - 2)
        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: offset + $0, to: today)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(currentWeekDates.enumerated()), id: \.0) { i, date in
                DayCell(
                    dayLabel: weekDays[i],
                    date: date,
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    isToday: calendar.isDateInToday(date)
                )
                .onTapGesture {
                    withAnimation(.spring(duration: 0.3)) {
                        selectedDate = date
                    }
                }
                if i < 6 { Spacer() }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(16)
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let dayLabel: String
    let date: Date
    let isSelected: Bool
    let isToday: Bool

    var dayNumber: String {
        Calendar.current.component(.day, from: date).description
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(dayLabel)
                .font(.caption2.bold())
                .foregroundColor(isSelected ? .white : .secondary)

            Text(dayNumber)
                .font(.subheadline.bold())
                .foregroundColor(isSelected ? .white : (isToday ? .black : .primary))

            Circle()
                .fill(isSelected ? Color.white.opacity(0.6) : (isToday ? Color.black : Color.clear))
                .frame(width: 4, height: 4)
        }
        .frame(width: 36, height: 60)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.black : Color.clear)
        )
    }
}
