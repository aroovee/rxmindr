import Foundation

struct Symptom: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let severity: SeverityLevel
    let dateReported: Date
    let relatedMedications: [String]  // Names of medications that might cause this
    
    enum SeverityLevel: String, CaseIterable {
        case mild = "Mild"
        case moderate = "Moderate"
        case severe = "Severe"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class SymptomTracker: ObservableObject {
    @Published var symptoms: [Symptom] = []
    @Published var commonSymptoms: Set<String> = [
        "Nausea", "Diarrhea", "Headache", "Dizziness", "Rash",
        "Fatigue", "Stomach Pain", "Vomiting", "Allergic Reaction",
        "Joint Pain", "Drowsiness", "Insomnia", "Anxiety",
        "Loss of Appetite", "Dry Mouth"
    ]
    
    func addSymptom(_ symptom: Symptom) {
        symptoms.append(symptom)
    }
    
    func findRelatedMedications(for symptoms: Set<String>, in prescriptions: [Prescription]) -> [String: [String]] {
        var medicationSymptoms: [String: [String]] = [:]
        
        for prescription in prescriptions {
            if let drugInfo = prescription.drugInfo {
                let sideEffects = Set(drugInfo.sideEffects.map { $0.lowercased() })
                let matchingSymptoms = symptoms.filter {
                    sideEffects.contains($0.lowercased())
                }
                
                if !matchingSymptoms.isEmpty {
                    medicationSymptoms[prescription.name] = Array(matchingSymptoms)
                }
            }
        }
        
        return medicationSymptoms
    }
}
