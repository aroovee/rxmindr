import Foundation

struct DrugSearchResult: Identifiable {
    let id = UUID()
    let name: String
    let score: Double
}

class NDCDatabaseProcessor {
    static var drugNames: Set<String> = []
    static var searchIndex: [String: [String]] = [:]
    static var isLoaded = false
    static var isLoading = false
    private static var searchCache: [String: [DrugSearchResult]] = [:]
    private static let cacheLimit = 100
    private static let processingQueue = DispatchQueue(label: "com.medbox.csv.processing", qos: .utility)
    
    static func processDatabase() {
        // Prevent multiple concurrent processing
        guard !isLoading else { return }
        
        // Start with fallback medications immediately for instant functionality
        loadFallbackMedications()
        
        // Process CSV in background
        processingQueue.async {
            processDatabaseAsync()
        }
    }
    
    private static func processDatabaseAsync() {
        isLoading = true
        
        guard let csvPath = Bundle.main.path(forResource: "20220906_product", ofType: "csv") else {
            print("CSV file not found in bundle - using fallback medications")
            DispatchQueue.main.async {
                isLoading = false
            }
            return
        }
        
        guard let fileHandle = FileHandle(forReadingAtPath: csvPath) else {
            print("Could not open CSV file - using fallback medications")
            DispatchQueue.main.async {
                isLoading = false
            }
            return
        }
        
        defer {
            fileHandle.closeFile()
        }
        
        do {
            // Stream process the file to avoid loading entire file into memory
            try processCSVStream(fileHandle: fileHandle)
        } catch {
            print("Error processing CSV: \(error)")
        }
        
        DispatchQueue.main.async {
            isLoading = false
        }
    }
    
    private static func processCSVStream(fileHandle: FileHandle) throws {
        let chunkSize = 1024 * 1024 // 1MB chunks
        var buffer = Data()
        var processedNames = Set<String>(drugNames) // Start with existing fallback names
        var lineCount = 0
        var isFirstChunk = true
        
        print("Starting streaming CSV processing...")
        
        while true {
            let chunk = fileHandle.readData(ofLength: chunkSize)
            if chunk.isEmpty { break }
            
            buffer.append(chunk)
            
            // Process complete lines from buffer
            while let newlineRange = buffer.range(of: Data([10])) { // ASCII newline
                let lineData = buffer.subdata(in: 0..<newlineRange.lowerBound)
                buffer.removeSubrange(0..<newlineRange.upperBound)
                
                guard let line = String(data: lineData, encoding: .utf8), !line.isEmpty else { continue }
                
                // Skip header row
                if isFirstChunk && lineCount == 0 {
                    isFirstChunk = false
                    lineCount += 1
                    continue
                }
                
                // Process line in chunks to avoid blocking
                if lineCount % 100 == 0 {
                    // Yield control every 100 lines to prevent blocking
                    Thread.sleep(forTimeInterval: 0.001)
                }
                
                // Process the CSV line
                processCSVLine(line, into: &processedNames)
                lineCount += 1
                
                // Update progress periodically
                if lineCount % 5000 == 0 {
                    let currentCount = processedNames.count
                    print("Processed \(lineCount) lines, found \(currentCount) unique drugs...")
                    
                    // Update the main data periodically for progressive enhancement
                    DispatchQueue.main.async {
                        self.drugNames = processedNames
                        self.buildSearchIndex()
                    }
                }
                
                // Safety check to prevent memory issues
                if lineCount > 100000 { // Limit processing to prevent crashes
                    print("Reached processing limit of 100k lines for performance")
                    break
                }
            }
        }
        
        // Process any remaining data in buffer
        if !buffer.isEmpty, let line = String(data: buffer, encoding: .utf8), !line.isEmpty {
            processCSVLine(line, into: &processedNames)
        }
        
        // Final update on main thread
        DispatchQueue.main.async {
            self.drugNames = processedNames
            self.buildSearchIndex()
            self.isLoaded = true
            
            print("CSV processing complete: \(processedNames.count) unique drugs from \(lineCount) records")
            print("Sample drugs: \(Array(processedNames).prefix(10))")
        }
    }
    
    private static func processCSVLine(_ line: String, into processedNames: inout Set<String>) {
        let fields = parseCSVLine(line)
        
        // Get proprietary name (brand name) - column index 3 (0-based)
        // Get non-proprietary name (generic name) - column index 5 (0-based)
        guard fields.count > 5 else { return }
        
        let proprietaryName = fields[3].trimmingCharacters(in: .whitespacesAndNewlines)
        let nonProprietaryName = fields[5].trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add both proprietary (brand) and non-proprietary (generic) names if they exist
        if !proprietaryName.isEmpty && proprietaryName.lowercased() != "null" {
            let processed = processDrugName(proprietaryName)
            if !processed.isEmpty && processed.count > 2 { // Filter very short names
                processedNames.insert(processed)
            }
        }
        
        if !nonProprietaryName.isEmpty && nonProprietaryName.lowercased() != "null" {
            let processed = processDrugName(nonProprietaryName)
            if !processed.isEmpty && processed.count > 2 { // Filter very short names
                processedNames.insert(processed)
            }
        }
    }
    
    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
            
