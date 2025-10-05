import SwiftUI

struct MainTabView: View {
    @StateObject private var prescriptionStore = PrescriptionStore()
    @StateObject private var streakManager = StreakManager()
    @StateObject private var profileStore = ProfileStore()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                DashboardView(prescriptionStore: prescriptionStore, streakManager: streakManager, profileStore: profileStore)
            }
            .tabItem {
                Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                Text("Home")
            }
            .tag(0)
            
            NavigationView {
                PrescriptionListView(prescriptionStore: prescriptionStore)
            }
            .tabItem {
                ZStack {
                    Image(systemName: selectedTab == 1 ? "pills.fill" : "pills")
                    if prescriptionStore.interactionManager.hasActiveInteractions {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 8, y: -8)
                    }
                }
                Text("Medications")
            }
            .tag(1)
            
            NavigationView {
                StreakView(streakManager: streakManager)
            }
            .tabItem {
                Image(systemName: selectedTab == 2 ? "flame.fill" : "flame")
                Text("Streak")
            }
            .tag(2)
            
            NavigationView {
                ScanView(prescriptionStore: prescriptionStore)
            }
            .tabItem {
                Image(systemName: selectedTab == 3 ? "camera.fill" : "camera")
                Text("Scan")
            }
            .tag(3)
            
            NavigationView {
                MoreView(profileStore: profileStore)
            }
            .tabItem {
                Image(systemName: selectedTab == 4 ? "gear.badge.fill" : "gear")
                Text("More")
            }
            .tag(4)
        }
        .tint(DesignSystem.Colors.primary)
        .onAppear {
            streakManager.setRecordManager(prescriptionStore.recordManager)
            streakManager.updateStreak(for: prescriptionStore.prescriptions)
        }
        .onChange(of: prescriptionStore.prescriptions) {
            streakManager.updateStreak(for: prescriptionStore.prescriptions)
        }
    }
}

struct DashboardView: View {
    @ObservedObject var prescriptionStore: PrescriptionStore
    @ObservedObject var streakManager: StreakManager
    @ObservedObject var profileStore: ProfileStore
    @State private var currentDate = Date()
    @State private var showingProfiles = false
    
    private var todaysPrescriptions: [Prescription] {
        prescriptionStore.prescriptions.filter { prescription in
            let calendar = Calendar.current
            let today = currentDate
            
            return prescription.reminderTimes.contains { reminder in
                reminder.isEnabled && calendar.isDate(reminder.time, inSameDayAs: today)
            }
        }
    }
    
    private var upcomingPrescriptions: [Prescription] {
        let now = currentDate
        let calendar = Calendar.current
        
        // Get all active prescriptions (not taken today)
        let activePrescriptions = prescriptionStore.prescriptions.filter { prescription in
            // Only include if not taken today
            if let lastTaken = prescription.lastTaken,
               calendar.isDate(lastTaken, inSameDayAs: now) && prescription.isTaken {
                return false
            }
            
            // Check if there are any upcoming reminders today
            return prescription.reminderTimes.contains { reminder in
                reminder.isEnabled && calendar.isDate(reminder.time, inSameDayAs: now) && reminder.time > now
            }
        }
        
        return activePrescriptions.sorted { prescription1, prescription2 in
            let next1 = prescription1.reminderTimes
                .filter { $0.isEnabled && calendar.isDate($0.time, inSameDayAs: now) && $0.time > now }
                .min { $0.time < $1.time }?.time ?? Date.distantFuture
            let next2 = prescription2.reminderTimes
                .filter { $0.isEnabled && calendar.isDate($0.time, inSameDayAs: now) && $0.time > now }
                .min { $0.time < $1.time }?.time ?? Date.distantFuture
            return next1 < next2
        }
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 24) {
                StreakSummaryCard(streakManager: streakManager)
                TodaysSummaryCard(prescriptions: todaysPrescriptions)
                UpcomingMedicationsCard(prescriptions: upcomingPrescriptions, prescriptionStore: prescriptionStore)
                QuickActionsCard(prescriptionStore: prescriptionStore)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle(profileStore.currentProfile?.name.isEmpty == false ? "Hi, \(profileStore.currentProfile?.name ?? "")!" : "Welcome Back")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let currentProfile = profileStore.currentProfile {
                    Button(action: {
                        showingProfiles = true
                    }) {
                        Circle()
                            .fill(currentProfile.color.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: currentProfile.profileIcon)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(currentProfile.color)
                            )
                    }
                }
            }
        }
        .refreshable {
            currentDate = Date()
            streakManager.updateStreak(for: prescriptionStore.prescriptions)
        }
        .background(
            DesignSystem.Gradients.backgroundGradient
                .ignoresSafeArea()
        )
        .sheet(isPresented: $showingProfiles) {
            ProfilesView()
                .environmentObject(profileStore)
        }
    }
}

