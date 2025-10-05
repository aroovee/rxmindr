import SwiftUI

struct TravelChecklistView: View {
    @ObservedObject var travelManager: TravelModeManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var checklistManager = TravelChecklistManager()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if let travelPlan = travelManager.currentTravelPlan {
                        
                        // Progress Card
                        ChecklistProgressCard(checklistManager: checklistManager)
                        
                        // Pre-Travel Checklist
                        ChecklistSection(
                            title: "Before You Leave",
                            icon: "house.fill",
                            items: checklistManager.preTravelItems,
                            checklistManager: checklistManager
                        )
                        
                        // Packing Checklist
                        ChecklistSection(
                            title: "Packing",
                            icon: "bag.fill",
                            items: checklistManager.packingItems,
                            checklistManager: checklistManager
                        )
                        
                        // Travel Day Checklist
                        ChecklistSection(
                            title: "Travel Day",
                            icon: "airplane",
                            items: checklistManager.travelDayItems,
                            checklistManager: checklistManager
                        )
                        
                        // At Destination Checklist
                        ChecklistSection(
                            title: "At Destination",
                            icon: "location.fill",
                            items: checklistManager.destinationItems,
                            checklistManager: checklistManager
                        )
                        
                    } else {
                        EmptyTravelChecklistView()
                    }
                }
                .padding()
            }
            .navigationTitle("Travel Checklist")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        checklistManager.resetAllItems()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            checklistManager.loadChecklistState()
        }
    }
}

struct ChecklistProgressCard: View {
    @ObservedObject var checklistManager: TravelChecklistManager
    
    private var completionPercentage: Double {
        let totalItems = checklistManager.allItems.count
        let completedItems = checklistManager.checkedItems.count
        return totalItems > 0 ? Double(completedItems) / Double(totalItems) : 0.0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.success)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Travel Preparation")
                        .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("\(checklistManager.checkedItems.count) of \(checklistManager.allItems.count) items completed")
                        .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                Text("\(Int(completionPercentage * 100))%")
                    .font(DesignSystem.Typography.headingLarge(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DesignSystem.Colors.neutral300)
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(DesignSystem.Colors.success)
                        .frame(width: geometry.size.width * completionPercentage, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 0.3), value: completionPercentage)
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .cardStyle()
    }
}

struct ChecklistSection: View {
    let title: String
    let icon: String
    let items: [ChecklistItem]
    @ObservedObject var checklistManager: TravelChecklistManager
    
    private var completedCount: Int {
        items.filter { checklistManager.checkedItems.contains($0.id) }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text(title)
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Text("\(completedCount)/\(items.count)")
                    .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                    .foregroundColor(completedCount == items.count ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary)
            }
            