            i = line.index(after: i)
        }
        
        // Add the last field
        fields.append(currentField)
        
        return fields.map { $0.replacingOccurrences(of: "\"", with: "") }
    }
    
    private static func loadFallbackMedications() {
        let fallbackMeds = [
            "Amoxicillin", "Metformin", "Lisinopril", "Ibuprofen", "Aspirin",
            "Tylenol", "Advil", "Lipitor", "Zoloft", "Prozac", "Xanax",
            "Adderall", "Synthroid", "Levothyroxine", "Omeprazole", "Prilosec",
            "Zantac", "Benadryl", "Claritin", "Zyrtec", "Mucinex", "Sudafed",
            "Insulin", "Metoprolol", "Amlodipine", "Simvastatin", "Atorvastatin",
            "Hydrochlorothiazide", "Losartan", "Gabapentin", "Tramadol", "Oxycodone",
            "Morphine", "Codeine", "Prednisone", "Albuterol", "Fluticasone",
            "Montelukast", "Warfarin", "Apixaban", "Clopidogrel", "Furosemide",
            "Acetaminophen", "Naproxen", "Diclofenac", "Celecoxib", "Meloxicam",
            "Hydroxyzine", "Loratadine", "Cetirizine", "Fexofenadine", "Diphenhydramine"
        ]
        
        DispatchQueue.main.async {
            drugNames = Set(fallbackMeds)
            buildSearchIndex()
            isLoaded = true
            print("Loaded \(fallbackMeds.count) fallback medications for immediate use")
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
    
    private static func searchFallbackMedications(for searchText: String) -> [DrugSearchResult] {
        let fallbackMeds = [
            "Amoxicillin", "Metformin", "Lisinopril", "Ibuprofen", "Aspirin",
            "Tylenol", "Advil", "Lipitor", "Zoloft", "Prozac", "Xanax",
            "Adderall", "Synthroid", "Levothyroxine", "Omeprazole", "Prilosec"
        ]
        
        var results: [DrugSearchResult] = []
        
        for med in fallbackMeds {
            let score = calculateMatchScore(searchText: searchText, drugName: med.lowercased())
            if score > 0.3 {
                results.append(DrugSearchResult(name: med, score: score))
            }
        }
        
        results.sort { $0.score > $1.score }
        return Array(results.prefix(10))
    }
    
    private static func buildSearchIndex() {
        searchIndex.removeAll()
        
        for drug in drugNames {
            let normalized = drug.lowercased()
            
            // Create prefixes of different lengths (2-5 characters)
            for prefixLength in 2...min(5, normalized.count) {
                let prefix = String(normalized.prefix(prefixLength))
                
                if searchIndex[prefix] == nil {
                    searchIndex[prefix] = []
                }
                searchIndex[prefix]?.append(drug)
            }
        }
        
        print("Search index built with \(searchIndex.keys.count) prefixes")
    }

    static func fuzzySearchDrugNames(matching searchText: String) -> [DrugSearchResult] {
        let normalizedSearch = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !normalizedSearch.isEmpty else { return [] }
        
        // If still loading, search fallback medications only
        if isLoading && !isLoaded {
            return searchFallbackMedications(for: normalizedSearch)
        }
        
        // Check cache first
        if let cachedResults = searchCache[normalizedSearch] {
            print("Returning cached results for '\(searchText)': \(cachedResults.count) matches")
            return cachedResults
        }
        
        var candidateDrugs: Set<String> = []
        
        // Use prefix-based search index for initial filtering
        let searchPrefix = String(normalizedSearch.prefix(min(3, normalizedSearch.count)))
        
        if let indexedDrugs = searchIndex[searchPrefix] {
            candidateDrugs.formUnion(indexedDrugs)
            print("Index lookup for '\(searchPrefix)' found \(indexedDrugs.count) candidates")
        }
        
        // If prefix search didn't find enough candidates, expand search
        if candidateDrugs.count < 20 {
            for (prefix, drugs) in searchIndex {
                if prefix.contains(searchPrefix) || normalizedSearch.contains(prefix) {
                    candidateDrugs.formUnion(drugs)
                }
            }
        }
        
        // If still not enough candidates, fall back to full search
        if candidateDrugs.isEmpty {
            candidateDrugs = drugNames
        }
        
        var results: [DrugSearchResult] = []
        
        // Score candidates
        for drug in candidateDrugs {
            let processedDrug = drug.lowercased()
            let score = calculateMatchScore(searchText: normalizedSearch, drugName: processedDrug)
            
            if score > 0.25 {  // Slightly higher threshold for better results
                results.append(DrugSearchResult(name: drug, score: score))
            }
        }
        
        // Sort by score descending and limit results
        results.sort { $0.score > $1.score }
        results = Array(results.prefix(50))  // Limit to top 50 results
        
        // Cache results (with size limit)
        if searchCache.count >= cacheLimit {
            // Remove oldest entries
            let keysToRemove = Array(searchCache.keys).prefix(cacheLimit / 2)
            for key in keysToRemove {
                searchCache.removeValue(forKey: key)
            }
        }
        searchCache[normalizedSearch] = results
        
        print("Search for '\(searchText)' found \(results.count) matches from \(candidateDrugs.count) candidates")
        
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
