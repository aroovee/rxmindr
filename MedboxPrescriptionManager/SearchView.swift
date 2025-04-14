import SwiftUI

struct SearchView: View {
    @ObservedObject var prescriptionStore: PrescriptionStore
    @State private var searchText = ""
    @State private var searchResults: [DrugSearchResult] = []
    @State private var isLoading = false
    @State private var debugMessage = ""
    
    let commonMedications = ["Amoxicillin", "Metformin", "Lisinopril", "Ibuprofen"]
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search medications...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: searchText) { newValue in
                            performSearch(query: newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                
                // Debug Info (remove in production)
                if !debugMessage.isEmpty {
                    Text(debugMessage)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
                
                // Search Results
                if isLoading {
                    ProgressView()
                        .padding()
                } else if !searchText.isEmpty {
                    if searchResults.isEmpty {
                        VStack(spacing: 10) {
                            Text("No medications found")
                                .font(.headline)
                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else {
                        List(searchResults) { result in
                            NavigationLink(
                                destination: DrugDetailView(
                                    drugName: result.name,
                                    matchScore: result.score,
                                    prescriptionStore: prescriptionStore
                                )
                            ) {
                                VStack(alignment: .leading) {
                                    Text(result.name)
                                        .font(.headline)
                                    Text("Match: \(Int(result.score * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                } else {
                    // Common Medications
                    VStack(alignment: .leading) {
                        Text("Common Medications")
                            .font(.headline)
                            .padding()
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 10) {
                            ForEach(commonMedications, id: \.self) { medication in
                                Button(action: {
                                    searchText = medication
                                    performSearch(query: medication)
                                }) {
                                    Text(medication)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Search")
        }
        .onAppear {
            // Verify database is loaded
            debugMessage = "Database loaded: \(NDCDatabaseProcessor.isLoaded)\nDrugs count: \(NDCDatabaseProcessor.drugNames.count)"
        }
    }
    
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        
        // Debounce search
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let results = NDCDatabaseProcessor.fuzzySearchDrugNames(matching: query)
            searchResults = results
            debugMessage = "Found \(results.count) matches for '\(query)'"
            isLoading = false
        }
    }
}
