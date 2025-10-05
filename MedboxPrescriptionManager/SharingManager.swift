import Foundation
import UserNotifications
import MessageUI

class SharingManager: ObservableObject {
    static let shared = SharingManager()
    
    @Published var sharingPermissions: [UUID: SharingPermission] = [:]
    
    private let saveKey = "SharingPermissions"
    private let mailComposer = MailComposer()
    
    init() {
        loadSharingPermissions()
    }
    
    // MARK: - Permission Management
    
    func enableSharing(for profileId: UUID) {
        if sharingPermissions[profileId] == nil {
            sharingPermissions[profileId] = SharingPermission(profileId: profileId)
        }
        sharingPermissions[profileId]?.isEnabled = true
        saveSharingPermissions()
    }
    
    func disableSharing(for profileId: UUID) {
        sharingPermissions[profileId]?.isEnabled = false
        saveSharingPermissions()
    }
    
    func addTrustedContact(_ contact: TrustedContact, to profileId: UUID) {
        if sharingPermissions[profileId] == nil {
            sharingPermissions[profileId] = SharingPermission(profileId: profileId)
        }
        sharingPermissions[profileId]?.trustedContacts.append(contact)
        saveSharingPermissions()
    }
    
    func updateTrustedContact(_ contact: TrustedContact, for profileId: UUID) {
        guard let index = sharingPermissions[profileId]?.trustedContacts.firstIndex(where: { $0.id == contact.id }) else { return }
        sharingPermissions[profileId]?.trustedContacts[index] = contact
        saveSharingPermissions()
    }
    
    func removeTrustedContact(_ contactId: UUID, from profileId: UUID) {
        sharingPermissions[profileId]?.trustedContacts.removeAll { $0.id == contactId }
        saveSharingPermissions()
    }
    
    func getTrustedContacts(for profileId: UUID) -> [TrustedContact] {
        return sharingPermissions[profileId]?.trustedContacts ?? []
    }
    
    func updatePrivacySettings(_ settings: SharingPermission.PrivacySettings, for profileId: UUID) {
        sharingPermissions[profileId]?.privacySettings = settings
        saveSharingPermissions()
    }
    
    // MARK: - Medication Progress Sharing
    
    func sendDailySummary(for profile: Profile, prescriptions: [Prescription]) {
        guard let permission = sharingPermissions[profile.id],
              permission.isEnabled else { return }
        
        let contacts = permission.trustedContacts.filter { 
            $0.shouldReceive(notificationType: .dailySummary) 
        }
        
        guard !contacts.isEmpty else { return }
        
        let summary = generateDailySummary(for: profile, prescriptions: prescriptions, privacy: permission.privacySettings)
        
        for contact in contacts {
            sendNotificationToContact(contact: contact, message: summary, type: .dailySummary)
            updateLastNotified(contactId: contact.id, profileId: profile.id)
        }
    }
    
    func sendMissedMedicationAlert(for profile: Profile, prescription: Prescription) {
        guard let permission = sharingPermissions[profile.id],
              permission.isEnabled else { return }
        
        let contacts = permission.trustedContacts.filter {
            $0.shouldReceive(notificationType: .missedMedication)
        }
        
        guard !contacts.isEmpty else { return }
        
        let alert = generateMissedMedicationAlert(
            for: profile,
            prescription: prescription,
            privacy: permission.privacySettings
        )
        
        for contact in contacts {
            sendNotificationToContact(contact: contact, message: alert, type: .missedMedication)
            updateLastNotified(contactId: contact.id, profileId: profile.id)
        }
    }
    
    func sendEmergencyAlert(for profile: Profile, prescriptions: [Prescription]) {
        guard let permission = sharingPermissions[profile.id],
              permission.isEnabled else { return }
        
        let contacts = permission.trustedContacts.filter {
            $0.shouldReceive(notificationType: .emergency)
        }
        
        guard !contacts.isEmpty else { return }
        
        let alert = generateEmergencyAlert(
            for: profile,
            prescriptions: prescriptions,
            privacy: permission.privacySettings
        )
        
        for contact in contacts {
            sendNotificationToContact(contact: contact, message: alert, type: .emergency)
            updateLastNotified(contactId: contact.id, profileId: profile.id)
        }
    }
    
    // MARK: - Message Generation
    
    private func generateDailySummary(for profile: Profile, prescriptions: [Prescription], privacy: SharingPermission.PrivacySettings) -> String {
        let today = Date()
        let takenCount = prescriptions.filter { $0.isTaken }.count
        let totalCount = prescriptions.count
        let adherenceRate = totalCount > 0 ? (Double(takenCount) / Double(totalCount)) * 100 : 100
        
        var message = "📊 Daily Medication Summary for \(profile.name)\n\n"
        message += "Date: \(DateFormatter.shortDate.string(from: today))\n"
        message += "Medications taken: \(takenCount)/\(totalCount)\n"
        message += "Adherence rate: \(String(format: "%.1f", adherenceRate))%\n\n"
        
        if privacy.shareMedicationNames {
            message += "Medication Status:\n"
            for prescription in prescriptions {
                let status = prescription.isTaken ? "✅ Taken" : "❌ Not taken"
                let medicationName = privacy.shareDosageInformation ? 
                    "\(prescription.name) (\(prescription.dose))" : prescription.name
                message += "• \(medicationName): \(status)\n"
                
                if privacy.shareTimingInformation && prescription.isTaken,
                   let lastTaken = prescription.lastTaken {
                    message += "  Last taken: \(DateFormatter.timeOnly.string(from: lastTaken))\n"
                }
            }
        }
        
        if adherenceRate < 80 {
            message += "\n⚠️ Adherence is below recommended levels. Consider checking in with \(profile.name)."
        }
        
        message += "\n\nSent from Medbox Prescription Manager"
        return message
    }
    
