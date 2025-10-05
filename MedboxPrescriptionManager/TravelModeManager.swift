import Foundation
import SwiftUI
import CoreLocation
import UserNotifications

class TravelModeManager: ObservableObject {
    @Published var isTravelModeActive = false
    @Published var currentTravelPlan: TravelPlan?
    @Published var travelMedications: [TravelMedication] = []
    @Published var timeZoneAdjustments: [TimeZoneAdjustment] = []
    
    private weak var _prescriptionStore: PrescriptionStore?
    private let notificationManager = NotificationManager.shared
    
    var prescriptionStore: PrescriptionStore? {
        return _prescriptionStore
    }
    
    init(prescriptionStore: PrescriptionStore) {
        self._prescriptionStore = prescriptionStore
    }
    
    // MARK: - Travel Plan Management
    
    func activateTravelMode(with travelPlan: TravelPlan) {
        currentTravelPlan = travelPlan
        isTravelModeActive = true
        
        // Generate travel medications list
        generateTravelMedicationsList()
        
        // Calculate time zone adjustments
        calculateTimeZoneAdjustments()
        
        // Update notifications for travel
        updateNotificationsForTravel()
        
        // Save travel state
        saveTravelState()
    }
    
    func deactivateTravelMode() {
        isTravelModeActive = false
        currentTravelPlan = nil
        travelMedications.removeAll()
        timeZoneAdjustments.removeAll()
        
        // Restore original notification schedule
        restoreOriginalNotifications()
        
        // Clear travel state
        clearTravelState()
    }
    
    // MARK: - Travel Medications List Generation
    
    func generateTravelMedicationsList() {
        guard let travelPlan = currentTravelPlan else { return }
        
        guard let prescriptions = _prescriptionStore?.prescriptions else { return }
        var travelMeds: [TravelMedication] = []
        
        for prescription in prescriptions {
            let travelMedication = createTravelMedication(
                from: prescription,
                travelPlan: travelPlan
            )
            travelMeds.append(travelMedication)
        }
        
        // Sort by importance (essential first)
        travelMedications = travelMeds.sorted { med1, med2 in
            if med1.isEssential != med2.isEssential {
                return med1.isEssential
            }
            return med1.requiredQuantity > med2.requiredQuantity
        }
    }
    
    private func createTravelMedication(from prescription: Prescription, travelPlan: TravelPlan) -> TravelMedication {
        let dailyDoses = prescription.dailyFrequency
        let travelDays = travelPlan.durationInDays
        let bufferDays = 3 // Extra days as buffer
        
        let requiredQuantity = dailyDoses * (travelDays + bufferDays)
        let currentStock = prescription.pillsRemaining ?? 0
        let needsRefill = requiredQuantity > currentStock
        
        // Determine if medication is essential for travel
        let isEssential = prescription.isEssentialForTravel || 
                         isEssentialMedication(prescription)
        
        return TravelMedication(
            prescription: prescription,
            requiredQuantity: requiredQuantity,
            currentStock: currentStock,
            needsRefill: needsRefill,
            refillQuantity: needsRefill ? requiredQuantity - currentStock : 0,
            isEssential: isEssential,
            travelNotes: prescription.travelNotes ?? generateTravelNotes(for: prescription),
            packingRecommendation: generatePackingRecommendation(for: prescription, travelPlan: travelPlan)
        )
    }
    
    private func isEssentialMedication(_ prescription: Prescription) -> Bool {
        let essentialCategories = [
            "insulin", "heart", "blood pressure", "seizure", "thyroid",
            "anticoagulant", "psychiatric", "pain", "emergency"
        ]
        
        let prescriptionText = "\(prescription.name.lowercased()) \(prescription.drugInfo?.name.lowercased() ?? "")"
        
        return essentialCategories.contains { category in
            prescriptionText.contains(category)
        }
    }
    
