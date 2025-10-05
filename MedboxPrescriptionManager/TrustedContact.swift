import Foundation
import SwiftUI

struct TrustedContact: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var email: String
    var phoneNumber: String?
    var relationship: String
    var accessLevel: AccessLevel
    var isActive: Bool
    var notificationPreferences: NotificationPreferences
    let dateAdded: Date
    var lastNotified: Date?
    
    enum AccessLevel: String, CaseIterable, Codable {
        case basic = "basic"           // Can see if medications are taken on time
        case detailed = "detailed"     // Can see specific medications and schedules
        case emergency = "emergency"   // Gets alerts for missed critical medications
        
        var displayName: String {
            switch self {
            case .basic: return "Basic Progress"
            case .detailed: return "Detailed Information"
            case .emergency: return "Emergency Contact"
            }
        }
        
        var description: String {
            switch self {
            case .basic: return "Can see overall medication adherence"
            case .detailed: return "Can see specific medications and schedules"
            case .emergency: return "Receives alerts for missed critical medications"
            }
        }
    }
    
    struct NotificationPreferences: Codable, Equatable {
        var enableDailySummary: Bool = true
        var enableMissedMedicationAlerts: Bool = true
        var enableWeeklySummary: Bool = false
        var enableEmergencyAlerts: Bool = true
        var preferredContactMethod: ContactMethod = .email
        
        enum ContactMethod: String, CaseIterable, Codable {
            case email = "email"
            case sms = "sms"
            case both = "both"
            
            var displayName: String {
                switch self {
                case .email: return "Email"
                case .sms: return "SMS"
                case .both: return "Email & SMS"
                }
            }
        }
    }
    
    init(
        name: String,
        email: String,
        phoneNumber: String? = nil,
        relationship: String = "Family",
        accessLevel: AccessLevel = .basic,
        isActive: Bool = true,
        notificationPreferences: NotificationPreferences = NotificationPreferences()
    ) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
        self.relationship = relationship
        self.accessLevel = accessLevel
        self.isActive = isActive
        self.notificationPreferences = notificationPreferences
        self.dateAdded = Date()
        self.lastNotified = nil
    }
    
    // Helper method to check if contact should receive a specific type of notification
    func shouldReceive(notificationType: NotificationType) -> Bool {
        guard isActive else { return false }
        
        switch notificationType {
        case .dailySummary:
            return notificationPreferences.enableDailySummary
        case .missedMedication:
            return notificationPreferences.enableMissedMedicationAlerts && 
                   (accessLevel == .detailed || accessLevel == .emergency)
        case .weeklySummary:
            return notificationPreferences.enableWeeklySummary
        case .emergency:
            return notificationPreferences.enableEmergencyAlerts && accessLevel == .emergency
        }
    }
    
    enum NotificationType {
        case dailySummary
        case missedMedication
        case weeklySummary
        case emergency
    }
}

// Sharing permission model
struct SharingPermission: Codable {
    let profileId: UUID
    var trustedContacts: [TrustedContact]
    var isEnabled: Bool
    var privacySettings: PrivacySettings
    
    struct PrivacySettings: Codable {
        var shareMedicationNames: Bool = true
        var shareDosageInformation: Bool = false
        var shareTimingInformation: Bool = true
        var shareAdherenceStats: Bool = true
        var sharePhysicianInfo: Bool = false
    }
    
    init(profileId: UUID) {
        self.profileId = profileId
        self.trustedContacts = []
        self.isEnabled = false
        self.privacySettings = PrivacySettings()
    }
}