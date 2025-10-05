import UIKit
import Vision
import VisionKit
import NaturalLanguage

protocol PrescriptionScannerDelegate: AnyObject {
    func didScanPrescription(_ prescription: PrescriptionInfo)
}

struct PrescriptionInfo {
        var fullText: String
        var medicineName: String?
        var dose: String?
        var frequency: String?
        var prescriptionNumber: String?
        var fillDate: String?
        var dateOfBirth: String?
        // Add any other relevant fields
}

class PrescriptionScannerViewController: UIViewController, VNDocumentCameraViewControllerDelegate {
    
    weak var delegate: PrescriptionScannerDelegate?
    private let scanButton = UIButton(type: .system)
    private let resultTextView = UITextView()
    public var drugNames: [String] = []
    
    private let commonDrugSuffixes = ["cin", "zole", "pril", "sartan", "olol", "statin", "mab", "zumab", "tinib", "conazole", "mycin", "oxacin", "tidine"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadDrugNames()
        print("PrescriptionScannerViewController loaded")
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        scanButton.setTitle("Scan Prescription", for: .normal)
        scanButton.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        
        resultTextView.isEditable = false
        resultTextView.font = UIFont.systemFont(ofSize: 14)
        resultTextView.text = "Scanned text will appear here"
        
        let stackView = UIStackView(arrangedSubviews: [scanButton, resultTextView])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            scanButton.heightAnchor.constraint(equalToConstant: 44),
            resultTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
    }
    
    private func loadDrugNames() {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to access documents directory")
            return
        }
        let fileURL = documentsURL.appendingPathComponent("drug_names.txt")
        
