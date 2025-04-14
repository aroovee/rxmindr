import SwiftUI

@main
struct MedboxPrescriptionManagerApp: App {
    init() {
        NDCDatabaseProcessor.processDatabase()
        NotificationManager.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            CoverScreen()
        }
    }
}