    private func generateTravelNotes(for prescription: Prescription) -> String {
        var notes: [String] = []
        
        // Storage recommendations
        if let drugInfo = prescription.drugInfo {
            if drugInfo.warnings.lowercased().contains("refrigerate") {
                notes.append("Keep refrigerated - bring cooling pack")
            }
            if drugInfo.warnings.lowercased().contains("moisture") {
                notes.append("Keep in original container - protect from moisture")
            }
        }
        
        // Timing recommendations
        if prescription.dailyFrequency > 1 {
            notes.append("Multiple daily doses - set timezone-adjusted reminders")
        }
        
        // Legal considerations
        if prescription.name.lowercased().contains("controlled") {
            notes.append("Controlled substance - carry prescription and doctor's letter")
        }
        
        return notes.joined(separator: ". ")
    }
    
    private func generatePackingRecommendation(for prescription: Prescription, travelPlan: TravelPlan) -> PackingRecommendation {
        let isInternational = travelPlan.isInternational
        let duration = travelPlan.durationInDays
        
        var recommendations: [String] = []
        
        // Quantity recommendations
        recommendations.append("Pack \(prescription.dailyFrequency * (duration + 3)) pills (includes 3-day buffer)")
        
        // Packing location
        if prescription.isEssentialForTravel {
            recommendations.append("Pack in carry-on bag")
            recommendations.append("Keep some in separate bag as backup")
        } else {
            recommendations.append("Can pack in checked luggage")
        }
        
        // Documentation
        if isInternational {
            recommendations.append("Bring original prescription and doctor's letter")
            if prescription.name.lowercased().contains("controlled") {
                recommendations.append("Check destination country regulations")
            }
        }
        
        // Special handling
        if let drugInfo = prescription.drugInfo,
           drugInfo.warnings.lowercased().contains("temperature") {
            recommendations.append("Consider temperature-controlled storage")
        }
        
        return PackingRecommendation(
            primaryLocation: prescription.isEssentialForTravel ? .carryOn : .checked,
            backupLocation: .carryOn,
            specialHandling: recommendations.filter { $0.contains("temperature") || $0.contains("refrigerat") },
            documentation: recommendations.filter { $0.contains("prescription") || $0.contains("letter") },
            allRecommendations: recommendations
        )
    }
    
    // MARK: - Time Zone Adjustments
    
    func calculateTimeZoneAdjustments() {
        guard let travelPlan = currentTravelPlan else { return }
        
        let homeTimeZone = TimeZone.current
        let destinationTimeZone = travelPlan.destinationTimeZone
        let timeDifference = destinationTimeZone.secondsFromGMT() - homeTimeZone.secondsFromGMT()
        let hoursDifference = timeDifference / 3600
        
        var adjustments: [TimeZoneAdjustment] = []
        
        guard let prescriptions = _prescriptionStore?.prescriptions else { return }
        
        for prescription in prescriptions {
            for reminderTime in prescription.reminderTimes where reminderTime.isEnabled {
                let originalTime = reminderTime.time
                let adjustedTime = Calendar.current.date(
                    byAdding: .hour,
                    value: hoursDifference,
                    to: originalTime
                ) ?? originalTime
                
                let adjustment = TimeZoneAdjustment(
                    prescriptionId: prescription.id,
                    prescriptionName: prescription.name,
                    originalTime: originalTime,
                    adjustedTime: adjustedTime,
                    timeZoneDifference: hoursDifference,
                    homeTimeZone: homeTimeZone,
                    destinationTimeZone: destinationTimeZone
                )
                
                adjustments.append(adjustment)
            }
        }
        
        timeZoneAdjustments = adjustments
    }
    
    func updateNotificationsForTravel() {
        guard let travelPlan = currentTravelPlan else { return }
        
        // Cancel existing notifications
        // Cancel notifications for all travel medications
        for prescription in _prescriptionStore?.prescriptions ?? [] {
            notificationManager.cancelNotifications(for: prescription)
        }
        
        // Schedule new notifications with adjusted times
        for adjustment in timeZoneAdjustments {
            if let prescription = _prescriptionStore?.prescriptions.first(where: { $0.id == adjustment.prescriptionId }) {
                // Create adjusted reminder times
                var adjustedPrescription = prescription
                adjustedPrescription.reminderTimes = adjustedPrescription.reminderTimes.map { reminder in
                    var adjustedReminder = reminder
                    adjustedReminder.time = adjustment.adjustedTime
                    return adjustedReminder
                }
                
                // Schedule notifications for travel period
                notificationManager.scheduleNotificationForTravel(
                    for: adjustedPrescription,
                    travelPlan: travelPlan
                )
            }
        }
    }
    
