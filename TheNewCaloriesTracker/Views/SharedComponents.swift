import SwiftUI

//(nền tối)
struct MacroBadge: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(value).font(.subheadline.bold()).foregroundColor(.white)
            Text(label).font(.caption2).foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }
}
// nền sáng 
struct MacroCard: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(value, specifier: "%.1f")g").font(.headline.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}