        print("Attempting to load drug names from: \(fileURL.path)")
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            drugNames = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            print("Successfully loaded \(drugNames.count) drug names")
        } catch {
            print("Error loading drug names: \(error)")
        }
    }
    
    @objc private func scanButtonTapped() {
        print("Scan button tapped")
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = self
        present(documentCameraViewController, animated: true)
    }
    
    // MARK: - VNDocumentCameraViewControllerDelegate
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        print("Document camera finished with \(scan.pageCount) page(s)")
        guard scan.pageCount >= 1 else {
            controller.dismiss(animated: true)
            return
        }
        
        let image = scan.imageOfPage(at: 0)
        controller.dismiss(animated: true) { [weak self] in
            self?.processSelectedImage(image)
        }
    }
    
    func processSelectedImage(_ image: UIImage) {
        print("Processing image")
        guard let cgImage = image.cgImage else {
            print("Failed to get CGImage from UIImage")
            return
        }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            if let error = error {
                print("Text recognition error: \(error.localizedDescription)")
                self?.updateResultText("Error: \(error.localizedDescription)")
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("No text observations found")
                self?.updateResultText("No text found in the image")
                return
            }
            
            let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            print("Recognized text: \(recognizedText)")
            self?.analyzeText(recognizedText)
        }
        
        request.recognitionLevel = .accurate
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform OCR: \(error.localizedDescription)")
            updateResultText("Failed to perform OCR: \(error.localizedDescription)")
        }
    }
    func extractStructuredInfo(from text: String) -> [String: String] {
        var info: [String: String] = [:]
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            if line.contains("RX#") {
                info["prescriptionNumber"] = line.components(separatedBy: "RX#").last?.trimmingCharacters(in: .whitespaces)
            } else if line.contains("Fill Date:") {
                info["fillDate"] = line.components(separatedBy: "Fill Date:").last?.trimmingCharacters(in: .whitespaces)
            } else if line.contains("DOB:") {
                info["dateOfBirth"] = line.components(separatedBy: "DOB:").last?.trimmingCharacters(in: .whitespaces)
            }
            // Add more conditions for other important fields
        }
        
        return info
    }  
    private func analyzeText(_ text: String) {
        var prescription = PrescriptionInfo(fullText: text)
        
        // Improved Medicine Name Detection
        let (medicineName, confidence) = improvedDetectMedicineName(in: text)
        prescription.medicineName = medicineName
        print("Medicine Name: \(medicineName ?? "Not found") (Confidence: \(confidence))")
        
        // Improved Dose Detection
        if let dose = detectDose(in: text, nearDrugName: medicineName) {
            prescription.dose = dose
            print("Dose found: \(dose)")
        } else {
            print("Dose not found")
        }
        
        // Improved Frequency Detection
        if let frequency = detectFrequency(in: text) {
            prescription.frequency = frequency
            print("Frequency found: \(frequency)")
        } else {
            print("Frequency not found")
        }
        
        let analysisResult = """
        Full Text:
        \(prescription.fullText)
        
        Analysis:
        Medicine Name: \(prescription.medicineName ?? "Not found") (Confidence: \(confidence))
        Dose: \(prescription.dose ?? "Not found")
        Frequency: \(prescription.frequency ?? "Not found")
        """
        
        print("Full Analysis Result:")
        print(analysisResult)
        
        updateResultText(analysisResult)
        delegate?.didScanPrescription(prescription)
    }

    private func improvedDetectMedicineName(in text: String) -> (String?, Double) {
            let lines = text.components(separatedBy: .newlines)
            print("Analyzing text for medicine name...")
            
            // First look for exact matches
            for line in lines {
                // Remove parentheses and their contents
                let cleanedLine = line.replacingOccurrences(of: "\\s*\\([^)]*\\)", with: "", options: .regularExpression)
                print("Checking line: \(cleanedLine)")
                
                // Check for common prescription label patterns
                if line.contains("GENERIC NAME:") ||
                   line.contains("Generic for:") ||
                   line.contains("Cap") ||
                   line.contains("Tab") {
                    for drugName in drugNames {
                        if cleanedLine.lowercased().contains(drugName.lowercased()) {
                            print("Found exact match: \(drugName)")
                            return (drugName, 1.0)
                        }
                    }
                }
            }
            
            // If no exact match found, try fuzzy matching
            for line in lines {
                let words = line.components(separatedBy: .whitespaces)
                for word in words {
                    if word.count > 3 {
                        let (match, score) = fuzzyMatch(word, candidates: drugNames)
                        if score > 0.8 {
                            print("Found fuzzy match: \(match ?? "nil") with score: \(score)")
                            return (match, score)
                        }
                    }
                }
            }
            
            print("No medicine name found")
            return (nil, 0.0)
        }
    private func detectDose(in text: String, nearDrugName drugName: String?) -> String? {
        let dosePatterns = [
            "\\b\\d+(\\.\\d+)?\\s*(mg|mcg|g|ml)\\b",
            "\\b\(drugName ?? "")\\s+\\d+(\\.\\d+)?\\s*(mg|mcg|g|ml)\\b"
        ]
        
        for pattern in dosePatterns {
            if let doseRange = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                return String(text[doseRange])
            }
        }
        
        return nil
    }

    private func detectFrequency(in text: String) -> String? {
        let frequencyPatterns = [
            "Take\\s+\\d+\\s+capsule.*morning.*\\d+\\s+capsules?.*evening",
            "Take\\s+\\d+\\s+tablet.*morning.*\\d+\\s+tablets?.*evening",
            "\\b(once|twice|three times|four times|\\d+\\s+times?)\\s+(daily|a day|per day|every day|weekly|monthly)\\b",
            "\\bas needed\\b",
            "\\bevery\\s+(morning|evening|night|day)\\b",
            "\\b\\d+\\s+times?\\s+a\\s+day\\b",
            "\\bnot to exceed \\d+\\s+(tablets?|doses?)\\s+per\\s+day\\b",
            "TAKE\\s+.*\\s+PRIOR TO.*PROCEDURE"
        ]
        
        for pattern in frequencyPatterns {
            if let frequencyRange = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                return String(text[frequencyRange])
            }
        }
        
        return nil
    }
    
    func detectMedicineName(_ text: String) -> (String?, Double) {
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("TABS") || line.contains("GENERIC NAME:") {
                for drugName in drugNames {
                    if line.lowercased().contains(drugName.lowercased()) {
                        return (drugName, 1.0)
                    }
                }
                // If no exact match, try fuzzy matching
                let words = line.components(separatedBy: .whitespaces)
                for word in words {
                    if word.count > 3 {
                        let (match, score) = fuzzyMatch(word, candidates: drugNames)
                        if score > 0.8 {
                            return (match, score)
                        }
                    }
                }
            }
        }
        return (nil, 0.0)
    }

    func fuzzyMatch(_ input: String, candidates: [String]) -> (String?, Double) {
        var bestMatch: (String, Double) = ("", 0)
        for candidate in candidates {
            let distance = levenshteinDistance(input.lowercased(), candidate.lowercased())
            let score = 1 - Double(distance) / Double(max(input.count, candidate.count))
            if score > bestMatch.1 {
                bestMatch = (candidate, score)
            }
        }
        return bestMatch.1 > 0.8 ? bestMatch : (nil, 0)
    }
    
    func levenshteinDistance(_ lhs: String, _ rhs: String) -> Int {
        let lhs = Array(lhs)
        let rhs = Array(rhs)
        var dist = Array(repeating: Array(repeating: 0, count: rhs.count + 1), count: lhs.count + 1)

        for i in 0...lhs.count {
            dist[i][0] = i
        }
        for j in 0...rhs.count {
            dist[0][j] = j
        }

        for i in 1...lhs.count {
            for j in 1...rhs.count {
                if lhs[i-1] == rhs[j-1] {
                    dist[i][j] = dist[i-1][j-1]
                } else {
                    dist[i][j] = min(dist[i-1][j] + 1,
                                     dist[i][j-1] + 1,
                                     dist[i-1][j-1] + 1)
                }
            }
        }
        return dist[lhs.count][rhs.count]
    }
    
    private func detectPotentialDrugNames(_ text: String) -> [(name: String, score: Double)] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var potentialDrugs: [(name: String, score: Double)] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, tokenRange in
            if tag == .personalName || tag == .organizationName {
                let word = String(text[tokenRange])
                if word.count > 3 {
                    let score = scorePotentialDrugName(word)
                    if score > 0.5 {
                        potentialDrugs.append((word, score))
                    }
                }
            }
            return true
        }
        
        return potentialDrugs.sorted(by: { $0.score > $1.score })
    }
    
    private func scorePotentialDrugName(_ name: String) -> Double {
        var score = 0.0
        
        // Check for common drug suffixes
        if commonDrugSuffixes.contains(where: { name.lowercased().hasSuffix($0) }) {
            score += 0.5
        }
        
        // Check for capitalization
        if name.first!.isUppercase {
            score += 0.3
        }
        
        // Check for length (most drug names are between 5 and 15 characters)
        if name.count >= 5 && name.count <= 15 {
            score += 0.2
        }
        
        return score
    }
    
    private func updateResultText(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            self?.resultTextView.text = text
        }
    }
}
