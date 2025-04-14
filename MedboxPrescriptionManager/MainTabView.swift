import SwiftUI

struct MainTabView: View {
    @StateObject private var prescriptionStore = PrescriptionStore()
    
    var body: some View {
        TabView {
            PrescriptionListView(prescriptionStore: prescriptionStore)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Prescriptions")
                }
            
            SearchView(prescriptionStore: prescriptionStore)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            
            SymptomMatcherView(prescriptionStore: prescriptionStore)
                .tabItem {
                    Image(systemName: "heart.text.square")
                    Text("Symptoms")
                }
            
            ScanView(prescriptionStore: prescriptionStore)
                .tabItem {
                    Image(systemName: "camera")
                    Text("Scan")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
    }
}

// Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}   
