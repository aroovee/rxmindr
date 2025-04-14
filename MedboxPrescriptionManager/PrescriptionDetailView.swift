import SwiftUI

struct PrescriptionDetailView: View {
    @ObservedObject var prescriptionStore: PrescriptionStore
    @Binding var prescription: Prescription
    @State private var showingShareSheet = false
    @State private var dailyFrequency: Int
    
    init(prescriptionStore: PrescriptionStore, prescription: Binding<Prescription>) {
        self.prescriptionStore = prescriptionStore
        self._prescription = prescription
        self._dailyFrequency = State(initialValue: prescription.wrappedValue.reminderTimes.count)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Details")) {
                TextField("Name", text: $prescription.name)
                TextField("Dose", text: $prescription.dose)
                TextField("Frequency", text: $prescription.frequency)
            }
            
            Section(header: Text("Dates")) {
                DatePicker("Start Date", selection: $prescription.startDate, displayedComponents: .date)
                if let endDate = prescription.endDate {
                    DatePicker("End Date", selection: Binding(
                        get: { endDate },
                        set: { prescription.endDate = $0 }
                    ), displayedComponents: .date)
                }
            }
            
            Section(header: Text("Daily Reminders")) {
                Stepper("Number of reminders: \(dailyFrequency)", value: $dailyFrequency, in: 1...4)
                    .onChange(of: dailyFrequency) { newValue in
                        updateReminderTimes(count: newValue)
                    }
                
                ForEach(Array(prescription.reminderTimes.enumerated()), id: \.element.id) { index, reminder in
                    HStack {
                        DatePicker(
                            "Reminder \(index + 1)",
                            selection: reminderTimeBinding(for: index),
                            displayedComponents: .hourAndMinute
                        )
                        
                        Spacer()
                        
                        Toggle("", isOn: reminderEnabledBinding(for: index))
                            .labelsHidden()
                    }
                }
            }
            
            Section(header: Text("Status")) {
                Toggle("Taken", isOn: $prescription.isTaken)
                if let lastTaken = prescription.lastTaken {
                    Text("Last taken: \(formatDate(lastTaken))")
                }
            }
            
            Section {
                Button(action: {
                    showingShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Status")
                    }
                }
                
                Button("Save Changes") {
                    prescriptionStore.updatePrescription(prescription)
                    NotificationManager.shared.updateNotifications(for: prescription)
                }
            }
        }
        .navigationBarTitle(prescription.name)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [generateSharingText()])
        }
    }
    
    private func updateReminderTimes(count: Int) {
        var updatedTimes = prescription.reminderTimes
        
        if count > updatedTimes.count {
            // Add new reminder times
            let hoursSpacing = 24 / count
            while updatedTimes.count < count {
                let nextTime = Calendar.current.date(
                    bySettingHour: hoursSpacing * updatedTimes.count,
                    minute: 0,
                    second: 0,
                    of: Date()
                ) ?? Date()
                updatedTimes.append(Prescription.ReminderTime(time: nextTime))
            }
        } else {
            // Remove excess reminder times
            updatedTimes = Array(updatedTimes.prefix(count))
        }
        
        prescription.reminderTimes = updatedTimes
    }
    
    private func reminderTimeBinding(for index: Int) -> Binding<Date> {
        Binding(
            get: { prescription.reminderTimes[index].time },
            set: { newTime in
                var updatedTimes = prescription.reminderTimes
                updatedTimes[index].time = newTime
                prescription.reminderTimes = updatedTimes
            }
        )
    }
    
    private func reminderEnabledBinding(for index: Int) -> Binding<Bool> {
        Binding(
            get: { prescription.reminderTimes[index].isEnabled },
            set: { newValue in
                var updatedTimes = prescription.reminderTimes
                updatedTimes[index].isEnabled = newValue
                prescription.reminderTimes = updatedTimes
            }
        )
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func generateSharingText() -> String {
        var text = """
        Medication Status Update
        
        Medication: \(prescription.name)
        Dose: \(prescription.dose)
        Frequency: \(prescription.frequency)
        Status: \(prescription.isTaken ? "Taken" : "Not taken")
        Conflicts: \(prescription.hasConflicts ? "Has conflicts" : "No conflicts")
        
        Reminder Times:
        """
        
        for (index, reminder) in prescription.reminderTimes.enumerated() {
            text += "\n\(index + 1). \(formatTime(reminder.time)) (\(reminder.isEnabled ? "Enabled" : "Disabled"))"
        }
        
        if let lastTaken = prescription.lastTaken {
            text += "\n\nLast taken: \(formatDate(lastTaken))"
        }
        
        if let endDate = prescription.endDate {
            text += "\nEnd Date: \(formatDate(endDate))"
        }
        let conflicts = prescription.conflicts
        text += "\nConflicts: \(conflicts)"
        
        
        return text
    }
}

// ShareSheet wrapper remains the same
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
