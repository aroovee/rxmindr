import Foundation
import SwiftUI

class SmartRefillManager: ObservableObject {
    @Published var refillAlerts: [RefillAlert] = []
    @Published var lowInventoryMedications: [Prescription] = []
    
    private let medicationRecordManager: MedicationRecordManager
    
    init(medicationRecordManager: MedicationRecordManager) {
        self.medicationRecordManager = medicationRecordManager
    }
    
    // MARK: - Smart Refill Predictions
    
    func updateRefillPredictions(for prescriptions: [Prescription]) {
        var alerts: [RefillAlert] = []
        var lowInventory: [Prescription] = []
        
        for prescription in prescriptions {
            // Calculate refill prediction based on usage patterns
            if let prediction = calculateRefillPrediction(for: prescription) {
                if prediction.daysRemaining <= 7 {
                    let alert = RefillAlert(
                        prescription: prescription,
                        prediction: prediction,
                        alertType: prediction.daysRemaining <= 3 ? .critical : .warning
                    )
                    alerts.append(alert)
                    lowInventory.append(prescription)
                }
            }
        }
        
        DispatchQueue.main.async {
            self.refillAlerts = alerts
            self.lowInventoryMedications = lowInventory
        }
    }
    
    func calculateRefillPrediction(for prescription: Prescription) -> RefillPrediction? {
        guard let totalPills = prescription.totalPills,
              let pillsRemaining = prescription.pillsRemaining else {
            return nil
        }
        
        // Get actual usage pattern from medication records
        let actualUsagePattern = calculateActualUsagePattern(for: prescription)
        let averageDailyUsage = actualUsagePattern.averageDailyUsage
        
        // Calculate days remaining based on actual usage
        let daysRemaining = averageDailyUsage > 0 ? Int(Double(pillsRemaining) / averageDailyUsage) : 0
        
        // Calculate predicted refill date
        let refillDate = Calendar.current.date(byAdding: .day, value: daysRemaining, to: Date()) ?? Date()
        
        // Calculate adherence rate
        let adherenceRate = actualUsagePattern.adherenceRate
        
        // Determine confidence level based on data quality
        let confidence = calculatePredictionConfidence(
            prescription: prescription,
            usagePattern: actualUsagePattern
        )
        
        return RefillPrediction(
            daysRemaining: daysRemaining,
            predictedRefillDate: refillDate,
            averageDailyUsage: averageDailyUsage,
            adherenceRate: adherenceRate,
            confidence: confidence,
            recommendedRefillDate: Calendar.current.date(byAdding: .day, value: -5, to: refillDate) ?? refillDate,
            usagePattern: actualUsagePattern
        )
    }
    
    private func calculateActualUsagePattern(for prescription: Prescription) -> UsagePattern {
        let records = medicationRecordManager.getRecords(for: prescription.id)
        let last30Days = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // Filter records for the last 30 days
        let recentRecords = records.filter { $0.date >= last30Days }

        // Calculate adherence
        let totalExpectedDoses = prescription.dailyFrequency * 30
        let actualTakenDoses = recentRecords.filter { $0.takenDoses > 0 }.count
        let adherenceRate = totalExpectedDoses > 0 ? Double(actualTakenDoses) / Double(totalExpectedDoses) : 0.0
        
        // Calculate average daily usage
        let takenDaysCount = Set(recentRecords.filter { $0.takenDoses > 0 }.map { 
            Calendar.current.startOfDay(for: $0.date) 
        }).count
        let averageDailyUsage = takenDaysCount > 0 ? Double(actualTakenDoses) / Double(takenDaysCount) : 0.0
        
        // Analyze usage consistency
        let consistencyScore = calculateUsageConsistency(records: recentRecords, prescription: prescription)
        
        return UsagePattern(
            averageDailyUsage: averageDailyUsage,
            adherenceRate: adherenceRate,
            consistencyScore: consistencyScore,
            dataPoints: recentRecords.count,
            periodDays: 30
        )
    }
    
    private func calculateUsageConsistency(records: [DailyMedicationRecord], prescription: Prescription) -> Double {
        let expectedDailyDoses = prescription.dailyFrequency
        let recordsByDay = Dictionary(grouping: records) { 
            Calendar.current.startOfDay(for: $0.date)
        }
        
        var consistencyScores: [Double] = []
        
        for (_, dayRecords) in recordsByDay {
            let takenCount = dayRecords.filter { $0.takenDoses > 0 }.count
            let consistencyForDay = min(Double(takenCount) / Double(expectedDailyDoses), 1.0)
            consistencyScores.append(consistencyForDay)
        }
        
        guard !consistencyScores.isEmpty else { return 0.0 }
        
        let average = consistencyScores.reduce(0, +) / Double(consistencyScores.count)
        let variance = consistencyScores.map { pow($0 - average, 2) }.reduce(0, +) / Double(consistencyScores.count)
        
        return max(0, 1.0 - sqrt(variance))
    }
    
