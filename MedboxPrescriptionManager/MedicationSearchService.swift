import Foundation

struct MedicationSearchResult {
    let name: String
    let score: Double
    let genericName: String?
    let category: String?
}

class MedicationSearchService: ObservableObject {
    static let shared = MedicationSearchService()
    @Published var searchResults: [MedicationSearchResult] = []
    
    // Common medications database - in a real app, this could be loaded from a file or API
    private let medications: [(name: String, generic: String?, category: String?)] = [
        // Pain relievers
        ("Acetaminophen", nil, "Pain Reliever"),
        ("Tylenol", "Acetaminophen", "Pain Reliever"),
        ("Advil", "Ibuprofen", "Pain Reliever"),
        ("Motrin", "Ibuprofen", "Pain Reliever"),
        ("Ibuprofen", nil, "Pain Reliever"),
        ("Aspirin", nil, "Pain Reliever"),
        ("Naproxen", nil, "Pain Reliever"),
        ("Aleve", "Naproxen", "Pain Reliever"),
        
        // Antibiotics
        ("Amoxicillin", nil, "Antibiotic"),
        ("Augmentin", "Amoxicillin/Clavulanate", "Antibiotic"),
        ("Azithromycin", nil, "Antibiotic"),
        ("Z-Pak", "Azithromycin", "Antibiotic"),
        ("Zithromax", "Azithromycin", "Antibiotic"),
        ("Cephalexin", nil, "Antibiotic"),
        ("Keflex", "Cephalexin", "Antibiotic"),
        ("Ciprofloxacin", nil, "Antibiotic"),
        ("Cipro", "Ciprofloxacin", "Antibiotic"),
        ("Clindamycin", nil, "Antibiotic"),
        ("Doxycycline", nil, "Antibiotic"),
        ("Penicillin", nil, "Antibiotic"),
        
        // Blood pressure
        ("Lisinopril", nil, "Blood Pressure"),
        ("Prinivil", "Lisinopril", "Blood Pressure"),
        ("Zestril", "Lisinopril", "Blood Pressure"),
        ("Amlodipine", nil, "Blood Pressure"),
        ("Norvasc", "Amlodipine", "Blood Pressure"),
        ("Metoprolol", nil, "Blood Pressure"),
        ("Lopressor", "Metoprolol", "Blood Pressure"),
        ("Toprol", "Metoprolol", "Blood Pressure"),
        ("Losartan", nil, "Blood Pressure"),
        ("Cozaar", "Losartan", "Blood Pressure"),
        ("Atenolol", nil, "Blood Pressure"),
        ("Tenormin", "Atenolol", "Blood Pressure"),
        
        // Diabetes
        ("Metformin", nil, "Diabetes"),
        ("Glucophage", "Metformin", "Diabetes"),
        ("Insulin", nil, "Diabetes"),
        ("Humalog", "Insulin Lispro", "Diabetes"),
        ("Novolog", "Insulin Aspart", "Diabetes"),
        ("Lantus", "Insulin Glargine", "Diabetes"),
        ("Glipizide", nil, "Diabetes"),
        ("Glucotrol", "Glipizide", "Diabetes"),
        
        // Cholesterol
        ("Atorvastatin", nil, "Cholesterol"),
        ("Lipitor", "Atorvastatin", "Cholesterol"),
        ("Simvastatin", nil, "Cholesterol"),
        ("Zocor", "Simvastatin", "Cholesterol"),
        ("Rosuvastatin", nil, "Cholesterol"),
        ("Crestor", "Rosuvastatin", "Cholesterol"),
        
        // Thyroid
        ("Levothyroxine", nil, "Thyroid"),
        ("Synthroid", "Levothyroxine", "Thyroid"),
        ("Levoxyl", "Levothyroxine", "Thyroid"),
        ("Armour Thyroid", "Thyroid Extract", "Thyroid"),
        
        // Allergy/Asthma
        ("Loratadine", nil, "Allergy"),
        ("Claritin", "Loratadine", "Allergy"),
        ("Cetirizine", nil, "Allergy"),
        ("Zyrtec", "Cetirizine", "Allergy"),
        ("Fexofenadine", nil, "Allergy"),
        ("Allegra", "Fexofenadine", "Allergy"),
        ("Benadryl", "Diphenhydramine", "Allergy"),
        ("Albuterol", nil, "Asthma"),
        ("ProAir", "Albuterol", "Asthma"),
        ("Ventolin", "Albuterol", "Asthma"),
        
        // Antidepressants
        ("Sertraline", nil, "Antidepressant"),
        ("Zoloft", "Sertraline", "Antidepressant"),
        ("Fluoxetine", nil, "Antidepressant"),
        ("Prozac", "Fluoxetine", "Antidepressant"),
        ("Escitalopram", nil, "Antidepressant"),
        ("Lexapro", "Escitalopram", "Antidepressant"),
        ("Citalopram", nil, "Antidepressant"),
        ("Celexa", "Citalopram", "Antidepressant"),
        
        // Stomach/GI
        ("Omeprazole", nil, "Stomach"),
        ("Prilosec", "Omeprazole", "Stomach"),
        ("Pantoprazole", nil, "Stomach"),
        ("Protonix", "Pantoprazole", "Stomach"),
        ("Ranitidine", nil, "Stomach"),
        ("Zantac", "Ranitidine", "Stomach"),
        ("Famotidine", nil, "Stomach"),
        ("Pepcid", "Famotidine", "Stomach"),
        
        // Birth Control
        ("Ortho Tri-Cyclen", "Norgestimate/Ethinyl Estradiol", "Birth Control"),
        ("Yaz", "Drospirenone/Ethinyl Estradiol", "Birth Control"),
        ("Yasmin", "Drospirenone/Ethinyl Estradiol", "Birth Control"),
        ("Lo Loestrin", "Norethindrone/Ethinyl Estradiol", "Birth Control"),
        
        // Sleep
        ("Zolpidem", nil, "Sleep Aid"),
        ("Ambien", "Zolpidem", "Sleep Aid"),
        ("Melatonin", nil, "Sleep Aid"),
        ("Trazodone", nil, "Sleep Aid"),
        
        // Vitamins/Supplements
        ("Vitamin D", nil, "Vitamin"),
        ("Vitamin B12", nil, "Vitamin"),
        ("Iron", nil, "Supplement"),
        ("Calcium", nil, "Supplement"),
        ("Magnesium", nil, "Supplement"),
        ("Fish Oil", nil, "Supplement"),
        ("Omega-3", nil, "Supplement"),
        ("Multivitamin", nil, "Vitamin"),
        
        // Common OTC
        ("Pepto-Bismol", "Bismuth Subsalicylate", "Stomach"),
        ("Tums", "Calcium Carbonate", "Stomach"),
        ("Rolaids", "Calcium Carbonate/Magnesium", "Stomach"),
        ("Sudafed", "Pseudoephedrine", "Decongestant"),
        ("Mucinex", "Guaifenesin", "Expectorant"),
        ("Robitussin", "Dextromethorphan", "Cough Suppressant")
    ]
    
