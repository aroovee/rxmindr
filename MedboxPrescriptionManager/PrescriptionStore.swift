import Foundation
import UserNotifications
import UserNotificationsUI
import UIKit

extension Notification.Name {
    static let medicationsReset = Notification.Name("medicationsReset")
}

class PrescriptionStore: ObservableObject {
    static let shared = PrescriptionStore()
    @Published var prescriptions: [Prescription] = []
    @Published var recordManager = MedicationRecordManager()
    @Published var interactionManager = InteractionManager()
    @Published var refillManager: SmartRefillManager!
    @Published var travelManager: TravelModeManager!
    private let saveKey = "SavedPrescriptions"
    
    init() {
        // Initialize managers after other properties are set
        refillManager = SmartRefillManager(medicationRecordManager: recordManager)
        travelManager = TravelModeManager(prescriptionStore: self)
        
        loadPrescriptions()
        // Initialize daily records for today's medications
        initializeTodaysRecords()
        // Set up daily reset notifications
        setupDailyResetTimer()
        // Check interactions for initial prescriptions
        Task {
            await MainActor.run {
                interactionManager.checkInteractions(for: prescriptions)
                refillManager.updateRefillPredictions(for: prescriptions)
            }
        }
        
        // Load travel state if exists
        travelManager.loadTravelState()
    }
    
    func addPrescription(_ prescription: Prescription) {
        Task {
            var newPrescription = prescription
            // Fetch drug information
            do {
                let drugInfo = try await DrugInfoService.shared.getDrugInformation(for: prescription.name)
                newPrescription.drugInfo = drugInfo
            } catch {
                print("Error fetching drug info: \(error)")
            }
            
            DispatchQueue.main.async {
                self.prescriptions.append(newPrescription)
                self.savePrescriptions()
                NotificationManager.shared.scheduleNotification(for: newPrescription)
                
                // Initialize records for this prescription
                self.recordManager.initializeDailyRecords(for: [newPrescription])
                
                // Check for interactions with the new prescription
                self.interactionManager.checkInteractions(for: self.prescriptions)
                
                // Update refill predictions
                self.refillManager.updateRefillPredictions(for: self.prescriptions)
            }
        }
    }
    
    func updatePrescription(_ prescription: Prescription) {
        if let index = prescriptions.firstIndex(where: { $0.id == prescription.id }) {
            prescriptions[index] = prescription
            savePrescriptions()
            NotificationManager.shared.updateNotifications(for: prescription)
            // Check for interactions after update
            interactionManager.checkInteractions(for: prescriptions)
        }
    }
    
    func deletePrescription(_ prescription: Prescription) {
        prescriptions.removeAll { $0.id == prescription.id }
        savePrescriptions()
        NotificationManager.shared.cancelNotifications(for: prescription)
        // Check for interactions after deletion
        interactionManager.checkInteractions(for: prescriptions)
    }
    