            VStack(spacing: 12) {
                ForEach(items) { item in
                    ChecklistItemRow(
                        item: item,
                        isChecked: checklistManager.checkedItems.contains(item.id)
                    ) {
                        checklistManager.toggleItem(item.id)
                    }
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct ChecklistItemRow: View {
    let item: ChecklistItem
    let isChecked: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isChecked ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(DesignSystem.Typography.captionLarge(weight: .medium))
                        .foregroundColor(isChecked ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                        .strikethrough(isChecked)
                        .multilineTextAlignment(.leading)
                    
                    if let description = item.description {
                        Text(description)
                            .font(DesignSystem.Typography.captionMedium(weight: .regular))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer()
                
                if item.priority == .high {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyTravelChecklistView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            VStack(spacing: 8) {
                Text("No Active Travel Mode")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Start travel mode to access your personalized travel checklist.")
                    .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .cardStyle()
    }
}

// MARK: - Supporting Classes

class TravelChecklistManager: ObservableObject {
    @Published var checkedItems: Set<String> = []
    
    private let userDefaults = UserDefaults.standard
    private let checklistKey = "TravelChecklistState"
    
    var allItems: [ChecklistItem] {
        preTravelItems + packingItems + travelDayItems + destinationItems
    }
    
    let preTravelItems: [ChecklistItem] = [
        ChecklistItem(
            id: "refill_prescriptions",
            title: "Refill all prescriptions if needed",
            description: "Ensure you have enough medication for the entire trip plus extra",
            priority: .high
        ),
        ChecklistItem(
            id: "doctor_consultation",
            title: "Consult doctor about travel",
            description: "Discuss time zone changes and medication timing",
            priority: .medium
        ),
        ChecklistItem(
            id: "insurance_check",
            title: "Check travel insurance coverage",
            description: "Verify coverage for medical emergencies abroad",
            priority: .medium
        ),
        ChecklistItem(
            id: "prescription_copies",
            title: "Make copies of prescriptions",
            description: "Keep physical and digital copies separate from medications",
            priority: .high
        ),
        ChecklistItem(
            id: "research_destination",
            title: "Research destination medical facilities",
            description: "Find nearby hospitals and pharmacies",
            priority: .low
        )
    ]
    
    let packingItems: [ChecklistItem] = [
        ChecklistItem(
            id: "carry_on_medications",
            title: "Pack medications in carry-on",
            description: "Never pack medications in checked luggage",
            priority: .high
        ),
        ChecklistItem(
            id: "original_bottles",
            title: "Keep medications in original bottles",
            description: "Required for customs and identification",
            priority: .high
        ),
        ChecklistItem(
            id: "pill_organizer",
            title: "Pack pill organizer (if used)",
            description: "For easy daily medication management",
            priority: .medium
        ),
        ChecklistItem(
            id: "extra_supply",
            title: "Pack extra medication supply",
            description: "Bring 2-3 days extra in case of delays",
            priority: .high
        ),
        ChecklistItem(
            id: "medical_documents",
            title: "Pack medical documents",
            description: "Doctor's letters, insurance cards, emergency contacts",
            priority: .high
        ),
        ChecklistItem(
            id: "cooling_pack",
            title: "Pack cooling pack if needed",
            description: "For temperature-sensitive medications",
            priority: .medium
        )
    ]
    
    let travelDayItems: [ChecklistItem] = [
        ChecklistItem(
            id: "morning_medications",
            title: "Take morning medications",
            description: "Follow your regular schedule on departure day",
            priority: .high
        ),
        ChecklistItem(
            id: "medications_accessible",
            title: "Keep medications easily accessible",
            description: "In personal item or carry-on bag",
            priority: .high
        ),
        ChecklistItem(
            id: "timezone_adjustment",
            title: "Note time zone difference",
            description: "Plan for medication timing adjustments",
            priority: .medium
        ),
        ChecklistItem(
            id: "customs_declaration",
            title: "Declare medications at customs if required",
            description: "Some countries require declaration of certain medications",
            priority: .medium
        )
    ]
    
    let destinationItems: [ChecklistItem] = [
        ChecklistItem(
            id: "set_reminders",
            title: "Set up medication reminders",
            description: "Adjust alarms for new time zone",
            priority: .high
        ),
        ChecklistItem(
            id: "secure_storage",
            title: "Store medications securely",
            description: "Use hotel safe or secure location",
            priority: .medium
        ),
        ChecklistItem(
            id: "local_pharmacy",
            title: "Locate nearest pharmacy",
            description: "In case of emergency refill needs",
            priority: .medium
        ),
        ChecklistItem(
            id: "emergency_contacts",
            title: "Save local emergency contacts",
            description: "Local emergency number and medical facilities",
            priority: .high
        ),
        ChecklistItem(
            id: "medication_schedule",
            title: "Establish routine at destination",
            description: "Maintain consistent timing with new schedule",
            priority: .medium
        )
    ]
    
    func toggleItem(_ id: String) {
        if checkedItems.contains(id) {
            checkedItems.remove(id)
        } else {
            checkedItems.insert(id)
        }
        saveChecklistState()
    }
    
    func resetAllItems() {
        checkedItems.removeAll()
        saveChecklistState()
    }
    
    func saveChecklistState() {
        let itemsArray = Array(checkedItems)
        userDefaults.set(itemsArray, forKey: checklistKey)
    }
    
    func loadChecklistState() {
        if let itemsArray = userDefaults.array(forKey: checklistKey) as? [String] {
            checkedItems = Set(itemsArray)
        }
    }
}

struct ChecklistItem: Identifiable {
    let id: String
    let title: String
    let description: String?
    let priority: ChecklistPriority
    
    init(id: String, title: String, description: String? = nil, priority: ChecklistPriority = .medium) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
    }
}

enum ChecklistPriority {
    case high, medium, low
}

struct TravelChecklistView_Previews: PreviewProvider {
    static var previews: some View {
        TravelChecklistView(travelManager: TravelModeManager(prescriptionStore: PrescriptionStore.shared))
    }
}