import SwiftUI

struct PrescriptionListView: View {
    @ObservedObject var prescriptionStore: PrescriptionStore
    @State private var showingAddPrescription = false
    @State private var showingScanner = false
    @State private var searchText = ""
    @State private var showOverdueOnly = false
    
    private var filteredPrescriptions: [Prescription] {
        let prescriptions = prescriptionStore.prescriptions
        
        let filtered = prescriptions.filter { prescription in
            if searchText.isEmpty {
                return true
            }
            return prescription.name.localizedCaseInsensitiveContains(searchText)
        }
        
        if showOverdueOnly {
            return filtered.filter { prescription in
                guard let lastTaken = prescription.lastTaken else { return true }
                let frequency = Calendar.current.dateComponents([.hour], from: lastTaken, to: Date()).hour ?? 0
                return frequency >= 24 
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search medications...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    Toggle("Show Overdue Only", isOn: $showOverdueOnly)
                        .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemGroupedBackground))
                
                // Prescription List
                List {
                    ForEach(filteredPrescriptions.indices, id: \.self) { index in
                        let prescription = filteredPrescriptions[index]
                        NavigationLink(
                            destination: PrescriptionDetailView(
                                prescriptionStore: prescriptionStore,
                                prescription: binding(for: prescription)
                            )
                        ) {
                            PrescriptionRow(prescription: prescription)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                markAsTaken(prescription)
                            } label: {
                                Label("Take", systemImage: "checkmark.circle.fill")
                            }
                            .tint(.green)
                        }
                    }
                    .onDelete(perform: deletePrescriptions)
                }
                
                // No Results View
                if filteredPrescriptions.isEmpty {
                    NoResultsView(searchText: searchText, showingOverdueOnly: showOverdueOnly)
                }
            }
            .navigationTitle("My Prescriptions")
            .navigationBarItems(trailing: HStack(spacing: 16) {
                Button(action: {
                    showingScanner = true
                }) {
                    Image(systemName: "camera")
                        .font(.system(size: 18))
                }
                
                Button(action: {
                    showingAddPrescription = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18))
                }
            })
            .sheet(isPresented: $showingAddPrescription) {
                AddPrescriptionView(prescriptionStore: prescriptionStore)
            }
            .sheet(isPresented: $showingScanner) {
                ScannerView(isPresented: $showingScanner, prescriptionStore: prescriptionStore)
            }
        }
    }
    
    private func binding(for prescription: Prescription) -> Binding<Prescription> {
        guard let index = prescriptionStore.prescriptions.firstIndex(where: { $0.id == prescription.id }) else {
            fatalError("Prescription not found")
        }
        return $prescriptionStore.prescriptions[index]
    }
    
    private func markAsTaken(_ prescription: Prescription) {
        var updatedPrescription = prescription
        updatedPrescription.isTaken = true
        updatedPrescription.lastTaken = Date()
        prescriptionStore.updatePrescription(updatedPrescription)
    }
    
    private func deletePrescriptions(at offsets: IndexSet) {
        offsets.forEach { index in
            let prescription = filteredPrescriptions[index]
            prescriptionStore.deletePrescription(prescription)
        }
    }
}

// Subviews
struct PrescriptionRow: View {
    let prescription: Prescription
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading) {
                    Text(prescription.name)
                        .font(.headline)
                    Text(prescription.dose)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if prescription.isTaken {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if isOverdue {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                }
                
            }
            
            HStack {
                Text(prescription.frequency)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if let lastTaken = prescription.lastTaken {
                    Spacer()
                    Text("Last taken: \(formatDate(lastTaken))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
        .background(
            prescription.hasConflicts ? Color.red.opacity(0.7) :
            Color(.systemBackground)
        )
    }
    
    private var isOverdue: Bool {
        guard let lastTaken = prescription.lastTaken else { return false }
        let hours = Calendar.current.dateComponents([.hour], from: lastTaken, to: Date()).hour ?? 0
        return hours >= 24
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct NoResultsView: View {
    let searchText: String
    let showingOverdueOnly: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            if !searchText.isEmpty {
                Text("No medications found matching '\(searchText)'")
                    .font(.headline)
            } else if showingOverdueOnly {
                Text("No overdue medications")
                    .font(.headline)
            } else {
                Text("No medications added yet")
                    .font(.headline)
            }
            
            Text("Tap + to add a new prescription")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

// Preview
struct PrescriptionListView_Previews: PreviewProvider {
    static var previews: some View {
        PrescriptionListView(prescriptionStore: PrescriptionStore())
    }
}
