import SwiftUI

struct TravelModeView: View {
    @ObservedObject var travelManager: TravelModeManager
    @State private var showingTravelSetup = false
    @State private var selectedTab = 0
    
    enum TravelTab: Int, CaseIterable {
        case overview = 0
        case medications = 1
        case checklist = 2
        case settings = 3
        
        var title: String {
            switch self {
            case .overview: return "Overview"
            case .medications: return "Medications"
            case .checklist: return "Checklist"
            case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .overview: return "airplane"
            case .medications: return "pills.fill"
            case .checklist: return "checklist"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                DesignSystem.Gradients.backgroundGradient
                    .ignoresSafeArea()
                
                if travelManager.isTravelModeActive {
                    // Unified travel interface with tabs
                    VStack(spacing: 0) {
                        // Custom tab picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                ForEach(TravelTab.allCases, id: \.rawValue) { tab in
                                    TravelTabButton(
                                        tab: tab,
                                        isSelected: selectedTab == tab.rawValue
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedTab = tab.rawValue
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 8)
                        
                        // Tab content
                        TabView(selection: $selectedTab) {
                            TravelOverviewTab(travelManager: travelManager)
                                .tag(0)
                            TravelMedicationsTab(travelManager: travelManager)
                                .tag(1)
                            TravelChecklistTab(travelManager: travelManager)
                                .tag(2)
                            TravelSettingsTab(travelManager: travelManager)
                                .tag(3)
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    }
                } else {
                    // Travel mode setup
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            TravelModeSetupCard {
                                showingTravelSetup = true
                            }
                            TravelBenefitsCard()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(travelManager.isTravelModeActive ? "Travel Mode" : "Travel Mode")
            .navigationBarTitleDisplayMode(travelManager.isTravelModeActive ? .inline : .large)
            .sheet(isPresented: $showingTravelSetup) {
                TravelSetupView(travelManager: travelManager)
            }
        }
    }
}

// MARK: - New Tab Components

struct TravelTabButton: View {
    let tab: TravelModeView.TravelTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(tab.title)
                    .font(DesignSystem.Typography.captionMedium(weight: isSelected ? .semibold : .medium))
            }
            .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? DesignSystem.Colors.primary.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TravelOverviewTab: View {
    @ObservedObject var travelManager: TravelModeManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if let travelPlan = travelManager.currentTravelPlan {
                    // Trip overview
                    ActiveTravelModeCard(travelPlan: travelPlan, travelManager: travelManager)
                    
                    // Quick stats
                    TravelQuickStatsCard(travelManager: travelManager)
                    
                    // Time zone comparison
                    TimeZoneOverviewCard(travelPlan: travelPlan, travelManager: travelManager)
                }
            }
            .padding()
        }
    }
}

struct TravelMedicationsTab: View {
    @ObservedObject var travelManager: TravelModeManager
    @State private var selectedMedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Sub-tabs for medications
            HStack(spacing: 0) {
                MedTabButton(title: "Essential", isSelected: selectedMedTab == 0) {
                    selectedMedTab = 0
                }
                MedTabButton(title: "All", isSelected: selectedMedTab == 1) {
                    selectedMedTab = 1
                }
                MedTabButton(title: "Packing", isSelected: selectedMedTab == 2) {
                    selectedMedTab = 2
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            TabView(selection: $selectedMedTab) {
                EssentialMedicationsContent(travelManager: travelManager)
                    .tag(0)
                AllMedicationsContent(travelManager: travelManager)
                    .tag(1)
                PackingListContent(travelManager: travelManager)
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
}

struct TravelChecklistTab: View {
    @ObservedObject var travelManager: TravelModeManager
    @StateObject private var checklistManager = TravelChecklistManager()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Progress overview
                ChecklistProgressCard(checklistManager: checklistManager)
                
                // Checklist sections
                ChecklistSection(title: "Before You Leave", icon: "house.fill", items: checklistManager.preTravelItems, checklistManager: checklistManager)
                ChecklistSection(title: "Packing", icon: "bag.fill", items: checklistManager.packingItems, checklistManager: checklistManager)
                ChecklistSection(title: "Travel Day", icon: "airplane", items: checklistManager.travelDayItems, checklistManager: checklistManager)
                ChecklistSection(title: "At Destination", icon: "location.fill", items: checklistManager.destinationItems, checklistManager: checklistManager)
            }
            .padding()
        }
        .onAppear {
            checklistManager.loadChecklistState()
        }
    }
}

