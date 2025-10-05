import Foundation
import SwiftUI

class InteractionManager: ObservableObject {
    @Published var activeInteractions: [DrugInteraction] = []
    @Published var isChecking = false
    @Published var hasActiveInteractions = false
    
    private let drugInfoService = DrugInfoService.shared
    private var checkingTask: Task<Void, Never>?
    
    // Common drug interaction database for quick checking
    private let knownInteractions: [String: [String: InteractionSeverity]] = [
        "warfarin": [
            "aspirin": .high,
            "ibuprofen": .moderate,
            "acetaminophen": .low
        ],
        "metformin": [
            "alcohol": .moderate,
            "furosemide": .moderate
        ],
        "lisinopril": [
            "potassium": .high,
            "ibuprofen": .moderate
        ],
        "atorvastatin": [
            "gemfibrozil": .high,
            "niacin": .moderate
        ],
        "digoxin": [
            "furosemide": .high,
            "quinidine": .high,
            "verapamil": .moderate
        ]
    ]
    
    enum InteractionSeverity: String, CaseIterable {
        case low = "Minor"
        case moderate = "Moderate" 
        case high = "Major"
        
        var color: Color {
            switch self {
            case .low: return .yellow
            case .moderate: return .orange
            case .high: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "exclamationmark.triangle.fill"
            case .moderate: return "exclamationmark.triangle.fill"
            case .high: return "xmark.octagon.fill"
            }
        }
    }
    
    func checkInteractions(for prescriptions: [Prescription]) {
        // Cancel any existing task
        checkingTask?.cancel()
        
        checkingTask = Task { [weak self] in
            await self?.performInteractionCheck(prescriptions: prescriptions)
        }
    }
    
    @MainActor
    private func performInteractionCheck(prescriptions: [Prescription]) async {
        guard !prescriptions.isEmpty else {
            activeInteractions = []
            hasActiveInteractions = false
            isChecking = false
            return
        }
        
        isChecking = true
        var foundInteractions: [DrugInteraction] = []
        
        // First check known interactions (fast)
        let quickInteractions = checkKnownInteractions(prescriptions: prescriptions)
        foundInteractions.append(contentsOf: quickInteractions)
        
        // Then check API interactions (slower) 
        do {
            let apiInteractions = try await checkAPIInteractions(prescriptions: prescriptions)
            foundInteractions.append(contentsOf: apiInteractions)
        } catch {
            print("Error checking API interactions: \(error)")
        }
        
        // Remove duplicates
        let uniqueInteractions = removeDuplicateInteractions(foundInteractions)
        
        activeInteractions = uniqueInteractions
        hasActiveInteractions = !uniqueInteractions.isEmpty
        isChecking = false
    }
    
    private func checkKnownInteractions(prescriptions: [Prescription]) -> [DrugInteraction] {
        var interactions: [DrugInteraction] = []
        let drugNames = prescriptions.map { $0.name.lowercased() }
        
        for i in 0..<drugNames.count {
            for j in (i+1)..<drugNames.count {
                let drug1 = drugNames[i]
                let drug2 = drugNames[j]
                
                // Check both directions
                if let interactions1 = knownInteractions[drug1],
                   let severity = interactions1[drug2] {
                    let interaction = DrugInteraction(
                        severity: severity.rawValue,
                        description: "Known interaction between \(drug1.capitalized) and \(drug2.capitalized). Consult your healthcare provider.",
                        drug1: drug1.capitalized,
                        drug2: drug2.capitalized
                    )
                    interactions.append(interaction)
                }
                
                if let interactions2 = knownInteractions[drug2],
                   let severity = interactions2[drug1] {
                    let interaction = DrugInteraction(
                        severity: severity.rawValue,
                        description: "Known interaction between \(drug2.capitalized) and \(drug1.capitalized). Consult your healthcare provider.",
                        drug1: drug2.capitalized,
                        drug2: drug1.capitalized
                    )
                    interactions.append(interaction)
                }
            }
        }
        
        return interactions
    }
    
    private func checkAPIInteractions(prescriptions: [Prescription]) async throws -> [DrugInteraction] {
        let drugInteractionChecker = DrugInteraction(severity: "", description: "", drug1: "", drug2: "")
        return try await drugInteractionChecker.CheckInteractions()
    }
    
    private func removeDuplicateInteractions(_ interactions: [DrugInteraction]) -> [DrugInteraction] {
        var uniqueInteractions: [DrugInteraction] = []
        var seenPairs: Set<String> = []
        
        for interaction in interactions {
            let pair1 = "\(interaction.drug1.lowercased())-\(interaction.drug2.lowercased())"
            let pair2 = "\(interaction.drug2.lowercased())-\(interaction.drug1.lowercased())"
            
            if !seenPairs.contains(pair1) && !seenPairs.contains(pair2) {
                uniqueInteractions.append(interaction)
                seenPairs.insert(pair1)
                seenPairs.insert(pair2)
            }
        }
        
        return uniqueInteractions
    }
    
    func getInteractionSeverity(_ interaction: DrugInteraction) -> InteractionSeverity {
        switch interaction.severity.lowercased() {
        case "minor", "low":
            return .low
        case "moderate", "medium":
            return .moderate
        case "major", "high", "severe":
            return .high
        default:
            return .moderate
        }
    }
    
    func getInteractionsFor(prescription: Prescription) -> [DrugInteraction] {
        return activeInteractions.filter { interaction in
            interaction.drug1.lowercased() == prescription.name.lowercased() ||
            interaction.drug2.lowercased() == prescription.name.lowercased()
        }
    }
    
    func hasInteractions(for prescription: Prescription) -> Bool {
        return !getInteractionsFor(prescription: prescription).isEmpty
    }
    
    func getHighestSeverityFor(prescription: Prescription) -> InteractionSeverity? {
        let prescriptionInteractions = getInteractionsFor(prescription: prescription)
        return prescriptionInteractions.map { getInteractionSeverity($0) }.max { severity1, severity2 in
            switch (severity1, severity2) {
            case (.low, .moderate), (.low, .high), (.moderate, .high):
                return true
            default:
                return false
            }
        }
    }
}