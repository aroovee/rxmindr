import SwiftUI

struct AddPrescriptionView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var prescriptionStore: PrescriptionStore
    @State private var name: String
    @State private var dose = ""
    @State private var frequency = ""
    @State private var startDate = Date()
    @State private var endDate: Date?
    @State private var dailyFrequency = 1
    @State private var reminderTimes: [Prescription.ReminderTime] = [.init()]
    
    let frequencies = ["Daily", "Twice Daily", "Three Times Daily", "Four Times Daily", "Weekly", "As Needed"]
    
    init(prescriptionStore: PrescriptionStore, prefilledDrugName: String? = nil) {
        self.prescriptionStore = prescriptionStore
        _name = State(initialValue: prefilledDrugName ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Prescription Details")) {
                    TextField("Medicine Name", text: $name)
                    TextField("Dose", text: $dose)
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.self) { freq in
                            Text(freq).tag(freq)
                        }
                    }
                }
                
                Section(header: Text("Dates")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date (Optional)", selection: Binding(
                        get: { self.endDate ?? Date() },
                        set: { self.endDate = $0 }
                    ), displayedComponents: .date)
                }
                
                Section(header: Text("Daily Reminders")) {
                    Stepper("Number of reminders: \(dailyFrequency)",
                            value: $dailyFrequency, in: 1...4)
                    .onChange(of: dailyFrequency) { newValue in
                        updateReminderTimes(count: newValue)
                    }
                    
                    ForEach(Array(reminderTimes.enumerated()), id: \.element.id) { index, _ in
                        HStack {
                            DatePicker("Reminder \(index + 1)",
                                       selection: binding(for: index),
                                       displayedComponents: .hourAndMinute)
                            Toggle("", isOn: enabledBinding(for: index))
                                .labelsHidden()
                        }
                    }
                }
            }
            .navigationBarTitle("Add Prescription", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    savePrescription()
                }
            )
        }
    }
    
    private func binding(for index: Int) -> Binding<Date> {
        Binding(
            get: { self.reminderTimes[index].time },
            set: { self.reminderTimes[index].time = $0 }
        )
    }
    
    private func enabledBinding(for index: Int) -> Binding<Bool> {
        Binding(
            get: { self.reminderTimes[index].isEnabled },
            set: { self.reminderTimes[index].isEnabled = $0 }
        )
    }
    
    private func updateReminderTimes(count: Int) {
        if count > reminderTimes.count {
            // Add new reminder times
            let hoursSpacing = 24 / count
            while reminderTimes.count < count {
                let nextTime = Calendar.current.date(
                    bySettingHour: hoursSpacing * reminderTimes.count,
                    minute: 0,
                    second: 0,
                    of: Date()
                ) ?? Date()
                reminderTimes.append(.init(time: nextTime))
            }
        } else {
            // Remove excess reminder times
            reminderTimes = Array(reminderTimes.prefix(count))
        }
    }
    
    private func savePrescription() {
        let newPrescription = Prescription(
            name: name,
            dose: dose,
            frequency: frequency,
            dailyFrequency: dailyFrequency, // Include this
            startDate: startDate,
            endDate: endDate,
            reminderTimes: reminderTimes
        )
        prescriptionStore.addPrescription(newPrescription)
        NotificationManager.shared.scheduleNotification(for: newPrescription)
        presentationMode.wrappedValue.dismiss()
    }
}
