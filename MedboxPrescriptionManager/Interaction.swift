import Foundation


class DrugInteraction {
    init(severity: String, description: String, drug1: String, drug2: String) {
        self.severity = severity
        self.description = description
        self.drug1 = drug1
        self.drug2 = drug2
    }
    let prescriptions = PrescriptionStore.shared.prescriptions
    let baseURL = "https://rxnav.nlm.nih.gov/REST/interaction/list?rxcuis="
    var severity: String
    var description: String
    var drug1: String
    var drug2: String
    
    
    private func createRxCuiList(for drugNames: [String]) async throws -> [String] {
        var rxcuiList: [String] = []
        for name in drugNames {
            if let rxcui = try await DrugInfoService.shared.getRxcui(for: name){
                rxcuiList.append(rxcui)
            }
        }
        return rxcuiList
    }
    
    private func generateLinks (for rxcuiList: [String]) async throws -> [URL]{
        var urlList: [URL] = []
        for x in 0..<(rxcuiList.count){
            for j in (x+1)..<(rxcuiList.count){
                let URLstring = "https://rxnav.nlm.nih.gov/REST/interaction/list?rxcuis=\(rxcuiList[x])+\(rxcuiList[j])"
                let url = URL(string: URLstring)
                urlList.append(url!)
            }
            
            
            
            
        }
        return urlList
    }
    
    
    private func getInteractions(from urls: [URL]) async throws -> [DrugInteraction] {
        var interactions: [DrugInteraction] = []
        
        for urlString in urls {
           
            
            let (data, _) = try await URLSession.shared.data(from: urlString)
            struct InteractionResponse: Codable {
                let fullInteractionTypeGroup: [InteractionGroup]?
                
                struct InteractionGroup: Codable {
                    let fullInteractionType: [InteractionType]
                    
                    struct InteractionType: Codable {
                        let interactionPair: [InteractionPair]
                        
                        struct InteractionPair: Codable {
                            let severity: String
                            let description: String
                            let interactionConcept: [InteractionConcept]
                            
                            struct InteractionConcept: Codable {
                                let minConceptItem: MinConceptItem
                                
                                struct MinConceptItem: Codable {
                                    let name: String
                                }
                            }
                        }
                    }
                }
            }
            
            let decoder = JSONDecoder()
            let response = try decoder.decode(InteractionResponse.self,from: data)
            
            
            if let groups = response.fullInteractionTypeGroup {
                for group in groups {
                    for interactionType in group.fullInteractionType {
                        for pair in interactionType.interactionPair {
                            let interaction = DrugInteraction(
                                severity: pair.severity,
                                description: pair.description,
                                drug1: pair.interactionConcept[0].minConceptItem.name,
                                drug2: pair.interactionConcept[1].minConceptItem.name
                            )
                            interactions.append(interaction)
                        }
                    }
                }
            }
        }
        
        return interactions
    }
    
    public func CheckInteractions() async throws -> [DrugInteraction]{
        let drugNames = prescriptions.map { $0.name }
        
        
        let rxcuis = try await createRxCuiList(for: drugNames)
        
        let urls = try await generateLinks(for: rxcuis)
        
        return try await getInteractions(from: urls)
    }
}



