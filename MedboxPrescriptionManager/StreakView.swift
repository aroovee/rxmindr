import SwiftUI

struct StreakView: View {
    @ObservedObject var streakManager: StreakManager
    @StateObject private var recordManager = MedicationRecordManager()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                StreakHeaderView(streak: streakManager, recordManager: recordManager)
                WeeklyProgressView(streak: streakManager)
                StreakStatsView(streak: streakManager)
            }
            .padding()
        }
        .navigationTitle("Wellness Streak")
        .background(
            DesignSystem.Gradients.backgroundGradient
                .ignoresSafeArea()
        )
    }
}

struct StreakHeaderView: View {
    @ObservedObject var streak: StreakManager
    let recordManager: MedicationRecordManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: DesignSystem.Spacing.xl) {
                Circle()
                    .fill(DesignSystem.Gradients.warningGradient)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "flame.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .shadow(color: DesignSystem.Colors.warning.opacity(0.3), radius: 8, x: 0, y: 4)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("\(streak.currentStreak)")
                        .font(DesignSystem.Typography.heroDisplay(weight: .black, family: .avenir))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(streak.currentStreak == 1 ? "Day Streak" : "Days Strong")
                        .font(DesignSystem.Typography.titleMedium(weight: .medium, family: .avenir))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                // Calendar Navigation Link
                NavigationLink(destination: CalendarOnlyView(recordManager: recordManager)) {
                    Circle()
                        .fill(DesignSystem.Colors.primaryLight)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "calendar")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.primary)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(DesignSystem.Colors.primary.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            
            if streak.currentStreak > 0, let startDate = streak.streakStartDate {
                Text("Journey began \(formatDate(startDate))")
                    .font(DesignSystem.Typography.statusText())
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(DesignSystem.Colors.neutral100)
                    )
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .cardStyle()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct WeeklyProgressView: View {
    @ObservedObject var streak: StreakManager
    
    private let days = ["M", "T", "W", "T", "F", "S", "S"]
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            HStack {
                Text("Weekly Progress")
                    .font(DesignSystem.Typography.titleMedium(weight: .semibold, family: .avenir))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Text("\(Int(streak.getWeeklyCompletionRate() * 100))%")
                    .font(DesignSystem.Typography.titleMedium(weight: .bold, family: .avenir))
                    .foregroundColor(streak.getWeeklyCompletionRate() > 0.7 ? DesignSystem.Colors.success : DesignSystem.Colors.warning)
            }
            
            HStack(spacing: DesignSystem.Spacing.md) {
                DayProgressView(day: "M", index: 0, streak: streak)
                DayProgressView(day: "T", index: 1, streak: streak)
                DayProgressView(day: "W", index: 2, streak: streak)
                DayProgressView(day: "T", index: 3, streak: streak)
                DayProgressView(day: "F", index: 4, streak: streak)
                DayProgressView(day: "S", index: 5, streak: streak)
                DayProgressView(day: "S", index: 6, streak: streak)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .cardStyle()
    }
}

struct StreakStatsView: View {
    @ObservedObject var streak: StreakManager
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Text("Your Journey")
                .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignSystem.Spacing.lg) {
                StatCard(
                    title: "Best Streak",
                    value: "\(streak.longestStreak)",
                    subtitle: streak.longestStreak == 1 ? "day" : "days",
                    icon: "crown.fill",
                    color: DesignSystem.Colors.warning
                )
                
                StatCard(
                    title: "Total Days",
                    value: "\(streak.totalDaysTaken)",
                    subtitle: "completed",
                    icon: "calendar.badge.checkmark",
                    color: DesignSystem.Colors.primary
                )
            }
            
            if streak.currentStreak >= streak.longestStreak && streak.currentStreak > 0 {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .foregroundColor(DesignSystem.Colors.warning)
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("New personal record!")
                        .font(DesignSystem.Typography.statusText())
                        .foregroundColor(DesignSystem.Colors.warning)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    Capsule()
                        .fill(DesignSystem.Colors.warningLight)
                )
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .cardStyle()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                )
            
            Text(value)
                .font(DesignSystem.Typography.displaySmall(weight: .bold, family: .avenir))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.statusText())
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.bodySmall(weight: .regular, family: .sfPro))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(color.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .strokeBorder(color.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct DayProgressView: View {
    let day: String
    let index: Int
    @ObservedObject var streak: StreakManager
    
    private var isCompleted: Bool {
        guard index >= 0 && index < streak.weeklyProgress.count else { return false }
        return streak.weeklyProgress[index]
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Circle()
                .fill(isCompleted ? DesignSystem.Colors.success : DesignSystem.Colors.neutral300)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .strokeBorder(
                            isCompleted ? DesignSystem.Colors.success : DesignSystem.Colors.neutral400,
                            lineWidth: 2
                        )
                )
                .scaleEffect(isCompleted ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCompleted)
            
            Text(day)
                .font(DesignSystem.Typography.captionLarge(weight: .medium))
                .foregroundColor(isCompleted ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Calendar Only View (without NavigationView wrapper)
struct CalendarOnlyView: View {
    @ObservedObject var recordManager: MedicationRecordManager
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var showingDateDetail = false
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        ZStack {
            // Background gradient
            DesignSystem.Gradients.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Calendar Header Card
                    CalendarHeaderCard(
                        currentMonth: $currentMonth,
                        recordManager: recordManager,
                        dateFormatter: dateFormatter
                    )
                    
                    // Calendar Grid Card
                    CalendarGridCard(
                        currentMonth: $currentMonth,
                        selectedDate: $selectedDate,
                        showingDateDetail: $showingDateDetail,
                        recordManager: recordManager
                    )
                    
                    // Legend Card
                    AdherenceLegendCard()
                    
                    // Monthly Statistics Card
                    MonthlyStatsCard(
                        currentMonth: currentMonth,
                        recordManager: recordManager
                    )
                }
                .padding()
            }
        }
        .navigationTitle("Wellness Calendar")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingDateDetail) {
            DayDetailView(
                date: selectedDate,
                recordManager: recordManager
            )
        }
    }
}