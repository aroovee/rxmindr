import UserNotifications
import UIKit

protocol NotificationManagerDelegate: AnyObject {
    func didMarkAsTaken(prescriptionID: UUID)
    func didMarkAsUntaken(prescriptionID: UUID)
    func didSnoozeMedication(prescriptionID: UUID)
}

class NotificationManager: NSObject{
    static let shared = NotificationManager()
    weak var delegate:NotificationManagerDelegate?
    
    private override init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .criticalAlert, .providesAppNotificationSettings]) { granted, error in
            if granted {
                print("Notification authorization granted")
                // Enable critical alerts for medication reminders
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            }
        }
    }
    func createCategories() {
        let markTaken = UNNotificationAction(
            identifier: "MARK_TAKEN",
            title: "✓ Mark Taken",
            options: [.authenticationRequired] // Works from lock screen with authentication
        )
        
        let markUntaken = UNNotificationAction(
            identifier: "MARK_UNTAKEN",
            title: "✗ Mark Not Taken",
            options: [.authenticationRequired] // Works from lock screen with authentication
        )
        
        let snooze = UNNotificationAction(
            identifier: "SNOOZE",
            title: "⏰ Snooze 15 min",
            options: [] // Works from lock screen without authentication
        )
        
        // Category for when medication hasn't been taken yet
        let medicationReminderCategory = UNNotificationCategory(
            identifier: "MEDICATION_REMINDER",
            actions: [markTaken, snooze],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Category for when medication has been taken (allows unmarking)
        let medicationTakenCategory = UNNotificationCategory(
            identifier: "MEDICATION_TAKEN",
            actions: [markUntaken],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Category for urgent reminders - only "Mark Taken" action, not dismissible
        let urgentMedicationCategory = UNNotificationCategory(
            identifier: "URGENT_MEDICATION",
            actions: [markTaken], // Only allow marking as taken
            intentIdentifiers: [],
            options: [] // No custom dismiss - user must interact with notification
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            medicationReminderCategory,
            medicationTakenCategory,
            urgentMedicationCategory
        ])
    }
   
    private func markTaken(prescriptionID: UUID) {
        delegate?.didMarkAsTaken(prescriptionID: prescriptionID)
    }
    
    private func markUntaken(prescriptionID: UUID) {
        delegate?.didMarkAsUntaken(prescriptionID: prescriptionID)
    }
    
    private func snooze(prescriptionID: UUID) {
        delegate?.didSnoozeMedication(prescriptionID: prescriptionID)
    }
    
    func scheduleNotification(for prescription: Prescription) {
        let content = UNMutableNotificationContent()
        content.title = "💊 Medication Reminder"
        content.body = "Time to take \(prescription.name) - \(prescription.dose)"
        content.sound = .default
        
        // Use different category based on medication status
        content.categoryIdentifier = prescription.isTaken ? "MEDICATION_TAKEN" : "MEDICATION_REMINDER"
        
        content.userInfo = [
            "prescriptionID": prescription.id.uuidString,
            "prescriptionName": prescription.name,
            "isTaken": prescription.isTaken
        ]
        
        // Add badge count
        content.badge = NSNumber(value: getUnreadNotificationCount() + 1)
        
        // Schedule a notification for each reminder time
        for reminderTime in prescription.reminderTimes where reminderTime.isEnabled {
            let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime.time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            // Create unique identifier for each reminder
            let identifier = "\(prescription.id)-\(reminderTime.id)"
            
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { [weak self] error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                } else {
                    // Schedule urgent reminder for 30 minutes after each reminder time
                    // We need to calculate the next occurrence of this time
                    let calendar = Calendar.current
                    let now = Date()
                    
                    // Get today's occurrence of the reminder time
                    let todaysReminder = calendar.date(bySettingHour: components.hour ?? 0,
                                                     minute: components.minute ?? 0,
                                                     second: 0,
                                                     of: now)
                    
                    if let todaysReminder = todaysReminder, todaysReminder > now {
                        // If today's reminder hasn't passed yet, schedule urgent for today
                        self?.scheduleUrgentReminder(for: prescription, originalReminderTime: todaysReminder)
                    } else {
                        // Otherwise schedule for tomorrow
                        let tomorrowsReminder = calendar.date(byAdding: .day, value: 1, to: todaysReminder ?? now)
                        if let tomorrowsReminder = tomorrowsReminder {
                            self?.scheduleUrgentReminder(for: prescription, originalReminderTime: tomorrowsReminder)
                        }
                    }
                }
            }
        }
    }
    
    // Helper method to get unread notification count
    private func getUnreadNotificationCount() -> Int {
        // This is a placeholder - in a real app you'd track this properly
        return 0
    }
    
    // Method to send immediate contextual notification
    func sendImmediateNotification(for prescription: Prescription, message: String) {
        let content = UNMutableNotificationContent()
        content.title = "✅ Medication Update"
        content.body = message
        content.sound = .default
        content.categoryIdentifier = prescription.isTaken ? "MEDICATION_TAKEN" : "MEDICATION_REMINDER"
        content.userInfo = [
            "prescriptionID": prescription.id.uuidString,
            "prescriptionName": prescription.name,
            "isTaken": prescription.isTaken
        ]
        
        let request = UNNotificationRequest(
            identifier: "immediate-\(prescription.id.uuidString)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Immediate delivery
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending immediate notification: \(error.localizedDescription)")
            }
        }
    }
    
    // Add method to cancel notifications for a prescription
    func cancelNotifications(for prescription: Prescription) {
        let identifiers = prescription.reminderTimes.map { "\(prescription.id)-\($0.id)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // Add method to update notifications for a prescription
    func updateNotifications(for prescription: Prescription) {
        // First cancel existing notifications
        cancelNotifications(for: prescription)
        
        // Schedule new notifications if not taken
        if !prescription.isTaken {
            scheduleNotification(for: prescription)
        } else {
            // Cancel any urgent reminders since medication was taken
            cancelUrgentReminders(for: prescription)
        }
    }
    
    // Schedule urgent reminder 30 minutes after original reminder time
    func scheduleUrgentReminder(for prescription: Prescription, originalReminderTime: Date) {
        // Only schedule if medication hasn't been taken
        guard !prescription.isTaken else { return }
        
        let urgentTime = Calendar.current.date(byAdding: .minute, value: 30, to: originalReminderTime)
        guard let urgentTime = urgentTime else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🚨 URGENT: Medication Missed"
        content.body = "You missed taking \(prescription.name). This is important for your health - please take it now!"
        content.sound = .defaultCritical // Use critical sound that bypasses Do Not Disturb
        content.categoryIdentifier = "URGENT_MEDICATION"
        
        content.userInfo = [
            "prescriptionID": prescription.id.uuidString,
            "prescriptionName": prescription.name,
            "isUrgent": true,
            "originalTime": originalReminderTime.timeIntervalSince1970
        ]
        
        // Set interruption level to critical for iOS 15+
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .critical
            content.relevanceScore = 1.0 // Highest priority
        }
        
        // Schedule for the specific time (not repeating)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: urgentTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let identifier = "urgent-\(prescription.id)-\(originalReminderTime.timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling urgent reminder: \(error.localizedDescription)")
            } else {
                print("Urgent reminder scheduled for \(prescription.name) at \(urgentTime)")
                
                // Schedule additional follow-up urgent notifications if needed
                self.scheduleFollowUpUrgentReminders(for: prescription, baseTime: urgentTime)
                
                // Notify trusted contacts about missed medication
                self.notifyTrustedContactsOfMissedMedication(for: prescription)
            }
        }
    }
    
    // Schedule follow-up urgent reminders for critical medications
    private func scheduleFollowUpUrgentReminders(for prescription: Prescription, baseTime: Date) {
        // Schedule additional urgent reminders at 1 hour, 2 hours, and 4 hours after first urgent
        let followUpIntervals: [TimeInterval] = [60, 120, 240] // minutes
        
        for (index, interval) in followUpIntervals.enumerated() {
            guard let followUpTime = Calendar.current.date(byAdding: .minute, value: Int(interval), to: baseTime) else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "🚨 CRITICAL: Medication Still Missed"
            content.body = "You still haven't taken \(prescription.name). This is critically important for your health. Please take it immediately or contact your healthcare provider."
            content.sound = .defaultCritical
            content.categoryIdentifier = "URGENT_MEDICATION"
            
            content.userInfo = [
                "prescriptionID": prescription.id.uuidString,
                "prescriptionName": prescription.name,
                "isUrgent": true,
                "isCriticalFollowUp": true,
                "followUpNumber": index + 1
            ]
            
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .critical
                content.relevanceScore = 1.0
            }
            
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: followUpTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let identifier = "critical-followup-\(prescription.id)-\(index)-\(baseTime.timeIntervalSince1970)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling critical follow-up reminder: \(error.localizedDescription)")
                }
            }
        }
        
        // Schedule emergency alert after 4 hours if still not taken
        if let emergencyTime = Calendar.current.date(byAdding: .hour, value: 4, to: baseTime) {
            scheduleEmergencyAlert(for: prescription, at: emergencyTime)
        }
    }
    
    // Schedule emergency alert for extremely serious cases
    private func scheduleEmergencyAlert(for prescription: Prescription, at emergencyTime: Date) {
        let content = UNMutableNotificationContent()
        content.title = "🚨 EMERGENCY: Contact Healthcare Provider"
        content.body = "You've missed \(prescription.name) for over 4 hours. This could be dangerous. Contact your healthcare provider immediately."
        content.sound = .defaultCritical
        content.categoryIdentifier = "URGENT_MEDICATION"
        
        content.userInfo = [
            "prescriptionID": prescription.id.uuidString,
            "prescriptionName": prescription.name,
            "isEmergency": true
        ]
        
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .critical
            content.relevanceScore = 1.0
        }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: emergencyTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let identifier = "emergency-\(prescription.id)-\(emergencyTime.timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling emergency alert: \(error.localizedDescription)")
            } else {
                // Also notify trusted emergency contacts
                self.notifyTrustedContactsOfEmergency(for: prescription)
            }
        }
    }
    
    // Notify trusted contacts when medication is missed
    private func notifyTrustedContactsOfMissedMedication(for prescription: Prescription) {
        // Get current profile - in a real app, this would be properly managed
        if let currentProfile = ProfileStore().currentProfile {
            SharingManager.shared.sendMissedMedicationAlert(for: currentProfile, prescription: prescription)
        }
    }
    
    // Notify emergency contacts for critical situations
    private func notifyTrustedContactsOfEmergency(for prescription: Prescription) {
        if let currentProfile = ProfileStore().currentProfile {
            SharingManager.shared.sendEmergencyAlert(for: currentProfile, prescriptions: [prescription])
        }
    }
    
    // Cancel urgent reminders for a specific prescription
    func cancelUrgentReminders(for prescription: Prescription) {
        cancelUrgentRemindersById(prescription.id)
    }
    
    // Cancel urgent reminders by prescription ID
    private func cancelUrgentRemindersById(_ prescriptionId: UUID) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let urgentIdentifiers = requests
                .filter { $0.identifier.hasPrefix("urgent-\(prescriptionId)") }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: urgentIdentifiers)
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: urgentIdentifiers)
            
            if !urgentIdentifiers.isEmpty {
                print("Cancelled \(urgentIdentifiers.count) urgent reminders for prescription \(prescriptionId)")
            }
        }
    }
   
}


extension NotificationManager: UNUserNotificationCenterDelegate{
    
    func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse,
            withCompletionHandler completionHandler: @escaping () -> Void
        ) {
            let userInfo = response.notification.request.content.userInfo
            
            guard let prescriptionIdString = userInfo["prescriptionID"] as? String,
                  let prescriptionId = UUID(uuidString: prescriptionIdString) else {
                completionHandler()
                return
            }
            
            switch response.actionIdentifier {
            case "MARK_TAKEN":
                markTaken(prescriptionID: prescriptionId)
                // Cancel any pending urgent reminders for this prescription
                // We need the prescription object to cancel, so we'll handle this in the delegate
                cancelUrgentRemindersById(prescriptionId)
            case "MARK_UNTAKEN":
                markUntaken(prescriptionID: prescriptionId)
            case "SNOOZE":
                snooze(prescriptionID: prescriptionId)
            default:
                break
            }
            
            completionHandler()
        }
    
}

