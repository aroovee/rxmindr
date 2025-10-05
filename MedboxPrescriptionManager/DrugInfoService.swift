import Foundation

enum DrugInfoError: Error {
    case invalidURL
    case invalidResponse
    case drugNotFound
    case networkError
}

struct RxNormResponse: Codable {
    let idGroup: IdGroup?
}

struct IdGroup: Codable {
    let rxnormId: [String]
}

struct DrugInformation: Codable, Equatable {
    let name: String
    let uses: [String]
    let sideEffects: [String]
    let warnings: String
    let contraindications: [String]
    
    init(name: String,
         uses: [String] = ["Consult healthcare provider for specific uses"],
         sideEffects: [String] = ["Consult healthcare provider for side effects"],
         warnings: String = "Always follow your prescription and consult your healthcare provider.",
         contraindications: [String] = []) {
        self.name = name
        self.uses = uses
        self.sideEffects = sideEffects
        self.warnings = warnings
        self.contraindications = contraindications
    }
}

class DrugInfoService {
    static let shared = DrugInfoService()
    private let baseURL = "https://rxnav.nlm.nih.gov/REST"
    private let session: URLSession
    private var infoCache: [String: DrugInformation] = [:]
    private let cacheLimit = 50
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15  // Reduced timeout
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        self.session = URLSession(configuration: configuration)
    }
    
    func getDrugInformation(for drugName: String) async throws -> DrugInformation {
        let normalizedName = drugName.lowercased()
        
        // Check cache first
        if let cachedInfo = infoCache[normalizedName] {
            print("Returning cached info for: \(drugName)")
            return cachedInfo
        }
        
        print("Fetching drug information for: \(drugName)")
        
        do {
            // Try to get RxCUI first
            guard let rxcui = try await getRxcui(for: drugName) else {
                print("Could not find RxCUI for \(drugName), using fallback data")
                return createFallbackInformation(for: drugName)
            }
            
            print("Found RxCUI: \(rxcui)")
            
            // Fetch drug class information
            let classInfo = await fetchDrugClassInfo(rxcui: rxcui)
            
            // Extract information from class data
            let uses = extractUses(from: classInfo)
            let sideEffects = extractSideEffects(from: classInfo, drugName: drugName)
            let contraindications = extractContraindications(from: classInfo)
            let warnings = createWarnings(contraindications: contraindications)
            
            let drugInfo = DrugInformation(
                name: drugName,
                uses: uses.isEmpty ? generateCommonUses(for: drugName) : uses,
                sideEffects: sideEffects,
                warnings: warnings,
                contraindications: contraindications
            )
            
            // Cache the result
            cacheInformation(drugInfo, for: normalizedName)
            
            return drugInfo
            
        } catch {
            print("Error fetching drug information: \(error)")
            return createFallbackInformation(for: drugName)
        }
    }
    
    private func fetchDrugClassInfo(rxcui: String) async -> [String: Any] {
        do {
            let url = URL(string: "\(baseURL)/rxclass/class/byRxcui.json?rxcui=\(rxcui)")!
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Invalid response from drug class API")
                return [:]
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("Failed to parse drug class response")
                return [:]
            }
            
            return json
            
        } catch {
            print("Error fetching drug class info: \(error)")
            return [:]
        }
    }
    
    private func cacheInformation(_ info: DrugInformation, for key: String) {
        if infoCache.count >= cacheLimit {
            // Remove oldest entries
            let keysToRemove = Array(infoCache.keys).prefix(cacheLimit / 2)
            for key in keysToRemove {
                infoCache.removeValue(forKey: key)
            }
        }
        infoCache[key] = info
    }
    
    private func createFallbackInformation(for drugName: String) -> DrugInformation {
        return DrugInformation(
            name: drugName,
            uses: generateCommonUses(for: drugName),
            sideEffects: generateCommonSideEffects(for: drugName),
            warnings: "Always follow your prescription and consult your healthcare provider for complete information.",
            contraindications: []
        )
    }
    
    private func generateCommonUses(for drugName: String) -> [String] {
        let commonMedUses: [String: [String]] = [
            "amoxicillin": ["Bacterial infections", "Pneumonia", "Bronchitis", "Urinary tract infections"],
            "metformin": ["Type 2 diabetes", "Blood sugar control", "PCOS treatment"],
            "lisinopril": ["High blood pressure", "Heart failure", "Kidney protection in diabetes"],
            "ibuprofen": ["Pain relief", "Inflammation", "Fever reduction", "Headaches"],
            "aspirin": ["Pain relief", "Heart attack prevention", "Stroke prevention", "Anti-inflammatory"],
            "tylenol": ["Pain relief", "Fever reduction", "Headaches"],
            "lipitor": ["High cholesterol", "Heart disease prevention", "Stroke prevention"]
        ]
        
        let normalizedName = drugName.lowercased()
        for (key, uses) in commonMedUses {
            if normalizedName.contains(key) || key.contains(normalizedName) {
                return uses
            }
        }
        
        return ["Please consult your healthcare provider for specific use information"]
    }
    
    private func generateCommonSideEffects(for drugName: String) -> [String] {
        let commonSideEffects: [String: [String]] = [
            "amoxicillin": ["Nausea", "Diarrhea", "Stomach upset", "Allergic reactions"],
            "metformin": ["Nausea", "Diarrhea", "Stomach upset", "Lactic acidosis (rare)"],
            "lisinopril": ["Dry cough", "Dizziness", "Fatigue", "Headache"],
            "ibuprofen": ["Stomach upset", "Heartburn", "Dizziness", "Headache"],
            "aspirin": ["Stomach upset", "Bleeding risk", "Heartburn", "Nausea"],
            "tylenol": ["Liver damage (with overdose)", "Allergic reactions", "Skin rash"],
            "lipitor": ["Muscle pain", "Liver problems", "Digestive issues", "Headache"]
        ]
        
        let normalizedName = drugName.lowercased()
        for (key, effects) in commonSideEffects {
            if normalizedName.contains(key) || key.contains(normalizedName) {
                var result = effects
                result.append("Contact your healthcare provider if you experience severe side effects")
                return result
            }
        }
        
        return [
            "Nausea", "Dizziness", "Headache",
            "Contact your healthcare provider for complete side effect information"
        ]
    }
    
    private func extractUses(from response: [String: Any]) -> [String] {
        if let drugInfo = response["rxclassDrugInfoList"] as? [String: Any],
           let items = drugInfo["rxclassDrugInfo"] as? [[String: Any]] {
            return items.compactMap { item in
                if let conceptItem = item["rxclassMinConceptItem"] as? [String: Any],
                   let className = conceptItem["className"] as? String,
                   let rela = item["rela"] as? String,
                   rela == "may_treat" {
                    return className
                }
                return nil
            }
        }
        return []
    }
    
    private func extractSideEffects(from response: [String: Any], drugName: String) -> [String] {
        var effects = Set<String>()
        
        // Extract side effects from API response
        if let drugInfo = response["rxclassDrugInfoList"] as? [String: Any],
           let items = drugInfo["rxclassDrugInfo"] as? [[String: Any]] {
            items.forEach { item in
                if let conceptItem = item["rxclassMinConceptItem"] as? [String: Any],
                   let className = conceptItem["className"] as? String,
                   let rela = item["rela"] as? String,
                   rela == "has_pe" {
                    effects.insert("May cause: \(className)")
                }
            }
        }
        
        // If no specific side effects found, use fallback data
        if effects.isEmpty {
            return generateCommonSideEffects(for: drugName)
        }
        
        // Always add general advisory
        effects.insert("Contact your healthcare provider if you experience any severe side effects")
        
        return Array(effects)
    }
    
    private func extractContraindications(from response: [String: Any]) -> [String] {
        var contraindications = Set<String>()
        
        if let drugInfo = response["rxclassDrugInfoList"] as? [String: Any],
           let items = drugInfo["rxclassDrugInfo"] as? [[String: Any]] {
            items.forEach { item in
                if let conceptItem = item["rxclassMinConceptItem"] as? [String: Any],
                   let className = conceptItem["className"] as? String,
                   let rela = item["rela"] as? String,
                   rela == "ci_with" {
                    contraindications.insert(className)
                }
            }
        }
        
        return Array(contraindications)
    }
    
    private func createWarnings(contraindications: [String]) -> String {
        var warnings = [
            "Important Safety Information:",
            "• Follow prescribed dosage carefully",
            "• Complete full course of medication unless directed otherwise",
            "• Store as directed",
            "• Keep out of reach of children",
            "• Contact your healthcare provider if you experience severe side effects"
        ]
        
        if !contraindications.isEmpty {
            warnings.append("\nContraindications:")
            contraindications.forEach { warning in
                warnings.append("• \(warning)")
            }
        }
        
        return warnings.joined(separator: "\n")
    }
    
    public func getRxcui(for drugName: String) async throws -> String?{
        guard let encodedName = drugName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/rxcui.json?name=\(encodedName)") else {
            throw DrugInfoError.invalidURL
        }
        
        print("Requesting RxCUI from URL: \(url.absoluteString)")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DrugInfoError.invalidResponse
        }
        
        print("Response status code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 200 {
            let response = try JSONDecoder().decode(RxNormResponse.self, from: data)
            if let rxcui = response.idGroup?.rxnormId.first {
                print("Found RxCUI: \(rxcui)")
                return rxcui
            }
        }
        
        throw DrugInfoError.drugNotFound
    }
}
