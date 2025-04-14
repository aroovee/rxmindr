import SwiftUI

struct SymptomMatcherView: View {
    @ObservedObject var prescriptionStore: PrescriptionStore
    @State private var selectedSymptoms = Set<String>()
    @State private var matchResults: [SymptomMatch] = []
    @State private var showingResults = false
    
    
    let commonSymptoms = [
        "Nausea",
        "Diarrhea",
        "Headache",
        "Dizziness",
        "Fatigue",
        "Rash",
        "Drowsiness",
        "Insomnia",
        "Stomach Pain",
        "Dry Mouth",
        "Joint Pain",
        "Anxiety",
        "Depression",
        "Loss of Appetite",
        "Blurred Vision",
        "Constipation",
        "Muscle Pain",
        "Chest Pain",
        "Cough",
        "Fever"
    ].sorted()
    
    var body: some View {
        NavigationView {
            VStack {
                if showingResults && !matchResults.isEmpty {
                    MatchResultsView(results: matchResults)
                } else {
                    SymptomSelectionView(
                        selectedSymptoms: $selectedSymptoms,
                        commonSymptoms: commonSymptoms
                    )
                }
                
                // Action Button
                if !selectedSymptoms.isEmpty {
                    Button(action: {
                        if showingResults {
                            // Reset
                            selectedSymptoms.removeAll()
                            matchResults.removeAll()
                            showingResults = false
                        } else {
                            // Analyze
                            analyzeSymptoms()
                            showingResults = true
                        }
                    }) {
                        HStack {
                            Image(systemName: showingResults ? "arrow.counterclockwise" : "magnifyingglass")
                            Text(showingResults ? "Start Over" : "Analyze Symptoms")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Symptom Matcher")
        }
    }
    
    private func analyzeSymptoms() {
        matchResults = prescriptionStore.prescriptions.compactMap { prescription in
            guard let drugInfo = prescription.drugInfo else { return nil }
            
            let matchedSymptoms = selectedSymptoms.filter { symptom in
                drugInfo.sideEffects.contains { effect in
                    effect.localizedCaseInsensitiveContains(symptom)
                }
            }
            
            if !matchedSymptoms.isEmpty {
                return SymptomMatch(
                    medication: prescription.name,
                    matchedSymptoms: Array(matchedSymptoms),
                    confidence: Double(matchedSymptoms.count) / Double(selectedSymptoms.count)
                )
            }
            return nil
        }
        .sorted { $0.confidence > $1.confidence }
    }
}

struct SymptomSelectionView: View {
    @Binding var selectedSymptoms: Set<String>
    let commonSymptoms: [String]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Select your symptoms:")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(commonSymptoms, id: \.self) { symptom in
                        SymptomButton(
                            symptom: symptom,
                            isSelected: selectedSymptoms.contains(symptom),
                            action: {
                                if selectedSymptoms.contains(symptom) {
                                    selectedSymptoms.remove(symptom)
                                } else {
                                    selectedSymptoms.insert(symptom)
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }
}

struct SymptomButton: View {
    let symptom: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(symptom)
                    .font(.subheadline)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(8)
        }
    }
}

struct MatchResultsView: View {
    let results: [SymptomMatch]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                ForEach(results) { match in
                    MatchResultCard(match: match)
                }
            }
            .padding()
        }
    }
}

struct MatchResultCard: View {
    let match: SymptomMatch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(match.medication)
                    .font(.headline)
                Spacer()
                Text("\(Int(match.confidence * 100))% match")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            Text("Possible side effects:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ForEach(match.matchedSymptoms, id: \.self) { symptom in
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                    Text(symptom)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct SymptomMatch: Identifiable {
    let id = UUID()
    let medication: String
    let matchedSymptoms: [String]
    let confidence: Double
}
