import Foundation

struct DrugSearchResult: Identifiable {
    let id = UUID()
    let name: String
    let score: Double
}

class NDCDatabaseProcessor {
    static var drugNames: Set<String> = []  // Changed to Set for uniqueness
    static var isLoaded = false
    
    static func processDatabase() {
        guard let csvPath = Bundle.main.path(forResource: "20220906_product", ofType: "csv") else {
              print("CSV file not found in bundle")
              return
          }
          
          let fileManager = FileManager.default
          guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
              print("Unable to access documents directory")
              return
          }
          
          let fileURL = documentsURL.appendingPathComponent("drug_names.txt")
        do {
            let content = try String(contentsOfFile: csvPath, encoding: .utf8)
            let rawDrugNames = content.components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
            
            // Process and deduplicate drug names
            var processedNames = Set<String>()
            
            for drugName in rawDrugNames {
                let processed = processDrugName(drugName)
                if !processed.isEmpty {
                    processedNames.insert(processed)
                }
            }
            
            drugNames = processedNames
            isLoaded = true
            
            print("Successfully loaded \(drugNames.count) unique drug names")
            print("Sample drugs: \(Array(drugNames).prefix(5))")
        } catch {
            print("Error reading CSV: \(error)")
            print("Error loading drug names: \(error)")
        }
    }
    
    private static func processDrugName(_ name: String) -> String {
        var processed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common suffixes and prefixes that create duplicates
        let suffixesToRemove = [
            " TABS", " TAB", " CAPSULE", " CAP", " TABLET", " INJECTION",
            " ORAL", " SOLUTION", " SUSPENSION", " MG", " ML", " EXTENDED RELEASE",
            " ER", " XR", " SR", " DR", " IR"
        ]
        
        for suffix in suffixesToRemove {
            if processed.hasSuffix(suffix) {
                processed = String(processed.dropLast(suffix.count))
            }
        }
        
        // Remove strength information (e.g., "500MG", "10 MG", etc.)
        processed = processed.replacingOccurrences(
            of: "\\s*\\d+\\s*(MG|MCG|G|ML)\\b",
            with: "",
            options: .regularExpression
        )
        
        // Remove parenthetical information
        processed = processed.replacingOccurrences(
            of: "\\s*\\([^)]*\\)",
            with: "",
            options: .regularExpression
        )
        
        // Normalize spacing
        processed = processed.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        
        // Final trim
        processed = processed.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Convert to title case for consistency
        processed = processed.capitalized
        
        return processed
    }

    static func fuzzySearchDrugNames(matching searchText: String) -> [DrugSearchResult] {
        print("Searching for: \(searchText)")
        print("Database loaded: \(isLoaded)")
        print("Total unique drugs in database: \(drugNames.count)")
        
        let searchText = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !searchText.isEmpty else { return [] }
        
        var results: [DrugSearchResult] = []
        let processedSearch = processDrugName(searchText).lowercased()
        
        for drug in drugNames {
            let processedDrug = drug.lowercased()
            
            // Calculate match score
            let score = calculateMatchScore(searchText: processedSearch, drugName: processedDrug)
            
            if score > 0.2 {
                results.append(DrugSearchResult(
                    name: drug,  // Use original name for display
                    score: score
                ))
            }
        }
        
        // Sort by score and remove duplicates
        results.sort { $0.score > $1.score }
        
        // Debug print results
        print("Found \(results.count) unique matches")
        results.prefix(5).forEach { print("Match: \($0.name) - Score: \($0.score)") }
        
        return results
    }
    
    private static func calculateMatchScore(searchText: String, drugName: String) -> Double {
        var score = 0.0
        
        // Exact match
        if drugName == searchText {
            return 1.0
        }
        
        // Starts with search text
        if drugName.hasPrefix(searchText) {
            score += 0.8
        }
        
        // Contains search text
        if drugName.contains(searchText) {
            score += 0.6
        }
        
        // Word matching
        let searchWords = searchText.split(separator: " ")
        let drugWords = drugName.split(separator: " ")
        
        for searchWord in searchWords {
            for drugWord in drugWords {
                if drugWord == searchWord {
                    score += 0.4
                } else if drugWord.hasPrefix(String(searchWord)) {
                    score += 0.3
                }
            }
        }
        
        // Levenshtein distance for fuzzy matching
        let distance = levenshteinDistance(searchText, drugName)
        let lengthScore = 1.0 - (Double(distance) / Double(max(searchText.count, drugName.count)))
        score += lengthScore * 0.2
        
        return min(max(score, 0.0), 1.0)
    }
    
    private static func levenshteinDistance(_ first: String, _ second: String) -> Int {
        let str1Array = Array(first)
        let str2Array = Array(second)
        var matrix = Array(repeating: Array(repeating: 0, count: str2Array.count + 1), count: str1Array.count + 1)
        
        for i in 0...str1Array.count {
            matrix[i][0] = i
        }
        for j in 0...str2Array.count {
            matrix[0][j] = j
        }
        
        for i in 1...str1Array.count {
            for j in 1...str2Array.count {
                if str1Array[i - 1] == str2Array[j - 1] {
                    matrix[i][j] = matrix[i - 1][j - 1]
                } else {
                    matrix[i][j] = min(
                        matrix[i - 1][j] + 1,
                        matrix[i][j - 1] + 1,
                        matrix[i - 1][j - 1] + 1
                    )
                }
            }
        }
        
        return matrix[str1Array.count][str2Array.count]
    }
}