    private func generateMissedMedicationAlert(for profile: Profile, prescription: Prescription, privacy: SharingPermission.PrivacySettings) -> String {
        let medicationName = privacy.shareMedicationNames ? prescription.name : "medication"
        let dosageInfo = privacy.shareDosageInformation && privacy.shareMedicationNames ? " (\(prescription.dose))" : ""
        
        var message = "⚠️ Missed Medication Alert\n\n"
        message += "\(profile.name) has not taken their \(medicationName)\(dosageInfo) as scheduled.\n\n"
        
        if privacy.shareTimingInformation, let reminderTime = prescription.reminderTimes.first?.time {
            message += "Scheduled time: \(DateFormatter.timeOnly.string(from: reminderTime))\n"
        }
        
        message += "Current time: \(DateFormatter.timeOnly.string(from: Date()))\n\n"
        message += "You may want to check in with them to ensure they're okay.\n\n"
        message += "Sent from Medbox Prescription Manager"
        
        return message
    }
    
    private func generateEmergencyAlert(for profile: Profile, prescriptions: [Prescription], privacy: SharingPermission.PrivacySettings) -> String {
        let missedCritical = prescriptions.filter { !$0.isTaken }
        
        var message = "🚨 EMERGENCY: Critical Medication Alert\n\n"
        message += "\(profile.name) has missed multiple critical medications.\n\n"
        
        if privacy.shareMedicationNames {
            message += "Missed medications:\n"
            for prescription in missedCritical {
                let medicationName = privacy.shareDosageInformation ? 
                    "\(prescription.name) (\(prescription.dose))" : prescription.name
                message += "• \(medicationName)\n"
            }
        } else {
            message += "Number of missed medications: \(missedCritical.count)\n"
        }
        
        message += "\nThis is a serious health concern. Please contact \(profile.name) immediately.\n\n"
        
        if !profile.emergencyContact.isEmpty {
            message += "Emergency contact: \(profile.emergencyContact)\n\n"
        }
        
        message += "Sent from Medbox Prescription Manager"
        
        return message
    }
    
    // MARK: - Notification Delivery
    
    private func sendNotificationToContact(contact: TrustedContact, message: String, type: TrustedContact.NotificationType) {
        switch contact.notificationPreferences.preferredContactMethod {
        case .email:
            sendEmailNotification(to: contact, message: message, type: type)
        case .sms:
            sendSMSNotification(to: contact, message: message)
        case .both:
            sendEmailNotification(to: contact, message: message, type: type)
            sendSMSNotification(to: contact, message: message)
        }
    }
    
    private func sendEmailNotification(to contact: TrustedContact, message: String, type: TrustedContact.NotificationType) {
        let subject = getEmailSubject(for: type)
        mailComposer.sendEmail(
            to: contact.email,
            subject: subject,
            body: message
        )
    }
    
    private func sendSMSNotification(to contact: TrustedContact, message: String) {
        guard let phoneNumber = contact.phoneNumber else { return }
        // In a real app, this would integrate with an SMS service
        print("SMS to \(phoneNumber): \(message)")
    }
    
    private func getEmailSubject(for type: TrustedContact.NotificationType) -> String {
        switch type {
        case .dailySummary:
            return "Daily Medication Summary"
        case .missedMedication:
            return "Missed Medication Alert"
        case .weeklySummary:
            return "Weekly Medication Summary"
        case .emergency:
            return "🚨 URGENT: Critical Medication Alert"
        }
    }
    
    private func updateLastNotified(contactId: UUID, profileId: UUID) {
        guard let index = sharingPermissions[profileId]?.trustedContacts.firstIndex(where: { $0.id == contactId }) else { return }
        sharingPermissions[profileId]?.trustedContacts[index].lastNotified = Date()
        saveSharingPermissions()
    }
    
    // MARK: - Data Persistence
    
    private func saveSharingPermissions() {
        if let encoded = try? JSONEncoder().encode(sharingPermissions) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadSharingPermissions() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([UUID: SharingPermission].self, from: data) {
            sharingPermissions = decoded
        }
    }
}

// MARK: - Mail Composer Helper

class MailComposer {
    func sendEmail(to recipient: String, subject: String, body: String) {
        // In a real app, this would use MFMailComposeViewController or a backend service
        print("Email to \(recipient)")
        print("Subject: \(subject)")
        print("Body: \(body)")
        
        // For now, we can use URL scheme to open mail app
        let emailString = "mailto:\(recipient)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let emailURL = URL(string: emailString) {
            DispatchQueue.main.async {
                if UIApplication.shared.canOpenURL(emailURL) {
                    UIApplication.shared.open(emailURL)
                }
            }
        }
    }
}

// MARK: - Date Formatters

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}