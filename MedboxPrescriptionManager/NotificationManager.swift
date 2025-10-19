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
        var options: UNAuthorizationOptions = [.alert, .badge, .sound, .providesAppNotificationSettings]

        // Add time sensitive and critical alert options for iOS 15+
        if #available(iOS 15.0, *) {
            options.insert(.timeSensitive)
        }

        // Add critical alerts for medical apps (requires special entitlement)
        options.insert(.criticalAlert)

        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
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

        // Start with Active interruption level for initial medication reminders
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .active
            content.relevanceScore = 0.8 // High but not maximum priority
        }

        content.userInfo = [
            "prescriptionID": prescription.id.uuidString,
            "prescriptionName": prescription.name,
            "isTaken": prescription.isTaken,
            "notificationType": "initial_reminder"
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
                        // Schedule time-sensitive follow-up 10 minutes after initial reminder
                        self?.scheduleTimeSensitiveFollowUp(for: prescription, originalReminderTime: todaysReminder)

                        // If today's reminder hasn't passed yet, schedule urgent for today (30 min later)
                        self?.scheduleUrgentReminder(for: prescription, originalReminderTime: todaysReminder)
                    } else {
                        // Otherwise schedule for tomorrow
                        let tomorrowsReminder = calendar.date(byAdding: .day, value: 1, to: todaysReminder ?? now)
                        if let tomorrowsReminder = tomorrowsReminder {
                            self?.scheduleTimeSensitiveFollowUp(for: prescription, originalReminderTime: tomorrowsReminder)
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

        // Use active interruption for immediate updates
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .active
            content.relevanceScore = 0.7
        }

        content.userInfo = [
            "prescriptionID": prescription.id.uuidString,
            "prescriptionName": prescription.name,
            "isTaken": prescription.isTaken,
            "notificationType": "immediate_update"
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
    
    // Schedule Time Sensitive follow-up 10 minutes after original reminder
    func scheduleTimeSensitiveFollowUp(for prescription: Prescription, originalReminderTime: Date) {
        // Only schedule if medication hasn't been taken
        guard !prescription.isTaken else { return }

        let followUpTime = Calendar.current.date(byAdding: .minute, value: 10, to: originalReminderTime)
        guard let followUpTime = followUpTime else { return }

        let content = UNMutableNotificationContent()
        content.title = "⚠️ Medication Reminder"
        content.body = "You haven't taken \(prescription.name) yet. This medication is important for your health."
        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER"

        // Use Time Sensitive to break through Focus modes
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
            content.relevanceScore = 0.9 // Very high priority
        }

        content.userInfo = [
            "prescriptionID": prescription.id.uuidString,
            "prescriptionName": prescription.name,
            "isTimeSensitive": true,
            "notificationType": "time_sensitive_followup",
            "originalTime": originalReminderTime.timeIntervalSince1970
        ]

        // Schedule for the specific time (not repeating)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: followUpTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let identifier = "time-sensitive-\(prescription.id)-\(originalReminderTime.timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling time-sensitive follow-up: \(error.localizedDescription)")
            } else {
                print("Time-sensitive follow-up scheduled for \(prescription.name) at \(followUpTime)")
            }
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
            "notificationType": "urgent_critical",
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
                
                // Notify trusted contacts about missed medication after 30 minutes
                self.notifyTrustedContactsOfMissedMedication(for: prescription)
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
    
    
    // Cancel urgent reminders for a specific prescription
    func cancelUrgentReminders(for prescription: Prescription) {
        cancelUrgentRemindersById(prescription.id)
    }
    
    // Cancel urgent reminders by prescription ID
    private func cancelUrgentRemindersById(_ prescriptionId: UUID) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            // Cancel all escalation notifications: time-sensitive and urgent
            let escalationIdentifiers = requests
                .filter { request in
                    let id = request.identifier
                    return id.hasPrefix("time-sensitive-\(prescriptionId)") ||
                           id.hasPrefix("urgent-\(prescriptionId)") 
                }
                .map { $0.identifier }

            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: escalationIdentifiers)
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: escalationIdentifiers)

            if !escalationIdentifiers.isEmpty {
                print("Cancelled \(escalationIdentifiers.count) escalation notifications for prescription \(prescriptionId)")
            }
        }
    }
    // Schedule follow-up notification after snooze with time-sensitive priority
    private func scheduleSnoozeFollowUp(prescriptionId: UUID) {
        let snoozeTime = Calendar.current.date(byAdding: .minute, value: 15, to: Date())
        guard let snoozeTime = snoozeTime else { return }

        let content = UNMutableNotificationContent()
        content.title = "⏰ Snoozed Medication Reminder"
        content.body = "Time to take your medication (snoozed reminder)"
        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER"

        // Use time-sensitive for snoozed reminders to ensure they break through focus
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
            content.relevanceScore = 0.9
        }

        content.userInfo = [
            "prescriptionID": prescriptionId.uuidString,
            "isSnoozedReminder": true,
            "notificationType": "snooze_followup"
        ]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: snoozeTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let identifier = "snooze-\(prescriptionId)-\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling snooze follow-up: \(error.localizedDescription)")
            } else {
                print("Snooze follow-up scheduled for \(snoozeTime)")
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
                // Cancel any pending escalation notifications for this prescription
                cancelUrgentRemindersById(prescriptionId)
            case "MARK_UNTAKEN":
                markUntaken(prescriptionID: prescriptionId)
                // If marking as untaken, reschedule time-sensitive follow-up in 10 minutes
                if let notificationType = userInfo["notificationType"] as? String,
                   notificationType == "initial_reminder" {
                    // This means they unmarked from the initial reminder, schedule immediate time-sensitive
                    let now = Date()
                    let timeSensitiveTime = Calendar.current.date(byAdding: .minute, value: 10, to: now) ?? now
                    // We would need the prescription object here to reschedule properly
                    // This should be handled by the delegate with the full prescription object
                }
            case "SNOOZE":
                snooze(prescriptionID: prescriptionId)
                // For snooze, schedule another reminder in 15 minutes with time-sensitive priority
                scheduleSnoozeFollowUp(prescriptionId: prescriptionId)
            default:
                break
            }
            
            completionHandler()
        }
    
}