    func restoreOriginalNotifications() {
        // Cancel travel notifications
        // Cancel notifications for all travel medications
        for prescription in _prescriptionStore?.prescriptions ?? [] {
            notificationManager.cancelNotifications(for: prescription)
        }
        
        // Restore original notifications
        guard let prescriptions = _prescriptionStore?.prescriptions else { return }
        
        for prescription in prescriptions {
            notificationManager.scheduleNotification(for: prescription)
        }
    }
    
    // MARK: - Travel Checklist
    
    func generateTravelChecklist() -> TravelChecklist {
        guard let travelPlan = currentTravelPlan else {
            return TravelChecklist(items: [])
        }
        
        var items: [TravelChecklistItem] = []
        
        // Essential medications check
        let essentialMeds = travelMedications.filter { $0.isEssential }
        if !essentialMeds.isEmpty {
            items.append(TravelChecklistItem(
                title: "Pack essential medications",
                description: "\(essentialMeds.count) essential medications identified",
                category: .medications,
                isCompleted: false,
                priority: .high
            ))
        }
        
        // Refill check
        let needsRefill = travelMedications.filter { $0.needsRefill }
        if !needsRefill.isEmpty {
            items.append(TravelChecklistItem(
                title: "Get prescription refills",
                description: "\(needsRefill.count) medications need refills before travel",
                category: .preparation,
                isCompleted: false,
                priority: .high
            ))
        }
        
        // Documentation check
        if travelPlan.isInternational {
            items.append(TravelChecklistItem(
                title: "Prepare medication documentation",
                description: "Original prescriptions and doctor's letters",
                category: .documentation,
                isCompleted: false,
                priority: .medium
            ))
        }
        
        // Time zone adjustment check
        if !timeZoneAdjustments.isEmpty {
            items.append(TravelChecklistItem(
                title: "Update medication reminders",
                description: "Adjust reminder times for destination timezone",
                category: .preparation,
                isCompleted: false,
                priority: .medium
            ))
        }
        
        // Packing check
        items.append(TravelChecklistItem(
            title: "Pack medications in carry-on",
            description: "Keep essential medications accessible during travel",
            category: .packing,
            isCompleted: false,
            priority: .high
        ))
        
        return TravelChecklist(items: items.sorted { $0.priority.rawValue < $1.priority.rawValue })
    }
    
    // MARK: - Persistence
    
    private func saveTravelState() {
        if let encoded = try? JSONEncoder().encode(currentTravelPlan) {
            UserDefaults.standard.set(encoded, forKey: "CurrentTravelPlan")
        }
        UserDefaults.standard.set(isTravelModeActive, forKey: "IsTravelModeActive")
    }
    
    private func clearTravelState() {
        UserDefaults.standard.removeObject(forKey: "CurrentTravelPlan")
        UserDefaults.standard.set(false, forKey: "IsTravelModeActive")
    }
    
    func loadTravelState() {
        isTravelModeActive = UserDefaults.standard.bool(forKey: "IsTravelModeActive")
        
        if let data = UserDefaults.standard.data(forKey: "CurrentTravelPlan"),
           let travelPlan = try? JSONDecoder().decode(TravelPlan.self, from: data) {
            currentTravelPlan = travelPlan
            
            if isTravelModeActive {
                generateTravelMedicationsList()
                calculateTimeZoneAdjustments()
            }
        }
    }
}

// MARK: - Supporting Data Types

struct TravelChecklist {
    let items: [TravelChecklistItem]
    
    var completionRate: Double {
        guard !items.isEmpty else { return 0.0 }
        let completedCount = items.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(items.count)
    }
}

struct TravelChecklistItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: ChecklistCategory
    var isCompleted: Bool
    let priority: Priority
    
    enum Priority: Int, Comparable {
        case low = 2
        case medium = 1
        case high = 0
        
        static func < (lhs: Priority, rhs: Priority) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
}