    private func savePrescriptions() {
        if let encoded = try? JSONEncoder().encode(prescriptions) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadPrescriptions() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Prescription].self, from: data) {
            prescriptions = decoded
            
            for prescription in prescriptions {
                Task {
                    await refreshDrugInfo(for: prescription)
                }
            }
        }
    }
    
    private func refreshDrugInfo(for prescription: Prescription) async {
        do {
            let drugInfo = try await DrugInfoService.shared.getDrugInformation(for: prescription.name)
            let drugInteractions = DrugInteraction(severity: "", description: "", drug1: "", drug2: "")
            
            DispatchQueue.main.async {
                if let index = self.prescriptions.firstIndex(where: { $0.id == prescription.id }) {
                    var updatedPrescription = self.prescriptions[index]
                    updatedPrescription.drugInfo = drugInfo
                    self.prescriptions[index] = updatedPrescription
                    Task{
                        do{
                            for x in try await drugInteractions.CheckInteractions(){
                                if x.drug1 == prescription.name{
                                    updatedPrescription.hasConflicts = true
                                    updatedPrescription.conflicts.append(x.drug2)
                                }
                                if x.drug2 == prescription.name{
                                    updatedPrescription.hasConflicts = true
                                    updatedPrescription.conflicts.append(x.drug1)
                                }
                                self.savePrescriptions()
                            }
                        }catch{
                            print("Failure")
                        }
                    }
                }
            }
        }catch{
            print("Error refreshing drug info for \(prescription.name) \(error)")
        }
    }
    
    private func initializeTodaysRecords() {
        DispatchQueue.main.async {
            self.recordManager.initializeDailyRecords(for: self.prescriptions)
        }
    }
    
    func markPrescriptionAsTaken(_ prescription: Prescription) {
        if let index = prescriptions.firstIndex(where: { $0.id == prescription.id }) {
            prescriptions[index].isTaken = true
            prescriptions[index].lastTaken = Date()
            
            // Record the medication taken in our tracking system
            recordManager.recordMedicationTaken(prescription: prescription)
            
            // Update refill tracking (reduce pill count)
            refillManager.recordPillTaken(for: &prescriptions[index])
            
            // Record in HealthKit if authorized
            Task {
                await HealthKitManager.shared.recordMedicationTaken(prescription: prescription)
            }
            
            savePrescriptions()
            
            // Update refill predictions after taking medication
            refillManager.updateRefillPredictions(for: prescriptions)
            
            // Cancel any urgent or emergency notifications for this medication
            NotificationManager.shared.cancelUrgentReminders(for: prescription)
            
            // Send daily summary to trusted contacts if it's end of day
            checkAndSendDailySummary()
        }
    }
    
    // MARK: - Daily Reset Functionality
    private func setupDailyResetTimer() {
        // Set up notification to reset medications at midnight
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(dayChanged),
            name: .NSCalendarDayChanged,
            object: nil
        )
        
        // Also listen for app becoming active (in case app was backgrounded overnight)
        notificationCenter.addObserver(
            self,
            selector: #selector(appBecameActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func dayChanged() {
        DispatchQueue.main.async {
            self.resetDailyMedicationStatus()
        }
    }
    
    @objc private func appBecameActive() {
        DispatchQueue.main.async {
            self.checkForMidnightReset()
        }
    }
    
    private func checkForMidnightReset() {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if any medication was last taken on a different day
        var needsReset = false
        for prescription in prescriptions {
            if let lastTaken = prescription.lastTaken {
                if !calendar.isDate(lastTaken, inSameDayAs: now) && prescription.isTaken {
                    needsReset = true
                    break
                }
            }
        }
        
        if needsReset {
            resetDailyMedicationStatus()
        }
    }
    
    private func resetDailyMedicationStatus() {
        let calendar = Calendar.current
        let now = Date()
        
        for index in prescriptions.indices {
            // Reset isTaken status if last taken was not today
            if let lastTaken = prescriptions[index].lastTaken {
                if !calendar.isDate(lastTaken, inSameDayAs: now) {
                    prescriptions[index].isTaken = false
                }
            } else {
                // If never taken, ensure it's marked as not taken
                prescriptions[index].isTaken = false
            }
        }
        
        // Initialize records for today
        initializeTodaysRecords()
        
        savePrescriptions()
        
        // Notify observers of the reset
        NotificationCenter.default.post(name: .medicationsReset, object: nil)
    }
    
    // Check if it's time to send daily summary to trusted contacts
    private func checkAndSendDailySummary() {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        // Send daily summary in the evening (after 6 PM) if we haven't already sent one today
        if hour >= 18 {
            let lastSummaryDate = UserDefaults.standard.object(forKey: "lastDailySummaryDate") as? Date
            if lastSummaryDate == nil || !calendar.isDate(lastSummaryDate!, inSameDayAs: now) {
                sendDailySummaryToTrustedContacts()
                UserDefaults.standard.set(now, forKey: "lastDailySummaryDate")
            }
        }
    }
    
    // Send daily summary to all trusted contacts
    private func sendDailySummaryToTrustedContacts() {
        guard let currentProfile = ProfileStore().currentProfile else { return }
        SharingManager.shared.sendDailySummary(for: currentProfile, prescriptions: prescriptions)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension PrescriptionStore: NotificationManagerDelegate {
    func didMarkAsTaken(prescriptionID: UUID) {
        if let index = prescriptions.firstIndex(where: { $0.id == prescriptionID }) {
            let prescription = prescriptions[index]
            markPrescriptionAsTaken(prescription)
            
            // Send confirmation notification
            NotificationManager.shared.sendImmediateNotification(
                for: prescription,
                message: "\(prescription.name) marked as taken ✓"
            )
        }
    }
    
    func didMarkAsUntaken(prescriptionID: UUID) {
        if let index = prescriptions.firstIndex(where: { $0.id == prescriptionID }) {
            prescriptions[index].isTaken = false
            prescriptions[index].lastTaken = nil
            
            // Record the medication as not taken
            recordManager.recordMedicationNotTaken(prescription: prescriptions[index])
            
            // Record in HealthKit as skipped
            Task {
                await HealthKitManager.shared.recordMedicationSkipped(prescription: prescriptions[index])
            }
            
            savePrescriptions()
            
            // Send confirmation notification
            NotificationManager.shared.sendImmediateNotification(
                for: prescriptions[index],
                message: "\(prescriptions[index].name) marked as not taken"
            )
        }
    }
    
    func didSnoozeMedication(prescriptionID: UUID) {
        // Schedule a snooze notification
        if let prescription = prescriptions.first(where: { $0.id == prescriptionID }) {
            scheduleSnoozeNotification(for: prescription)
        }
    }
    
    private func scheduleSnoozeNotification(for prescription: Prescription) {
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: "Medication Reminder (Snoozed)", arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey:"Time to take \(prescription.name) - \(prescription.dose)",arguments: nil)
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "MEDICATION_REMINDER"
        content.userInfo = [
            "prescriptionID": prescription.id.uuidString,
            "prescriptionName": prescription.name
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15 * 60, repeats: false)
        let request = UNNotificationRequest(
            identifier: "snooze-\(prescription.id.uuidString)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling snooze notification: \(error.localizedDescription)")
            }
        }
    }
}