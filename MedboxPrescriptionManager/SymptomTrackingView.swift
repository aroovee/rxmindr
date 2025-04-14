import SwiftUI

struct SymptomTrackingView: View {
    @ObservedObject var prescriptionStore: PrescriptionStore
    @StateObject private var symptomTracker = SymptomTracker()
    @State private var selectedSymptoms = Set<String>()
    @State private var showingResults = false
    @State private var relatedMedications: [String: [String]] = [:]
    
    var body: some View {
        NavigationView {
            VStack {
                // Symptom Selection
                List {
                    Section(header: Text("Select Your Symptoms")) {
                        ForEach(Array(symptomTracker.commonSymptoms).sorted(), id: \.self) { symptom in
                            MultipleSelectionRow(title: symptom,
                                               isSelected: selectedSymptoms.contains(symptom)) {
                                if selectedSymptoms.contains(symptom) {
                                    selectedSymptoms.remove(symptom)
                                } else {
                                    selectedSymptoms.insert(symptom)
                                }
                            }
                        }
                    }
                }
                
                // Analysis Button
                if !selectedSymptoms.isEmpty {
                    Button(action: {
                        analyzeSymptoms()
                        showingResults = true
                    }) {
                        Text("Analyze Symptoms")
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
            .navigationTitle("Symptom Tracker")
            .sheet(isPresented: $showingResults) {
                SymptomResultsView(medications: relatedMedications)
            }
        }
    }
    
    private func analyzeSymptoms() {
        relatedMedications = symptomTracker.findRelatedMedications(
            for: selectedSymptoms,
            in: prescriptionStore.prescriptions
        )
    }
}

struct MultipleSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

struct SymptomResultsView: View {
    let medications: [String: [String]]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                if medications.isEmpty {
                    Section {
                        Text("No direct correlations found between your symptoms and current medications.")
                            .foregroundColor(.gray)
                    }
                } else {
                    ForEach(medications.keys.sorted(), id: \.self) { medication in
                        Section(header: Text(medication)) {
                            ForEach(medications[medication] ?? [], id: \.self) { symptom in
                                Text("May cause: \(symptom)")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Potential Causes")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
