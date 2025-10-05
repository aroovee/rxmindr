import SwiftUI

struct ModernDashboardView: View {
    @StateObject private var prescriptionStore = PrescriptionStore()
    @StateObject private var profileStore = ProfileStore()
    
    @State private var selectedTab = 0
    @State private var showingAddPrescription = false
    @State private var searchText = ""
    
    private let currentDate = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with modern gradient
                DesignSystem.Gradients.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: DesignSystem.Spacing.xl) {
                        // Hero section with user greeting
                        heroSection
                        
                        // Quick stats cards
                        quickStatsSection
                        
                        // Today's medications
                        todaysMedicationsSection
                        
                        // Upcoming reminders
                        upcomingRemindersSection
                        
                        // Health insights
                        healthInsightsSection
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, DesignSystem.Spacing.xxxl)
                }
                .refreshable {
                    await refreshData()
                }
                
                // Floating action button
                floatingActionButton
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddPrescription) {
                AddPrescriptionView(prescriptionStore: prescriptionStore)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func refreshData() async {
        // Simulate network delay for refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Force refresh by triggering observers
        prescriptionStore.objectWillChange.send()
        profileStore.objectWillChange.send()
    }
    
    private var heroSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Header with profile and notifications
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(greetingMessage)
                        .font(DesignSystem.Typography.headingLarge(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text(profileStore.currentProfile?.name ?? "User")
                        .font(DesignSystem.Typography.displayMedium(weight: .bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                Spacer()
                
                HStack(spacing: DesignSystem.Spacing.md) {
                    // Notification bell with badge
                    notificationButton
                    
                    // Profile avatar
                    profileAvatar
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.xl)
            
            // Main health status card
            mainHealthCard
        }
    }
    
    private var mainHealthCard: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Today's Health Status")
                        .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(currentDate.formatted(date: .complete, time: .omitted))
                        .font(DesignSystem.Typography.bodyMedium(weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Health score
                healthScoreIndicator
            }
            
            // Progress indicators
            healthProgressBars
        }
        .padding(DesignSystem.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(DesignSystem.Gradients.heroGradient)
                .shadow(
                    color: DesignSystem.Colors.primary.opacity(0.3),
                    radius: 20,
                    x: 0,
                    y: 10
                )
        )
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack {
                Text("Quick Stats")
                    .font(DesignSystem.Typography.headingLarge(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to detailed stats
                }
                .font(DesignSystem.Typography.bodyMedium(weight: .medium))
                .foregroundColor(DesignSystem.Colors.primary)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.lg) {
                    DashboardStatCard(
                        title: "Medications",
                        value: "\(prescriptionStore.prescriptions.count)",
                        subtitle: "Active prescriptions",
                        icon: "pills.fill",
                        color: DesignSystem.Colors.primary
                    )
                    
                    DashboardStatCard(
                        title: "Adherence",
                        value: "\(Int(adherencePercentage))%",
                        subtitle: "This week",
                        icon: "chart.line.uptrend.xyaxis",
                        color: DesignSystem.Colors.success
                    )
                    
                    DashboardStatCard(
                        title: "Streak",
                        value: "12",
                        subtitle: "Days in a row",
                        icon: "flame.fill",
                        color: DesignSystem.Colors.warning
                    )
                    
                    DashboardStatCard(
                        title: "Next Refill",
                        value: "3",
                        subtitle: "Days remaining",
                        icon: "calendar.badge.exclamationmark",
                        color: DesignSystem.Colors.error
                    )
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
            }
        }
    }
    
    private var todaysMedicationsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack {
                Text("Today's Medications")
                    .font(DesignSystem.Typography.headingLarge(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Text("\(takenCount)/\(totalMedicationsToday) taken")
                    .font(DesignSystem.Typography.bodyMedium(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(DesignSystem.Colors.neutral100)
                    )
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            
            LazyVStack(spacing: DesignSystem.Spacing.md) {
                ForEach(todaysPrescriptions) { prescription in
                    ModernPrescriptionCard(
                        prescription: prescription,
                        onTap: {
                            // Navigate to prescription details
                        },
                        onMarkTaken: {
                            withAnimation(.spring()) {
                                prescriptionStore.markPrescriptionAsTaken(prescription)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
    }
    
    private var upcomingRemindersSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack {
                Text("Upcoming Reminders")
                    .font(DesignSystem.Typography.headingLarge(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            
            VStack(spacing: DesignSystem.Spacing.md) {
                ForEach(upcomingReminders.prefix(3), id: \.id) { reminder in
                    ReminderCard(reminder: reminder)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
    }
    
    private var healthInsightsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack {
                Text("Health Insights")
                    .font(DesignSystem.Typography.headingLarge(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button("See All") {
                    // Navigate to insights
                }
                .font(DesignSystem.Typography.bodyMedium(weight: .medium))
                .foregroundColor(DesignSystem.Colors.primary)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            
            VStack(spacing: DesignSystem.Spacing.md) {
                InsightCard(
                    icon: "heart.fill",
                    title: "Great Adherence!",
                    description: "You've taken 95% of your medications this week. Keep up the excellent work!",
                    color: DesignSystem.Colors.success
                )
                
                InsightCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Refill Reminder",
                    description: "Your Lisinopril prescription needs to be refilled in 3 days.",
                    color: DesignSystem.Colors.warning
                )
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
    }
    
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(action: { showingAddPrescription = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(DesignSystem.Gradients.primaryGradient)
                                .shadow(
                                    color: DesignSystem.Colors.primary.opacity(0.4),
                                    radius: 12,
                                    x: 0,
                                    y: 8
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, DesignSystem.Spacing.xl)
                .padding(.bottom, DesignSystem.Spacing.xxxl)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var notificationButton: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            Image(systemName: "bell.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            // Notification badge
            if hasUnreadNotifications {
                Circle()
                    .fill(DesignSystem.Colors.error)
                    .frame(width: 8, height: 8)
                    .offset(x: 10, y: -10)
            }
        }
    }
    
    private var profileAvatar: some View {
        ZStack {
            Circle()
                .fill(profileStore.currentProfile?.color ?? DesignSystem.Colors.primary)
                .frame(width: 44, height: 44)
            
            if let profile = profileStore.currentProfile {
                Image(systemName: profile.profileIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .shadow(
            color: (profileStore.currentProfile?.color ?? DesignSystem.Colors.primary).opacity(0.3),
            radius: 8,
            x: 0,
            y: 4
        )
    }
    
    private var healthScoreIndicator: some View {
        VStack(alignment: .center, spacing: DesignSystem.Spacing.xs) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: healthScore / 100)
                    .stroke(
                        Color.white,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: healthScore)
                
                Text("\(Int(healthScore))")
                    .font(DesignSystem.Typography.headingMedium(weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("Health Score")
                .font(DesignSystem.Typography.captionLarge(weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private var healthProgressBars: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            ProgressIndicator(
                title: "Medications",
                progress: Double(takenCount) / max(Double(totalMedicationsToday), 1.0),
                color: .white
            )
            
            ProgressIndicator(
                title: "Adherence",
                progress: adherencePercentage / 100,
                color: .white
            )
            
            ProgressIndicator(
                title: "Goals",
                progress: 0.85,
                color: .white
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: currentDate)
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    private var todaysPrescriptions: [Prescription] {
        prescriptionStore.prescriptions
    }
    
    private var takenCount: Int {
        prescriptionStore.prescriptions.filter { $0.isTaken }.count
    }
    
    private var totalMedicationsToday: Int {
        prescriptionStore.prescriptions.count
    }
    
    private var adherencePercentage: Double {
        guard totalMedicationsToday > 0 else { return 100 }
        return (Double(takenCount) / Double(totalMedicationsToday)) * 100
    }
    
    private var healthScore: Double {
        let baseScore = adherencePercentage
        // Add other health factors here
        return min(baseScore, 100)
    }
    
    private var hasUnreadNotifications: Bool {
        // Check for unread notifications
        return false
    }
    
    private var upcomingReminders: [Prescription] {
        prescriptionStore.prescriptions.filter { !$0.isTaken }
    }
}

// MARK: - Supporting Views

struct DashboardStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(value)
                    .font(DesignSystem.Typography.displaySmall(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(title)
                    .font(DesignSystem.Typography.bodyMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.captionLarge(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            
            Spacer()
        }
        .frame(width: 160, height: 120)
        .padding(DesignSystem.Spacing.lg)
        .modernCard(elevation: .minimal)
    }
}

struct ProgressIndicator: View {
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text(title)
                    .font(DesignSystem.Typography.captionLarge(weight: .medium))
                    .foregroundColor(color.opacity(0.8))
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(DesignSystem.Typography.captionLarge(weight: .bold))
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                        .fill(color.opacity(0.3))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 4)
        }
    }
}

struct ReminderCard: View {
    let reminder: Prescription
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Time indicator
            VStack {
                Text(timeFormatter.string(from: reminder.reminderTimes.first?.time ?? Date()))
                    .font(DesignSystem.Typography.bodyMedium(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Rectangle()
                    .fill(DesignSystem.Colors.primary.opacity(0.3))
                    .frame(width: 2, height: 30)
                    .cornerRadius(1)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(reminder.name)
                    .font(DesignSystem.Typography.bodyMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("\(reminder.dose) • \(reminder.frequency)")
                    .font(DesignSystem.Typography.captionLarge(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            Button("Take") {
                // Mark as taken
            }
            .font(DesignSystem.Typography.captionLarge(weight: .semibold))
            .foregroundColor(DesignSystem.Colors.primary)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                Capsule()
                    .fill(DesignSystem.Colors.primaryLight)
            )
        }
        .padding(DesignSystem.Spacing.lg)
        .modernCard(elevation: .minimal)
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

struct InsightCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.bodyLarge(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(description)
                    .font(DesignSystem.Typography.bodyMedium(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.lg)
        .modernCard(elevation: .minimal)
    }
}

#Preview {
    ModernDashboardView()
}