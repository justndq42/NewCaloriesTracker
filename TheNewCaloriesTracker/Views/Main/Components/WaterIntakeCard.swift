import SwiftUI
import UIKit

struct WaterIntakeCard: View {
    let date: Date
    @Environment(AuthSessionStore.self) private var authStore
    @State private var waterStore = WaterIntakeStore.shared
    @State private var totalWater = 0
    @State private var amountScale: CGFloat = 1
    @State private var iconScale: CGFloat = 1
    @State private var buttonFlash = false
    @State private var goalReachedFlash = false

    private let defaultVolume = 500

    private var selectedDay: Date {
        Calendar.current.startOfDay(for: date)
    }

    private var currentUserID: String? {
        authStore.user?.id
    }

    private var dailyGoal: Int {
        guard let currentUserID else { return 3_000 }
        return waterStore.dailyGoal(for: currentUserID)
    }

    private var fillProgress: CGFloat {
        min(CGFloat(totalWater) / CGFloat(dailyGoal), 1)
    }

    private var actionTint: Color {
        totalWater == 0 ? .white.opacity(0.28) : .white.opacity(0.78)
    }

    private var canIncrement: Bool {
        guard let currentUserID else { return false }
        return waterStore.canIncrement(on: selectedDay, userID: currentUserID)
    }

    private var incrementTint: Color {
        canIncrement ? .white.opacity(0.9) : AppTheme.ColorToken.protein.opacity(0.86)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            bottleIcon

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Uống nước")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                    Text("\(totalWater) ml")
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .scaleEffect(amountScale)
                        .animation(.spring(response: 0.22, dampingFraction: 0.62), value: amountScale)
                    Text("Mục tiêu \(dailyGoal / 1_000)L/ngày")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer(minLength: 8)

                compactControlPill
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous)
                .fill(AppTheme.ColorToken.primarySoft)
        )
        .padding(.horizontal)
        .onAppear(perform: reloadTotal)
        .onChange(of: selectedDay) { _, _ in
            reloadTotal()
        }
        .onChange(of: waterStore.revision) { _, _ in
            reloadTotal()
        }
    }

    private var bottleIcon: some View {
        ZStack {
            GeometryReader { geometry in
                let iconSize = min(geometry.size.width, geometry.size.height)
                ZStack(alignment: .bottom) {
                    Image(systemName: "waterbottle.fill")
                        .font(.system(size: iconSize, weight: .regular))
                        .foregroundStyle(.white.opacity(0.08))

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.03, green: 0.33, blue: 0.87),
                                    Color(red: 0.0, green: 0.16, blue: 0.55)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: geometry.size.height * fillProgress)
                        .mask(
                            Image(systemName: "waterbottle.fill")
                                .font(.system(size: iconSize, weight: .regular))
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: fillProgress)

                    Image(systemName: "waterbottle.fill")
                        .font(.system(size: iconSize, weight: .regular))
                        .foregroundStyle(.white.opacity(0.58))
                }
            }
            .frame(width: 26, height: 42)
        }
        .scaleEffect(iconScale)
        .animation(.spring(response: 0.22, dampingFraction: 0.62), value: iconScale)
    }

    private var compactControlPill: some View {
        HStack(spacing: 8) {
            Button(action: decrementWater) {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(actionTint)
                    .frame(width: 22, height: 22)
            }
            .disabled(totalWater == 0)

            Divider()
                .frame(height: 16)
                .overlay(Color.white.opacity(0.16))

            Text("500 ml")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
                .frame(minWidth: 42)

            Divider()
                .frame(height: 16)
                .overlay(Color.white.opacity(0.16))

            Button(action: incrementWater) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(incrementTint)
                    .frame(width: 22, height: 22)
            }
            .disabled(!canIncrement)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(
                    goalReachedFlash
                    ? AppTheme.ColorToken.protein.opacity(0.2)
                    : buttonFlash
                    ? AppTheme.ColorToken.card.opacity(0.2)
                    : AppTheme.ColorToken.card.opacity(0.12)
                )
        )
        .animation(.easeInOut(duration: 0.18), value: buttonFlash)
        .animation(.easeInOut(duration: 0.18), value: goalReachedFlash)
    }

    private func incrementWater() {
        guard canIncrement else {
            animateGoalReachedFeedback()
            return
        }
        guard let currentUserID else { return }
        waterStore.increment(volume: defaultVolume, on: selectedDay, userID: currentUserID)
        totalWater = waterStore.total(for: selectedDay, userID: currentUserID)
        syncWaterLog()
        animateFeedback()
    }

    private func decrementWater() {
        guard let currentUserID else { return }
        waterStore.decrement(volume: defaultVolume, on: selectedDay, userID: currentUserID)
        totalWater = waterStore.total(for: selectedDay, userID: currentUserID)
        syncWaterLog()
        animateFeedback()
    }

    private func reloadTotal() {
        guard let currentUserID else {
            totalWater = 0
            return
        }

        totalWater = waterStore.total(for: selectedDay, userID: currentUserID)
    }

    private func syncWaterLog() {
        Task {
            guard let userID = authStore.user?.id,
                  let accessToken = await authStore.accessToken() else {
                return
            }

            try? await WaterLogSyncService.shared.syncLocalLog(
                on: selectedDay,
                userID: userID,
                accessToken: accessToken
            )
        }
    }

    private func animateFeedback() {
        amountScale = 1.08
        iconScale = 1.08
        buttonFlash = true

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 180_000_000)
            amountScale = 1
            iconScale = 1
            buttonFlash = false
        }
    }

    private func animateGoalReachedFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        goalReachedFlash = true

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 220_000_000)
            goalReachedFlash = false
        }
    }
}
