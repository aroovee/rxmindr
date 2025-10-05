import SwiftUI
import UserNotifications

@main
struct MedboxPrescriptionManagerApp: App {
    init() {
        NDCDatabaseProcessor.processDatabase()
        setupNotifications()
    }
    
    private func setupNotifications() {
        let notificationManager = NotificationManager.shared
        
        // Request authorization
        notificationManager.requestAuthorization()
        
        // Create notification categories
        notificationManager.createCategories()
        
        // Set the delegate
        UNUserNotificationCenter.current().delegate = notificationManager
        
        // Set the prescription store as the delegate
        notificationManager.delegate = PrescriptionStore.shared
    }
    
    var body: some Scene {
        WindowGroup {
            CoverScreen()
        }
    }
}
