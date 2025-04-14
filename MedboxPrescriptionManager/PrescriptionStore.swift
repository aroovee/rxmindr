import Foundation

class PrescriptionStore: ObservableObject {
    static let shared = PrescriptionStore()
    @Published var prescriptions: [Prescription] = []
    private let saveKey = "SavedPrescriptions"
    
    init() {
        loadPrescriptions()
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
            }
        }
    }
    
    func updatePrescription(_ prescription: Prescription) {
        if let index = prescriptions.firstIndex(where: { $0.id == prescription.id }) {
            prescriptions[index] = prescription
            savePrescriptions()
            NotificationManager.shared.updateNotifications(for: prescription)
        }
    }
    
    func deletePrescription(_ prescription: Prescription) {
        prescriptions.removeAll { $0.id == prescription.id }
        savePrescriptions()
        NotificationManager.shared.cancelNotifications(for: prescription)
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
}
