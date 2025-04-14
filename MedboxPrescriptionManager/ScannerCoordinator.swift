import SwiftUI

class ScannerCoordinator: NSObject, PrescriptionScannerDelegate {
    var prescriptionStore: PrescriptionStore
    var parent: ScannerView
    
    init(prescriptionStore: PrescriptionStore, parent: ScannerView) {
        self.prescriptionStore = prescriptionStore
        self.parent = parent
    }
    
    func didScanPrescription(_ prescriptionInfo: PrescriptionInfo) {
        let newPrescription = Prescription(
            name: prescriptionInfo.medicineName ?? "Unknown",
            dose: prescriptionInfo.dose ?? "Unknown",
            frequency: prescriptionInfo.frequency ?? "Unknown",
            startDate: Date()
        )
        prescriptionStore.addPrescription(newPrescription)
        NotificationManager.shared.scheduleNotification(for: newPrescription)
        parent.isPresented = false
    }
}

struct ScannerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
      @State private var showError = false
      @State private var errorMessage = ""
      var prescriptionStore: PrescriptionStore
      
      func makeUIViewController(context: Context) -> PrescriptionScannerViewController {
          let controller = PrescriptionScannerViewController()
          controller.delegate = context.coordinator
          return controller
      }
    
    func updateUIViewController(_ uiViewController: PrescriptionScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PrescriptionScannerDelegate {
        var parent: ScannerView
        
        init(_ parent: ScannerView) {
            self.parent = parent
        }
        
        func didScanPrescription(_ prescriptionInfo: PrescriptionInfo) {
            let newPrescription = Prescription(
                name: prescriptionInfo.medicineName ?? "Unknown",
                dose: prescriptionInfo.dose ?? "Unknown",
                frequency: prescriptionInfo.frequency ?? "Unknown",
                startDate: Date()
            )
            parent.prescriptionStore.addPrescription(newPrescription)
            parent.isPresented = false
        }
    }
}