    init() {}
    
    func searchMedications(query: String, limit: Int = 10) -> [MedicationSearchResult] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return []
        }
        
        let results = medications.compactMap { medication -> MedicationSearchResult? in
            let score = fuzzyMatch(query: query.lowercased(), target: medication.name.lowercased())
            
            // Also check generic name if available
            let genericScore: Double
            if let generic = medication.generic {
                genericScore = fuzzyMatch(query: query.lowercased(), target: generic.lowercased())
            } else {
                genericScore = 0.0
            }
            
            let finalScore = max(score, genericScore)
            
            // Only return results with a reasonable match score
            guard finalScore > 0.3 else { return nil }
            
            return MedicationSearchResult(
                name: medication.name,
                score: finalScore,
                genericName: medication.generic,
                category: medication.category
            )
        }
        .sorted { (result1: MedicationSearchResult, result2: MedicationSearchResult) -> Bool in
            return result1.score > result2.score
        }
        .prefix(limit)
        
        return Array(results)
    }
    
    @MainActor
    func performSearch(query: String) {
        searchResults = searchMedications(query: query)
    }
    
    // Fuzzy matching algorithm using Levenshtein distance with additional scoring
    private func fuzzyMatch(query: String, target: String) -> Double {
        // Exact match gets highest score
        if query == target {
            return 1.0
        }
        
        // Check if query is a prefix of target
        if target.hasPrefix(query) {
            return 0.9
        }
        
        // Check if target contains query
        if target.contains(query) {
            return 0.8
        }
        
        // Use Levenshtein distance for fuzzy matching
        let distance = levenshteinDistance(query, target)
        let maxLength = max(query.count, target.count)
        
        if maxLength == 0 {
            return 1.0
        }
        
        let similarity = 1.0 - (Double(distance) / Double(maxLength))
        
        // Additional scoring based on common abbreviations and variations
        let abbreviationBonus = checkAbbreviationMatch(query: query, target: target)
        
        return min(1.0, similarity + abbreviationBonus)
    }
    
    private func checkAbbreviationMatch(query: String, target: String) -> Double {
        // Check for common abbreviations
        let abbreviations: [String: [String]] = [
            "ace": ["acetaminophen"],
            "ibu": ["ibuprofen"],
            "levo": ["levothyroxine"],
            "met": ["metformin"],
            "amox": ["amoxicillin"],
            "lisi": ["lisinopril"],
            "ator": ["atorvastatin"]
        ]
        
        for (abbrev, fullNames) in abbreviations {
            if query == abbrev && fullNames.contains(where: { target.lowercased().contains($0) }) {
                return 0.3
            }
        }
        
        return 0.0
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        
        var matrix = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
        
        for i in 0...a.count {
            matrix[i][0] = i
        }
        
        for j in 0...b.count {
            matrix[0][j] = j
        }
        
        for i in 1...a.count {
            for j in 1...b.count {
                let cost = a[i-1] == b[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,     // deletion
                    matrix[i][j-1] + 1,     // insertion
                    matrix[i-1][j-1] + cost // substitution
                )
            }
        }
        
        return matrix[a.count][b.count]
    }
}