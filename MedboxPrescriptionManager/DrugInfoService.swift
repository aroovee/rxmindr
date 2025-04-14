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

struct DrugInformation: Codable {
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
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration)
    }
    
    func getDrugInformation(for drugName: String) async throws -> DrugInformation {
        print("Fetching drug information for: \(drugName)")
        
        do {
            let rxcui = try await getRxcui(for: drugName)
            print("Found RxCUI: \(rxcui)")
            
            let url = URL(string: "\(baseURL)/rxclass/class/byRxcui.json?rxcui=\(rxcui)")!
            let (data, _) = try await session.data(from: url)
            
            print("Raw class response: \(String(data: data, encoding: .utf8) ?? "")")
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw DrugInfoError.invalidResponse
            }
            
            // Get properties
            let propertiesUrl = URL(string: "\(baseURL)/rxcui/\(rxcui)/properties.json")!
            let (propData, _) = try await session.data(from: propertiesUrl)
            print("Raw properties response: \(String(data: propData, encoding: .utf8) ?? "")")
            
            let uses = extractUses(from: json)
            let sideEffects = extractSideEffects(from: json)
            let contraindications = extractContraindications(from: json)
            let warnings = createWarnings(contraindications: contraindications)
            
            return DrugInformation(
                name: drugName,
                uses: uses,
                sideEffects: sideEffects,
                warnings: warnings,
                contraindications: contraindications
            )
        } catch {
            print("Error fetching drug information: \(error)")
            return DrugInformation(
                name: drugName,
                uses: ["Please consult your healthcare provider for specific use information"],
                sideEffects: ["Contact your healthcare provider for side effect information"],
                warnings: "Always follow your prescription and consult your healthcare provider.",
                contraindications: []
            )
        }
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
    
    private func extractSideEffects(from response: [String: Any]) -> [String] {
        var effects = Set<String>([
            "Nausea", "Diarrhea", "Headache", "Dizziness",
            "Contact your healthcare provider if you experience any severe side effects"
        ])
        
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