struct StreakSummaryCard: View {
    @ObservedObject var streakManager: StreakManager
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(colors: [DesignSystem.Colors.warning, DesignSystem.Colors.warning.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(height: 40)
                
                Text("\(streakManager.currentStreak)")
                    .font(DesignSystem.Typography.displaySmall(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Day Streak")
                    .font(DesignSystem.Typography.captionLarge(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer(minLength: 20)
            
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.md) {
                Text("Keep it up!")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Stay consistent with your routine")
                    .font(DesignSystem.Typography.captionLarge(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(Array(streakManager.weeklyProgress.enumerated()), id: \.offset) { index, completed in
                        Circle()
                            .frame(width: 12, height: 12)
                            .foregroundColor(completed ? DesignSystem.Colors.success : DesignSystem.Colors.neutral300)
                            .scaleEffect(completed ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3), value: completed)
                    }
                }
                .padding(.top, DesignSystem.Spacing.xs)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
        .padding(.vertical, DesignSystem.Spacing.xl)
        .cardStyle()
    }
}

struct TodaysSummaryCard: View {
    let prescriptions: [Prescription]
    
    private var completedCount: Int {
        prescriptions.filter { $0.isTaken }.count
    }
    
    private var totalCount: Int {
        prescriptions.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack(alignment: .center) {
                Text("Today's Wellness")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Text("\(completedCount)/\(totalCount)")
                    .font(DesignSystem.Typography.headingLarge(weight: .bold))
                    .foregroundColor(completedCount == totalCount && totalCount > 0 ? DesignSystem.Colors.success : DesignSystem.Colors.primary)
            }
            
            if totalCount > 0 {
                ProgressView(value: Double(completedCount), total: Double(totalCount))
                    .tint(completedCount == totalCount ? DesignSystem.Colors.success : DesignSystem.Colors.primary)
                    .background(DesignSystem.Colors.neutral200)
                    .clipShape(Capsule())
                    .scaleEffect(y: 1.4)
                    .animation(.easeInOut(duration: 0.3), value: completedCount)
            }
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: completedCount == totalCount && totalCount > 0 ? "heart.fill" : "leaf.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(completedCount == totalCount && totalCount > 0 ? DesignSystem.Colors.success : DesignSystem.Colors.secondary)
                
                Text(completedCount == totalCount && totalCount > 0 ? "Perfect! Your health routine is complete" : "\(totalCount - completedCount) more to go today")
                    .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
        .padding(.vertical, DesignSystem.Spacing.xl)
        .cardStyle()
    }
}

struct UpcomingMedicationsCard: View {
    let prescriptions: [Prescription]
    let prescriptionStore: PrescriptionStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Text("Coming Up")
                .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if prescriptions.isEmpty {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.secondary)
                    
                    Text("All set for today")
                        .font(DesignSystem.Typography.bodyMedium(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("Relax and enjoy your day!")
                        .font(DesignSystem.Typography.captionLarge(weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.lg)
            } else {
                VStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(prescriptions.prefix(3), id: \.id) { prescription in
                        UpcomingMedicationRow(prescription: prescription, prescriptionStore: prescriptionStore)
                    }
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
        .padding(.vertical, DesignSystem.Spacing.xl)
        .cardStyle()
    }
}

struct UpcomingMedicationRow: View {
    let prescription: Prescription
    let prescriptionStore: PrescriptionStore
    
    private var nextReminderTime: Date? {
        let now = Date()
        return prescription.reminderTimes
            .filter { $0.isEnabled && $0.time > now }
            .min { $0.time < $1.time }?.time
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            // Medication Icon
            Circle()
                .fill(DesignSystem.Gradients.secondaryGradient)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "capsule.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(prescription.name)
                    .font(DesignSystem.Typography.bodyMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                
                Text(prescription.dose)
                    .font(DesignSystem.Typography.captionLarge(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: DesignSystem.Spacing.md)
            
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                if let nextTime = nextReminderTime {
                    Text(formatTime(nextTime))
                        .font(DesignSystem.Typography.captionLarge(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.primary)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(DesignSystem.Colors.primaryLight)
                        )
                }
                
                Button("Take Now") {
                    prescriptionStore.markPrescriptionAsTaken(prescription)
                }
                .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(DesignSystem.Gradients.successGradient)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct QuickActionsCard: View {
    let prescriptionStore: PrescriptionStore
    @State private var showingAddPrescription = false
    @State private var showingScanner = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Text("Quick Actions")
                .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            HStack(spacing: DesignSystem.Spacing.lg) {
                QuickActionButton(
                    title: "Add",
                    subtitle: "New medication",
                    icon: "plus.circle.fill",
                    color: DesignSystem.Colors.primary
                ) {
                    showingAddPrescription = true
                }
                
                QuickActionButton(
                    title: "Scan",
                    subtitle: "Prescription label",
                    icon: "camera.fill",
                    color: DesignSystem.Colors.secondary
                ) {
                    showingScanner = true
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
        .padding(.vertical, DesignSystem.Spacing.xl)
        .cardStyle()
        .sheet(isPresented: $showingAddPrescription) {
            AddPrescriptionView(prescriptionStore: prescriptionStore)
        }
        .sheet(isPresented: $showingScanner) {
            ScanView(prescriptionStore: prescriptionStore)
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.md) {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(color)
                    )
                
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text(title)
                        .font(DesignSystem.Typography.bodyMedium(weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.captionMedium(weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.lg)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(color.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .strokeBorder(color.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
