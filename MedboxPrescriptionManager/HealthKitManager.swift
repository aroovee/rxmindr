import Foundation
import HealthKit
import SwiftUI

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    // HealthKit data types we want to work with
    private let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)
    private let bloodPressureTypes: Set<HKQuantityType> = [
        HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!,
        HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
    ]
    
    // Use mindful session as a placeholder for medication tracking
    private let medicationDoseEvent = HKCategoryType.categoryType(forIdentifier: .mindfulSession)
    
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return false
        }
        
        let typesToWrite: Set<HKSampleType> = [
            medicationDoseEvent!
        ]
        
        let typesToRead: Set<HKObjectType> = [
            medicationDoseEvent!,
            heartRateType!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .height)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            await MainActor.run {
                self.checkAuthorizationStatus()
            }
            return isAuthorized
        } catch {
            print("HealthKit authorization error: \(error.localizedDescription)")
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        guard let medicationDoseEvent = medicationDoseEvent else { return }
        
        authorizationStatus = healthStore.authorizationStatus(for: medicationDoseEvent)
        isAuthorized = authorizationStatus == .sharingAuthorized
    }
    
    // MARK: - Medication Adherence Tracking
    func recordMedicationTaken(prescription: Prescription, takenAt: Date = Date()) async -> Bool {
        guard isAuthorized, let medicationDoseEvent = medicationDoseEvent else {
            return false
        }
        
        let metadata: [String: Any] = [
            "MedicationDose": prescription.dose,
            "MedicationName": prescription.name,
            "PrescriptionID": prescription.id.uuidString,
            "ActionType": "taken"
        ]
        
        let medicationSample = HKCategorySample(
            type: medicationDoseEvent,
            value: 0, // Using 0 for taken
            start: takenAt,
            end: takenAt,
            metadata: metadata
        )
        
        do {
            try await healthStore.save(medicationSample)
            print("Successfully recorded medication dose in HealthKit: \(prescription.name)")
            return true
        } catch {
            print("Error saving medication dose to HealthKit: \(error.localizedDescription)")
            return false
        }
    }
    
    func recordMedicationSkipped(prescription: Prescription, skippedAt: Date = Date()) async -> Bool {
        guard isAuthorized, let medicationDoseEvent = medicationDoseEvent else {
            return false
        }
        
        let metadata: [String: Any] = [
            "MedicationDose": prescription.dose,
            "MedicationName": prescription.name,
            "PrescriptionID": prescription.id.uuidString,
            "ActionType": "skipped"
        ]
        
        let medicationSample = HKCategorySample(
            type: medicationDoseEvent,
            value: 1, // Using 1 for skipped
            start: skippedAt,
            end: skippedAt,
            metadata: metadata
        )
        
        do {
            try await healthStore.save(medicationSample)
            print("Successfully recorded skipped medication in HealthKit: \(prescription.name)")
            return true
        } catch {
            print("Error saving skipped medication to HealthKit: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Data Retrieval
    func fetchMedicationAdherenceData(for days: Int = 30) async -> [MedicationAdherenceEntry] {
        guard isAuthorized, let medicationDoseEvent = medicationDoseEvent else {
            return []
        }
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: medicationDoseEvent,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                
                if let error = error {
                    print("Error fetching medication data: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }
                
                let adherenceEntries = samples?.compactMap { sample -> MedicationAdherenceEntry? in
                    guard let categorySample = sample as? HKCategorySample else { return nil }
                    
                    let medicationName = categorySample.metadata?["MedicationName"] as? String ?? "Unknown"
                    let dosage = categorySample.metadata?["MedicationDose"] as? String ?? ""
                    let prescriptionID = categorySample.metadata?["PrescriptionID"] as? String ?? ""
                    
                    let adherenceType: MedicationAdherenceType = categorySample.value == 0 ? .taken : .skipped
                    
                    return MedicationAdherenceEntry(
                        id: UUID(),
                        medicationName: medicationName,
                        dosage: dosage,
                        prescriptionID: prescriptionID,
                        date: categorySample.startDate,
                        adherenceType: adherenceType
                    )
                } ?? []
                
                continuation.resume(returning: adherenceEntries)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Health Metrics
    func fetchLatestHeartRate() async -> Double? {
        guard let heartRateType = heartRateType else { return nil }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                
                if let error = error {
                    print("Error fetching heart rate: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: heartRate)
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchAdherenceStatistics(for days: Int = 30) async -> AdherenceStatistics {
        let entries = await fetchMedicationAdherenceData(for: days)
        
        let totalDoses = entries.count
        let takenDoses = entries.filter { $0.adherenceType == .taken }.count
        let adherenceRate = totalDoses > 0 ? Double(takenDoses) / Double(totalDoses) * 100 : 0
        
        let medicationBreakdown = Dictionary(grouping: entries) { $0.medicationName }
            .mapValues { entries in
                let total = entries.count
                let taken = entries.filter { $0.adherenceType == .taken }.count
                return Double(taken) / Double(total) * 100
            }
        
        return AdherenceStatistics(
            totalDoses: totalDoses,
            takenDoses: takenDoses,
            adherenceRate: adherenceRate,
            medicationBreakdown: medicationBreakdown,
            periodDays: days
        )
    }
}

// MARK: - Supporting Data Types
struct MedicationAdherenceEntry: Identifiable, Codable {
    let id: UUID
    let medicationName: String
    let dosage: String
    let prescriptionID: String
    let date: Date
    let adherenceType: MedicationAdherenceType
}

enum MedicationAdherenceType: String, Codable, CaseIterable {
    case taken = "taken"
    case skipped = "skipped"
    
    var displayName: String {
        switch self {
        case .taken: return "Taken"
        case .skipped: return "Skipped"
        }
    }
    
    var color: Color {
        switch self {
        case .taken: return .green
        case .skipped: return .orange
        }
    }
}

struct AdherenceStatistics {
    let totalDoses: Int
    let takenDoses: Int
    let adherenceRate: Double
    let medicationBreakdown: [String: Double]
    let periodDays: Int
    
    var adherenceGrade: AdherenceGrade {
        switch adherenceRate {
        case 95...100: return .excellent
        case 85..<95: return .good
        case 70..<85: return .fair
        case 50..<70: return .poor
        default: return .critical
        }
    }
}

enum AdherenceGrade: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .yellow
        case .poor: return .orange
        case .critical: return .red
        }
    }
    
    var description: String {
        switch self {
        case .excellent: return "Outstanding adherence! Keep it up!"
        case .good: return "Good adherence with room for improvement"
        case .fair: return "Fair adherence - consider setting more reminders"
        case .poor: return "Poor adherence - please consult your healthcare provider"
        case .critical: return "Critical - immediate attention needed"
        }
    }
}