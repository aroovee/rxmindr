import SwiftUI

struct ScanView: View {
    @ObservedObject var prescriptionStore: PrescriptionStore
    @State private var isShowingScanner = false
    
    var body: some View {
        NavigationView {
            VStack {
                Button(action: {
                    isShowingScanner = true
                }) {
                    Image(systemName: "camera")
                        .font(.largeTitle)
                        .padding()
                    Text("Scan Prescription")
                }
            }
            .navigationBarTitle("Scan Prescription")
        }
        .sheet(isPresented: $isShowingScanner) {
            ScannerView(isPresented: $isShowingScanner, prescriptionStore: prescriptionStore)
        }
    }
}
