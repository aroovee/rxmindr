import SwiftUI
import HealthKit

struct HealthKitView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var adherenceStats: AdherenceStatistics?
    @State private var recentEntries: [MedicationAdherenceEntry] = []
    @State private var isLoading = false
    @State private var showingAuthAlert = false
    @State private var selectedPeriod = 30
    
    private let periodOptions = [7, 14, 30, 60, 90]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                DesignSystem.Gradients.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        if !healthKitManager.isAuthorized {
                            // Authorization Section
                            AuthorizationPromptCard {
                                Task {
                                    let success = await healthKitManager.requestAuthorization()
                                    if success {
                                        await loadHealthData()
                                    } else {
                                        showingAuthAlert = true
                                    }
                                }
                            }
                        } else {
                            // Period Selector
                            PeriodSelectorCard(selectedPeriod: $selectedPeriod) {
                                Task {
                                    await loadHealthData()
                                }
                            }
                            
                            if isLoading {
                                LoadingCard()
                            } else {
                                // Statistics Card
                                if let stats = adherenceStats {
                                    AdherenceStatisticsCard(statistics: stats)
                                    
                                    // Medication Breakdown
                                    MedicationBreakdownCard(statistics: stats)
                                }
                                
                                // Recent Activity
                                RecentActivityCard(entries: recentEntries)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Health Data")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if healthKitManager.isAuthorized {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Refresh") {
                            Task {
                                await loadHealthData()
                            }
                        }
                        .disabled(isLoading)
                    }
                }
            }
            .alert("HealthKit Authorization", isPresented: $showingAuthAlert) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enable HealthKit permissions in Settings to view health data.")
            }
        }
        .task {
            if healthKitManager.isAuthorized {
                await loadHealthData()
            }
        }
    }
    
    private func loadHealthData() async {
        isLoading = true
        
        async let stats = healthKitManager.fetchAdherenceStatistics(for: selectedPeriod)
        async let entries = healthKitManager.fetchMedicationAdherenceData(for: 14) // Last 14 days for recent activity
        
        let (fetchedStats, fetchedEntries) = await (stats, entries)
        
        await MainActor.run {
            self.adherenceStats = fetchedStats
            self.recentEntries = fetchedEntries
            self.isLoading = false
        }
    }
}

// MARK: - Supporting Views

struct AuthorizationPromptCard: View {
    let onAuthorize: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.success)
            
            VStack(spacing: 12) {
                Text("Connect to Health")
                    .font(DesignSystem.Typography.headingLarge(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Sync your medication adherence with Apple Health to track your progress and share data with healthcare providers.")
                    .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Connect to HealthKit") {
                onAuthorize()
            }
            .font(DesignSystem.Typography.bodyLarge(weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(DesignSystem.Colors.success)
            )
            .shadow(color: DesignSystem.Colors.success.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(24)
        .cardStyle()
    }
}

struct PeriodSelectorCard: View {
    @Binding var selectedPeriod: Int
    let onPeriodChanged: () -> Void
    
    private let periodOptions = [7, 14, 30, 60, 90]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time Period")
                .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(periodOptions, id: \.self) { period in
                        Button(action: {
                            selectedPeriod = period
                            onPeriodChanged()
                        }) {
                            Text("\(period) days")
                                .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                                .foregroundColor(selectedPeriod == period ? .white : DesignSystem.Colors.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedPeriod == period ? DesignSystem.Colors.primary : DesignSystem.Colors.primaryLight)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct AdherenceStatisticsCard: View {
    let statistics: AdherenceStatistics
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Adherence Overview")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Text("\(statistics.periodDays) days")
                    .font(DesignSystem.Typography.captionLarge(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            // Main Adherence Display
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(DesignSystem.Colors.cardBackground, lineWidth: 12)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0.0, to: statistics.adherenceRate / 100.0)
                        .stroke(
                            statistics.adherenceGrade.color,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: statistics.adherenceRate)
                    
                    VStack(spacing: 4) {
                        Text("\(Int(statistics.adherenceRate))%")
                            .font(DesignSystem.Typography.headingLarge(weight: .bold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text(statistics.adherenceGrade.rawValue)
                            .font(DesignSystem.Typography.captionMedium(weight: .medium))
                            .foregroundColor(statistics.adherenceGrade.color)
                    }
                }
                
                Text(statistics.adherenceGrade.description)
                    .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Stats Row
            HStack(spacing: 20) {
                StatItem(title: "Total Doses", value: "\(statistics.totalDoses)")
                StatItem(title: "Taken", value: "\(statistics.takenDoses)")
                StatItem(title: "Missed", value: "\(statistics.totalDoses - statistics.takenDoses)")
            }
        }
        .padding(24)
        .cardStyle()
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(DesignSystem.Typography.headingMedium(weight: .bold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(title)
                .font(DesignSystem.Typography.captionMedium(weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MedicationBreakdownCard: View {
    let statistics: AdherenceStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Medication Breakdown")
                .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if statistics.medicationBreakdown.isEmpty {
                Text("No medication data available for this period.")
                    .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.vertical, 20)
            } else {
                ForEach(Array(statistics.medicationBreakdown.sorted(by: { $0.value > $1.value })), id: \.key) { medication, adherenceRate in
                    MedicationAdherenceRow(
                        medicationName: medication,
                        adherenceRate: adherenceRate
                    )
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct MedicationAdherenceRow: View {
    let medicationName: String
    let adherenceRate: Double
    
    private var adherenceColor: Color {
        switch adherenceRate {
        case 90...100: return .green
        case 70..<90: return .blue
        case 50..<70: return .yellow
        default: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(medicationName)
                    .font(DesignSystem.Typography.bodyMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Text("\(Int(adherenceRate))%")
                    .font(DesignSystem.Typography.bodyMedium(weight: .bold))
                    .foregroundColor(adherenceColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DesignSystem.Colors.cardBackground)
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(adherenceColor)
                        .frame(width: geometry.size.width * (adherenceRate / 100), height: 6)
                        .cornerRadius(3)
                        .animation(.easeInOut(duration: 0.6), value: adherenceRate)
                }
            }
            .frame(height: 6)
        }
    }
}

struct RecentActivityCard: View {
    let entries: [MedicationAdherenceEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if entries.isEmpty {
                Text("No recent activity recorded.")
                    .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.vertical, 20)
            } else {
                ForEach(entries.prefix(10)) { entry in
                    ActivityRow(entry: entry)
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct ActivityRow: View {
    let entry: MedicationAdherenceEntry
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(entry.adherenceType.color.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: entry.adherenceType == .taken ? "checkmark" : "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(entry.adherenceType.color)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.medicationName)
                    .font(DesignSystem.Typography.bodyMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                if !entry.dosage.isEmpty {
                    Text(entry.dosage)
                        .font(DesignSystem.Typography.captionMedium(weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.adherenceType.displayName)
                    .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                    .foregroundColor(entry.adherenceType.color)
                
                Text(formatDate(entry.date))
                    .font(DesignSystem.Typography.captionMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct LoadingCard: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading health data...")
                .font(DesignSystem.Typography.bodyMedium(weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(40)
        .cardStyle()
    }
}

// Preview
struct HealthKitView_Previews: PreviewProvider {
    static var previews: some View {
        HealthKitView()
    }
}