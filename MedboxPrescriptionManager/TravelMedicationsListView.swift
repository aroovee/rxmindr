import SwiftUI

struct TravelMedicationsListView: View {
    @ObservedObject var travelManager: TravelModeManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom tab picker
                HStack(spacing: 0) {
                    TabButton(title: "Essential", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    
                    TabButton(title: "All Medications", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                    
                    TabButton(title: "Packing List", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                TabView(selection: $selectedTab) {
                    // Essential Medications
                    EssentialMedicationsTab(travelManager: travelManager)
                        .tag(0)
                    
                    // All Medications  
                    AllMedicationsTab(travelManager: travelManager)
                        .tag(1)
                    
                    // Packing List
                    PackingListTab(travelManager: travelManager)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Travel Medications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TabButton: View {
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

struct EssentialMedicationsTab: View {
    @ObservedObject var travelManager: TravelModeManager
    
    private var essentialMedications: [Prescription] {
        travelManager.prescriptionStore?.prescriptions.filter { $0.isEssentialForTravel } ?? []
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if essentialMedications.isEmpty {
                    EmptyEssentialMedicationsView()
                } else {
                    // Summary Card
                    EssentialMedicationsSummary(medications: essentialMedications, travelManager: travelManager)
                    
                    // Essential medications list
                    ForEach(essentialMedications, id: \.id) { prescription in
                        TravelMedicationCard(
                            prescription: prescription,
                            travelManager: travelManager,
                            showEssentialToggle: false
                        )
                    }
                }
            }
            .padding()
        }
    }
}

struct AllMedicationsTab: View {
    @ObservedObject var travelManager: TravelModeManager
    
    private var allMedications: [Prescription] {
        travelManager.prescriptionStore?.prescriptions ?? []
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if allMedications.isEmpty {
                    EmptyMedicationsView()
                } else {
                    ForEach(allMedications, id: \.id) { prescription in
                        TravelMedicationCard(
                            prescription: prescription,
                            travelManager: travelManager,
                            showEssentialToggle: true
                        )
                    }
                }
            }
            .padding()
        }
    }
}

struct PackingListTab: View {
    @ObservedObject var travelManager: TravelModeManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let travelPlan = travelManager.currentTravelPlan {
                    PackingChecklistCard(travelPlan: travelPlan, travelManager: travelManager)
                    TravelDocumentationCard()
                    EmergencyContactCard()
                } else {
                    Text("No active travel mode")
                        .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(40)
                }
            }
            .padding()
        }
    }
}

struct TravelMedicationCard: View {
    let prescription: Prescription
    @ObservedObject var travelManager: TravelModeManager
    let showEssentialToggle: Bool
    
