import SwiftUI

struct DrugDetailView: View {
    let drugName: String
    let matchScore: Double
    @ObservedObject var prescriptionStore: PrescriptionStore
    @State private var showingAddPrescription = false
    @State private var drugInfo: DrugInformation?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading drug information...")
                        .padding()
                } else if let error = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .padding()
                    }
                } else if let info = drugInfo {
                    // Drug Name Header
                    Text(info.name)
                        .font(.title)
                        .bold()
                        .padding(.bottom, 5)
                    
                    // Common Uses Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Common Uses")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        ForEach(info.uses, id: \.self) { use in
                            HStack(alignment: .top) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .padding(.top, 7)
                                Text(use)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Side Effects Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Side Effects")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        ForEach(info.sideEffects, id: \.self) { effect in
                            HStack(alignment: .top) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .padding(.top, 7)
                                Text(effect)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Warnings Section
                    if !info.warnings.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Important Warnings")
                                .font(.headline)
                                .foregroundColor(.red)
                            Text(info.warnings)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // Add Prescription Button
                    Button(action: {
                        showingAddPrescription = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Prescription")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.top)
                }
            }
            .padding()
        }
        .navigationBarTitle("Drug Information", displayMode: .inline)
        .sheet(isPresented: $showingAddPrescription) {
            AddPrescriptionView(prescriptionStore: prescriptionStore, prefilledDrugName: drugName)
        }
        .task {
            await loadDrugInformation()
        }
    }
    
    private func loadDrugInformation() async {
        isLoading = true
        do {
            drugInfo = try await DrugInfoService.shared.getDrugInformation(for: drugName)
            print("Successfully loaded drug info: \(String(describing: drugInfo))")
        } catch {
            errorMessage = "Unable to load drug information: \(error.localizedDescription)"
            print("Error loading drug info: \(error)")
        }
        isLoading = false
    }
}