struct TravelSettingsTab: View {
    @ObservedObject var travelManager: TravelModeManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if let travelPlan = travelManager.currentTravelPlan {
                    // Trip details card
                    TripDetailsCard(travelPlan: travelPlan)
                    
                    // Time zone adjustments
                    TimeZoneAdjustmentsCard(travelManager: travelManager) { }
                    
                    // End travel mode
                    EndTravelModeCard(travelManager: travelManager)
                }
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct TravelQuickStatsCard: View {
    @ObservedObject var travelManager: TravelModeManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Stats")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
            }
            
            HStack(spacing: 16) {
                QuickStatItem(
                    title: "Total Meds",
                    value: "\(travelManager.travelMedications.count)",
                    color: DesignSystem.Colors.primary
                )
                QuickStatItem(
                    title: "Essential",
                    value: "\(travelManager.travelMedications.filter { $0.isEssential }.count)",
                    color: DesignSystem.Colors.warning
                )
                QuickStatItem(
                    title: "Need Refill",
                    value: "\(travelManager.travelMedications.filter { $0.needsRefill }.count)",
                    color: DesignSystem.Colors.error
                )
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct QuickStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(DesignSystem.Typography.headingMedium(weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(DesignSystem.Typography.captionMedium(weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TimeZoneOverviewCard: View {
    let travelPlan: TravelPlan
    @ObservedObject var travelManager: TravelModeManager
    
    private var timeDifference: Int {
        (travelPlan.destinationTimeZone.secondsFromGMT() - TimeZone.current.secondsFromGMT()) / 3600
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.arrow.2.circlepath")
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .medium))
                
                Text("Time Adjustment")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            if timeDifference != 0 {
                Text("\(abs(timeDifference)) hours \(timeDifference > 0 ? "ahead" : "behind")")
                    .font(DesignSystem.Typography.bodyMedium(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text("\(travelManager.timeZoneAdjustments.count) medication reminders adjusted")
                    .font(DesignSystem.Typography.captionLarge(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            } else {
                Text("No time adjustment needed")
                    .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct MedTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.captionLarge(weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? DesignSystem.Colors.primary.opacity(0.1) : Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EssentialMedicationsContent: View {
    @ObservedObject var travelManager: TravelModeManager
    
    private var essentialMedications: [TravelMedication] {
        travelManager.travelMedications.filter { $0.isEssential }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if essentialMedications.isEmpty {
                    EmptyEssentialMedicationsView()
                } else {
                    ForEach(essentialMedications, id: \.id) { medication in
                        CompactMedicationCard(medication: medication)
                    }
                }
            }
            .padding()
        }
    }
}

struct AllMedicationsContent: View {
    @ObservedObject var travelManager: TravelModeManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(travelManager.travelMedications, id: \.id) { medication in
                    CompactMedicationCard(medication: medication)
                }
            }
            .padding()
        }
    }
}

struct PackingListContent: View {
    @ObservedObject var travelManager: TravelModeManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let travelPlan = travelManager.currentTravelPlan {
                    PackingChecklistCard(travelPlan: travelPlan, travelManager: travelManager)
                    TravelDocumentationCard()
                }
            }
            .padding()
        }
    }
}

struct CompactMedicationCard: View {
    let medication: TravelMedication
    
    var body: some View {
        HStack(spacing: 12) {
            // Essential indicator
            Circle()
                .fill(medication.isEssential ? DesignSystem.Colors.warning : DesignSystem.Colors.neutral300)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(medication.prescription.name)
                    .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Need \(medication.requiredQuantity) pills")
                    .font(DesignSystem.Typography.captionMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            if medication.needsRefill {
                Text("Refill")
                    .font(DesignSystem.Typography.captionSmall(weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(DesignSystem.Colors.error))
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignSystem.Colors.success)
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .padding(16)
        .cardStyle()
    }
}

struct TripDetailsCard: View {
    let travelPlan: TravelPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(DesignSystem.Colors.primary)
                    .font(.system(size: 16, weight: .medium))
                
                Text("Trip Details")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            VStack(spacing: 12) {
                DetailRow(label: "Destination", value: travelPlan.destination)
                DetailRow(label: "Duration", value: "\(travelPlan.durationInDays) days")
                DetailRow(label: "Type", value: travelPlan.isInternational ? "International" : "Domestic")
                
                if let notes = travelPlan.notes {
                    DetailRow(label: "Notes", value: notes)
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.captionLarge(weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.captionLarge(weight: .regular))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct EndTravelModeCard: View {
    @ObservedObject var travelManager: TravelModeManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "stop.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 20, weight: .medium))
                
                Text("End Travel Mode")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            Text("This will restore your original medication schedule and clear travel data.")
                .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Button(action: {
                travelManager.deactivateTravelMode()
            }) {
                Text("End Travel Mode")
                    .font(DesignSystem.Typography.bodyMedium(weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(.red)
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ActiveTravelModeCard: View {
    let travelPlan: TravelPlan
    @ObservedObject var travelManager: TravelModeManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "airplane")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Travel Mode Active")
                        .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("Destination: \(travelPlan.destination)")
                        .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(DesignSystem.Colors.success)
                    .frame(width: 12, height: 12)
            }
            
            // Trip details
            HStack(spacing: 20) {
                TripDetailItem(
                    title: "Duration",
                    value: "\(travelPlan.durationInDays) days",
                    icon: "calendar"
                )
                
                TripDetailItem(
                    title: "Time Zone",
                    value: travelPlan.destinationTimeZone.identifier.components(separatedBy: "/").last ?? "Unknown",
                    icon: "clock"
                )
                
                TripDetailItem(
                    title: "Type",
                    value: travelPlan.isInternational ? "International" : "Domestic",
                    icon: travelPlan.isInternational ? "globe" : "map"
                )
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct TripDetailItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(DesignSystem.Colors.primary)
            
            Text(value)
                .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(title)
                .font(DesignSystem.Typography.captionSmall(weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TravelMedicationsCard: View {
    @ObservedObject var travelManager: TravelModeManager
    let onViewAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "pills.fill")
                    .foregroundColor(DesignSystem.Colors.secondary)
                    .font(.system(size: 16, weight: .medium))
                
                Text("Travel Medications")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button("View All") {
                    onViewAll()
                }
                .font(DesignSystem.Typography.captionLarge(weight: .medium))
            }
            
            // Summary stats
            HStack(spacing: 16) {
                TravelMedStat(
                    title: "Total",
                    count: travelManager.travelMedications.count,
                    color: DesignSystem.Colors.primary
                )
                
                TravelMedStat(
                    title: "Essential",
                    count: travelManager.travelMedications.filter { $0.isEssential }.count,
                    color: DesignSystem.Colors.warning
                )
                
                TravelMedStat(
                    title: "Need Refill",
                    count: travelManager.travelMedications.filter { $0.needsRefill }.count,
                    color: DesignSystem.Colors.error
                )
            }
            
            // Top 3 essential medications preview
            let essentialMeds = travelManager.travelMedications.filter { $0.isEssential }.prefix(3)
            if !essentialMeds.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(essentialMeds), id: \.id) { medication in
                        TravelMedicationRow(medication: medication)
                    }
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct TravelMedStat: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(DesignSystem.Typography.headingMedium(weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(DesignSystem.Typography.captionMedium(weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TravelMedicationRow: View {
    let medication: TravelMedication
    
    var body: some View {
        HStack(spacing: 12) {
            // Essential indicator
            Circle()
                .fill(medication.isEssential ? DesignSystem.Colors.warning : DesignSystem.Colors.neutral300)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(medication.prescription.name)
                    .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Need \(medication.requiredQuantity) pills")
                    .font(DesignSystem.Typography.captionMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            if medication.needsRefill {
                Text("Refill Needed")
                    .font(DesignSystem.Typography.captionSmall(weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(DesignSystem.Colors.error)
                    )
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignSystem.Colors.success)
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignSystem.Colors.cardBackground)
        )
    }
}

struct TimeZoneAdjustmentsCard: View {
    @ObservedObject var travelManager: TravelModeManager
    let onViewAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.arrow.2.circlepath")
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .medium))
                
                Text("Time Zone Adjustments")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                if !travelManager.timeZoneAdjustments.isEmpty {
                    Button("View All") {
                        onViewAll()
                    }
                    .font(DesignSystem.Typography.captionLarge(weight: .medium))
                }
            }
            
            if !travelManager.timeZoneAdjustments.isEmpty {
                VStack(spacing: 8) {
                    ForEach(travelManager.timeZoneAdjustments.prefix(3)) { adjustment in
                        TimeZoneAdjustmentRow(adjustment: adjustment)
                    }
                    
                    if travelManager.timeZoneAdjustments.count > 3 {
                        Text("+\(travelManager.timeZoneAdjustments.count - 3) more adjustments")
                            .font(DesignSystem.Typography.captionMedium(weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .padding(.top, 4)
                    }
                }
            } else {
                Text("No reminder adjustments needed")
                    .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct TimeZoneAdjustmentRow: View {
    let adjustment: TimeZoneAdjustment
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(adjustment.prescriptionName)
                    .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(adjustment.adjustmentDescription)
                    .font(DesignSystem.Typography.captionMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            Text("\(adjustment.timeZoneDifference > 0 ? "+" : "")\(adjustment.timeZoneDifference)h")
                .font(DesignSystem.Typography.captionMedium(weight: .semibold))
                .foregroundColor(DesignSystem.Colors.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignSystem.Colors.cardBackground)
        )
    }
}

struct TravelChecklistCard: View {
    @ObservedObject var travelManager: TravelModeManager
    let onViewChecklist: () -> Void
    
    private var checklist: TravelChecklist {
        travelManager.generateTravelChecklist()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundColor(DesignSystem.Colors.success)
                    .font(.system(size: 16, weight: .medium))
                
                Text("Travel Checklist")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button("Open Checklist") {
                    onViewChecklist()
                }
                .font(DesignSystem.Typography.captionLarge(weight: .medium))
            }
            
            // Progress indicator
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Completion Progress")
                        .font(DesignSystem.Typography.captionLarge(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(Int(checklist.completionRate * 100))%")
                        .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(DesignSystem.Colors.neutral300)
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(DesignSystem.Colors.success)
                            .frame(width: geometry.size.width * checklist.completionRate, height: 6)
                            .cornerRadius(3)
                            .animation(.easeInOut(duration: 0.3), value: checklist.completionRate)
                    }
                }
                .frame(height: 6)
            }
            
            // Quick summary
            HStack(spacing: 16) {
                ChecklistStat(
                    title: "Total Items",
                    count: checklist.items.count,
                    color: DesignSystem.Colors.primary
                )
                
                ChecklistStat(
                    title: "Completed",
                    count: checklist.items.filter { $0.isCompleted }.count,
                    color: DesignSystem.Colors.success
                )
                
                ChecklistStat(
                    title: "High Priority",
                    count: checklist.items.filter { $0.priority == .high }.count,
                    color: DesignSystem.Colors.error
                )
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct ChecklistStat: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(DesignSystem.Typography.headingSmall(weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(DesignSystem.Typography.captionSmall(weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TravelModeSetupCard: View {
    let onSetup: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.primary)
            
            VStack(spacing: 12) {
                Text("Travel Mode")
                    .font(DesignSystem.Typography.headingLarge(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Automatically adjust your medication reminders for travel, generate packing lists, and track essential medications.")
                    .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onSetup) {
                Text("Setup Travel Mode")
                    .font(DesignSystem.Typography.bodyLarge(weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(DesignSystem.Colors.primary)
                    )
                    .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(40)
        .cardStyle()
    }
}

struct TravelBenefitsCard: View {
    private let benefits = [
        ("clock.arrow.2.circlepath", "Automatic Time Zone Adjustment", "Reminders adjust to destination time"),
        ("list.clipboard", "Smart Packing Lists", "Know exactly what medications to pack"),
        ("exclamationmark.triangle", "Refill Alerts", "Get notified if you need refills before travel"),
        ("doc.text", "Documentation Helper", "Generate prescription letters for international travel")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Travel Mode Benefits")
                .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            VStack(spacing: 12) {
                ForEach(0..<benefits.count, id: \.self) { index in
                    let benefit = benefits[index]
                    BenefitRow(icon: benefit.0, title: benefit.1, description: benefit.2)
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(description)
                    .font(DesignSystem.Typography.captionMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
}


// Preview
struct TravelModeView_Previews: PreviewProvider {
    static var previews: some View {
        TravelModeView(travelManager: TravelModeManager(prescriptionStore: PrescriptionStore.shared))
    }
}