    private var medicationsNeeded: Int {
        guard let travelPlan = travelManager.currentTravelPlan else { return 0 }
        let duration = travelPlan.endDate.timeIntervalSince(travelPlan.startDate)
        let days = Int(duration / (24 * 60 * 60)) + 1 // Add extra day
        return days * prescription.dailyFrequency
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prescription.name)
                        .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("\(prescription.dose) • \(prescription.dailyFrequency)x daily")
                        .font(DesignSystem.Typography.captionLarge(weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                if showEssentialToggle {
                    Button(action: {
                        toggleEssentialStatus()
                    }) {
                        Image(systemName: prescription.isEssentialForTravel ? "heart.fill" : "heart")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(prescription.isEssentialForTravel ? .red : DesignSystem.Colors.textSecondary)
                    }
                }
            }
            
            // Travel calculation
            VStack(spacing: 12) {
                HStack {
                    Text("Needed for Trip:")
                        .font(DesignSystem.Typography.captionLarge(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(medicationsNeeded) pills")
                        .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                if let pillsRemaining = prescription.pillsRemaining {
                    HStack {
                        Text("Available:")
                            .font(DesignSystem.Typography.captionLarge(weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Spacer()
                        
                        Text("\(pillsRemaining) pills")
                            .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                            .foregroundColor(pillsRemaining >= medicationsNeeded ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                    }
                }
                
                // Status indicator
                HStack(spacing: 8) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(statusColor)
                    
                    Text(statusText)
                        .font(DesignSystem.Typography.captionMedium(weight: .medium))
                        .foregroundColor(statusColor)
                    
                    Spacer()
                }
            }
            
            // Travel notes if available
            if let notes = prescription.travelNotes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Travel Notes:")
                        .font(DesignSystem.Typography.captionMedium(weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text(notes)
                        .font(DesignSystem.Typography.captionMedium(weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DesignSystem.Colors.primary.opacity(0.05))
                )
            }
        }
        .padding(16)
        .cardStyle()
    }
    
    private var statusIcon: String {
        guard let pillsRemaining = prescription.pillsRemaining else { return "questionmark.circle" }
        
        if pillsRemaining >= medicationsNeeded {
            return "checkmark.circle.fill"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var statusColor: Color {
        guard let pillsRemaining = prescription.pillsRemaining else { return DesignSystem.Colors.warning }
        
        if pillsRemaining >= medicationsNeeded {
            return DesignSystem.Colors.success
        } else {
            return DesignSystem.Colors.error
        }
    }
    
    private var statusText: String {
        guard let pillsRemaining = prescription.pillsRemaining else { return "Inventory unknown" }
        
        if pillsRemaining >= medicationsNeeded {
            return "Sufficient supply"
        } else {
            let shortage = medicationsNeeded - pillsRemaining
            return "Need \(shortage) more pills"
        }
    }
    
    private func toggleEssentialStatus() {
        guard let prescriptionStore = travelManager.prescriptionStore else { return }
        prescriptionStore.updatePrescription(Prescription(
            id: prescription.id,
            name: prescription.name,
            dose: prescription.dose,
            frequency: prescription.frequency,
            dailyFrequency: prescription.dailyFrequency,
            startDate: prescription.startDate,
            endDate: prescription.endDate,
            reminderTimes: prescription.reminderTimes,
            isTaken: prescription.isTaken,
            lastTaken: prescription.lastTaken,
            hasConflicts: prescription.hasConflicts,
            conflicts: prescription.conflicts,
            drugInfo: prescription.drugInfo,
            totalPills: prescription.totalPills,
            pillsRemaining: prescription.pillsRemaining,
            refillDate: prescription.refillDate,
            prescriptionNumber: prescription.prescriptionNumber,
            pharmacy: prescription.pharmacy,
            physicianName: prescription.physicianName,
            isEssentialForTravel: !prescription.isEssentialForTravel,
            travelNotes: prescription.travelNotes
        ))
    }
}

struct EssentialMedicationsSummary: View {
    let medications: [Prescription]
    @ObservedObject var travelManager: TravelModeManager
    
    private var totalMedicationsNeeded: Int {
        guard let travelPlan = travelManager.currentTravelPlan else { return 0 }
        let duration = travelPlan.endDate.timeIntervalSince(travelPlan.startDate)
        let days = Int(duration / (24 * 60 * 60)) + 1
        
        return medications.reduce(0) { total, prescription in
            total + (days * prescription.dailyFrequency)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Essential Medications")
                        .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("\(medications.count) medication\(medications.count == 1 ? "" : "s") marked as essential")
                        .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
            }
            
            // Summary stats
            HStack(spacing: 20) {
                SummaryStatItem(
                    title: "Medications",
                    value: "\(medications.count)",
                    color: DesignSystem.Colors.primary
                )
                
                SummaryStatItem(
                    title: "Pills Needed",
                    value: "\(totalMedicationsNeeded)",
                    color: DesignSystem.Colors.success
                )
                
                SummaryStatItem(
                    title: "Days Covered",
                    value: travelDaysText,
                    color: DesignSystem.Colors.warning
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
    
    private var travelDaysText: String {
        guard let travelPlan = travelManager.currentTravelPlan else { return "0" }
        let duration = travelPlan.endDate.timeIntervalSince(travelPlan.startDate)
        let days = Int(duration / (24 * 60 * 60)) + 1
        return "\(days)"
    }
}

struct SummaryStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(DesignSystem.Typography.headingLarge(weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(DesignSystem.Typography.captionMedium(weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct EmptyEssentialMedicationsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            VStack(spacing: 8) {
                Text("No Essential Medications")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Mark medications as essential for travel by tapping the heart icon on the All Medications tab.")
                    .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .cardStyle()
    }
}

struct EmptyMedicationsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pills")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            VStack(spacing: 8) {
                Text("No Medications")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Add medications to create your travel medication list.")
                    .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .cardStyle()
    }
}

struct PackingChecklistCard: View {
    let travelPlan: TravelPlan
    @ObservedObject var travelManager: TravelModeManager
    @State private var checkedItems: Set<String> = []
    
    private var checklistItems: [String] {
        [
            "Pack medications in carry-on bag",
            "Bring extra supply (2-3 days worth)",
            "Keep original prescription bottles",
            "Pack pill organizer if needed",
            "Bring prescription copies",
            "Check medication restrictions for destination",
            "Set up medication reminders for new time zone",
            "Bring doctor's letter if needed"
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text("Packing Checklist")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(checklistItems, id: \.self) { item in
                    ChecklistRow(
                        text: item,
                        isChecked: checkedItems.contains(item)
                    ) {
                        if checkedItems.contains(item) {
                            checkedItems.remove(item)
                        } else {
                            checkedItems.insert(item)
                        }
                    }
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct ChecklistRow: View {
    let text: String
    let isChecked: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isChecked ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary)
                
                Text(text)
                    .font(DesignSystem.Typography.captionLarge(weight: .regular))
                    .foregroundColor(isChecked ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                    .strikethrough(isChecked)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TravelDocumentationCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text("Travel Documentation")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                DocumentationItem(
                    title: "Prescription Copies",
                    description: "Keep copies of all prescriptions in case of loss"
                )
                
                DocumentationItem(
                    title: "Doctor's Letter",
                    description: "Letter explaining medical necessity for controlled substances"
                )
                
                DocumentationItem(
                    title: "Insurance Cards",
                    description: "Health insurance and travel insurance information"
                )
                
                DocumentationItem(
                    title: "Emergency Contacts",
                    description: "Doctor and pharmacy contact information"
                )
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct DocumentationItem: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(description)
                .font(DesignSystem.Typography.captionMedium(weight: .regular))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct EmergencyContactCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "phone.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.red)
                
                Text("Emergency Contacts")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            Text("Save these contacts before traveling:")
                .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• Your doctor's emergency number")
                Text("• Pharmacy contact information")
                Text("• Travel insurance helpline")
                Text("• Local emergency services (911 equivalent)")
            }
            .font(DesignSystem.Typography.captionLarge(weight: .regular))
            .foregroundColor(DesignSystem.Colors.textPrimary)
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

struct TravelMedicationsListView_Previews: PreviewProvider {
    static var previews: some View {
        TravelMedicationsListView(travelManager: TravelModeManager(prescriptionStore: PrescriptionStore.shared))
    }
}