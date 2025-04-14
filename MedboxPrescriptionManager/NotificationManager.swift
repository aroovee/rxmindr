import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification authorization granted")
            } else if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification(for prescription: Prescription) {
        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder"
        content.body = "Time to take \(prescription.name) - \(prescription.dose)"
        content.sound = .default
        
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
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
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
        // Then schedule new ones
        scheduleNotification(for: prescription)
    }
}