struct TravelPlan: Codable {
    let id: UUID
    let destination: String
    let startDate: Date
    let endDate: Date
    let destinationTimeZone: TimeZone
    let isInternational: Bool
    let notes: String?
    
    var durationInDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    init(id: UUID = UUID(), destination: String, startDate: Date, endDate: Date, 
         destinationTimeZone: TimeZone, isInternational: Bool = false, notes: String? = nil) {
        self.id = id
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.destinationTimeZone = destinationTimeZone
        self.isInternational = isInternational
        self.notes = notes
    }
}

struct TravelMedication: Identifiable {
    let id = UUID()
    let prescription: Prescription
    let requiredQuantity: Int
    let currentStock: Int
    let needsRefill: Bool
    let refillQuantity: Int
    let isEssential: Bool
    let travelNotes: String
    let packingRecommendation: PackingRecommendation
}

struct PackingRecommendation {
    let primaryLocation: PackingLocation
    let backupLocation: PackingLocation
    let specialHandling: [String]
    let documentation: [String]
    let allRecommendations: [String]
}

enum PackingLocation {
    case carryOn, checked, personal
    
    var displayName: String {
        switch self {
        case .carryOn: return "Carry-on bag"
        case .checked: return "Checked luggage"
        case .personal: return "Personal item"
        }
    }
}

struct TimeZoneAdjustment: Identifiable {
    let id = UUID()
    let prescriptionId: UUID
    let prescriptionName: String
    let originalTime: Date
    let adjustedTime: Date
    let timeZoneDifference: Int
    let homeTimeZone: TimeZone
    let destinationTimeZone: TimeZone
    
    var adjustmentDescription: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let originalTimeString = formatter.string(from: originalTime)
        let adjustedTimeString = formatter.string(from: adjustedTime)
        
        return "\(originalTimeString) → \(adjustedTimeString)"
    }
}

// TravelChecklist and TravelChecklistItem moved to avoid duplication

enum ChecklistCategory: String, CaseIterable {
    case medications = "Medications"
    case preparation = "Preparation"
    case documentation = "Documentation"
    case packing = "Packing"
    
    var icon: String {
        switch self {
        case .medications: return "pills.fill"
        case .preparation: return "list.clipboard"
        case .documentation: return "doc.text"
        case .packing: return "bag.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .medications: return .blue
        case .preparation: return .orange
        case .documentation: return .green
        case .packing: return .purple
        }
    }
}

enum Priority: Int, CaseIterable {
    case high = 0
    case medium = 1
    case low = 2
    
    var displayName: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

// TimeZone is already Codable in Foundation, so no extension needed

// Extension to NotificationManager for travel
extension NotificationManager {
    func scheduleNotificationForTravel(for prescription: Prescription, travelPlan: TravelPlan) {
        // Implementation for travel-specific notifications
        // This would schedule notifications for the duration of travel with adjusted times
        for reminder in prescription.reminderTimes where reminder.isEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Travel Reminder: \(prescription.name)"
            content.body = "Time to take your medication (adjusted for \(travelPlan.destination))"
            content.sound = .default
            
            // Schedule for each day of travel
            let calendar = Calendar.current
            var currentDate = travelPlan.startDate
            
            while currentDate <= travelPlan.endDate {
                let reminderDateTime = calendar.dateBySettingTimeOfDay(
                    from: reminder.time,
                    to: currentDate
                )
                
                if let reminderDateTime = reminderDateTime, reminderDateTime > Date() {
                    let trigger = UNCalendarNotificationTrigger(
                        dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDateTime),
                        repeats: false
                    )
                    
                    let request = UNNotificationRequest(
                        identifier: "travel_\(prescription.id)_\(currentDate)",
                        content: content,
                        trigger: trigger
                    )
                    
                    UNUserNotificationCenter.current().add(request)
                }
                
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }
    }
}

extension Calendar {
    func dateBySettingTimeOfDay(from timeSource: Date, to dateTarget: Date) -> Date? {
        let timeComponents = dateComponents([.hour, .minute, .second], from: timeSource)
        return date(bySettingHour: timeComponents.hour ?? 0,
                   minute: timeComponents.minute ?? 0,
                   second: timeComponents.second ?? 0,
                   of: dateTarget)
    }
}