    private func calculatePredictionConfidence(prescription: Prescription, usagePattern: UsagePattern) -> PredictionConfidence {
        var confidenceScore = 0.0
        
        // Data quantity factor (more data = higher confidence)
        let dataQuantityFactor = min(Double(usagePattern.dataPoints) / 30.0, 1.0)
        confidenceScore += dataQuantityFactor * 0.3
        
        // Consistency factor (consistent usage = higher confidence)
        confidenceScore += usagePattern.consistencyScore * 0.4
        
        // Adherence factor (regular adherence = more predictable)
        let adherenceFactor = usagePattern.adherenceRate > 0.7 ? usagePattern.adherenceRate : 0.5
        confidenceScore += adherenceFactor * 0.3
        
        switch confidenceScore {
        case 0.8...1.0: return .high
        case 0.5..<0.8: return .medium
        default: return .low
        }
    }
    
    // MARK: - Pill Consumption Tracking
    
    func recordPillTaken(for prescription: inout Prescription) {
        guard let pillsRemaining = prescription.pillsRemaining, pillsRemaining > 0 else {
            return
        }
        
        prescription.pillsRemaining = pillsRemaining - 1
        
        // If running very low, create immediate alert
        if prescription.pillsRemaining ?? 0 <= 3 {
            let prediction = RefillPrediction(
                daysRemaining: prescription.pillsRemaining ?? 0,
                predictedRefillDate: Date(),
                averageDailyUsage: Double(prescription.dailyFrequency),
                adherenceRate: 1.0,
                confidence: .high,
                recommendedRefillDate: Date(),
                usagePattern: UsagePattern(
                    averageDailyUsage: Double(prescription.dailyFrequency),
                    adherenceRate: 1.0,
                    consistencyScore: 1.0,
                    dataPoints: 1,
                    periodDays: 1
                )
            )
            
            let alert = RefillAlert(
                prescription: prescription,
                prediction: prediction,
                alertType: .critical
            )
            
            // Capture the prescription ID to avoid capturing inout parameter
            let prescriptionId = prescription.id
            
            DispatchQueue.main.async {
                if !self.refillAlerts.contains(where: { $0.prescription.id == prescriptionId }) {
                    self.refillAlerts.append(alert)
                }
            }
        }
    }
    
    // MARK: - Refill Recommendations
    
    func getRefillRecommendations() -> [RefillRecommendation] {
        return refillAlerts.compactMap { alert in
            guard let prediction = alert.prediction else { return nil }
            
            return RefillRecommendation(
                prescription: alert.prescription,
                urgency: alert.alertType == .critical ? .immediate : .soon,
                recommendedRefillDate: prediction.recommendedRefillDate,
                daysRemaining: prediction.daysRemaining,
                confidence: prediction.confidence,
                reason: generateRecommendationReason(for: alert)
            )
        }.sorted { $0.urgency.rawValue < $1.urgency.rawValue }
    }
    
    private func generateRecommendationReason(for alert: RefillAlert) -> String {
        guard let prediction = alert.prediction else {
            return "Refill needed based on current inventory."
        }
        
        let daysRemaining = prediction.daysRemaining
        let adherenceRate = Int(prediction.adherenceRate * 100)
        
        switch alert.alertType {
        case .critical:
            return "Critical: Only \(daysRemaining) days remaining. Refill immediately."
        case .warning:
            return "Based on your \(adherenceRate)% adherence rate, you'll need a refill in \(daysRemaining) days."
        }
    }
}

// MARK: - Supporting Data Types

struct RefillPrediction {
    let daysRemaining: Int
    let predictedRefillDate: Date
    let averageDailyUsage: Double
    let adherenceRate: Double
    let confidence: PredictionConfidence
    let recommendedRefillDate: Date
    let usagePattern: UsagePattern
}

struct UsagePattern {
    let averageDailyUsage: Double
    let adherenceRate: Double
    let consistencyScore: Double
    let dataPoints: Int
    let periodDays: Int
}

struct RefillAlert: Identifiable {
    let id = UUID()
    let prescription: Prescription
    let prediction: RefillPrediction?
    let alertType: RefillAlertType
    let timestamp = Date()
}

struct RefillRecommendation: Identifiable {
    let id = UUID()
    let prescription: Prescription
    let urgency: RefillUrgency
    let recommendedRefillDate: Date
    let daysRemaining: Int
    let confidence: PredictionConfidence
    let reason: String
}

enum RefillAlertType {
    case warning, critical
    
    var color: Color {
        switch self {
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}

enum RefillUrgency: Int, CaseIterable {
    case immediate = 0
    case soon = 1
    case planned = 2
    
    var displayName: String {
        switch self {
        case .immediate: return "Immediate"
        case .soon: return "Soon"
        case .planned: return "Planned"
        }
    }
    
    var color: Color {
        switch self {
        case .immediate: return .red
        case .soon: return .orange
        case .planned: return .blue
        }
    }
}

enum PredictionConfidence: String, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var color: Color {
        switch self {
        case .high: return .green
        case .medium: return .yellow
        case .low: return .red
        }
    }
    
    var description: String {
        switch self {
        case .high: return "High confidence based on consistent usage data"
        case .medium: return "Medium confidence with moderate usage data"
        case .low: return "Low confidence - consider manual tracking"
        }
    }
}
