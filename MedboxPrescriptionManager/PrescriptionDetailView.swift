import SwiftUI

struct PrescriptionDetailView: View {
    @ObservedObject var prescriptionStore: PrescriptionStore
    @Binding var prescription: Prescription
    @State private var showingShareSheet = false
    @State private var dailyFrequency: Int
    @State private var prescriptionNotes: String = "Enter prescription notes"
    @State private var selectedMethod: String = "Injection"
    var methods: [String] = ["Injection", "Tablet", "Liquid", "IV", "Rectal"]
    
    init(prescriptionStore: PrescriptionStore, prescription: Binding<Prescription>) {
        self.prescriptionStore = prescriptionStore
        self._prescription = prescription
        self._dailyFrequency = State(initialValue: prescription.wrappedValue.reminderTimes.count)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                MedicationHeaderCard(prescription: prescription)
                
                MedicationDetailsCard(
                    prescription: $prescription,
                    selectedMethod: $selectedMethod,
                    methods: methods
                )
                
                DateSettingsCard(prescription: $prescription)
                
                RemindersCard(
                    prescription: $prescription,
                    dailyFrequency: $dailyFrequency,
                    updateReminderTimes: updateReminderTimes,
                    reminderTimeBinding: reminderTimeBinding,
                    reminderEnabledBinding: reminderEnabledBinding
                )
                
                StatusCard(
                    prescription: $prescription,
                    formatDate: formatDate
                )
                
                NotesCard(prescriptionNotes: $prescriptionNotes)
                
                ActionsCard(
                    showingShareSheet: $showingShareSheet,
                    prescriptionStore: prescriptionStore,
                    prescription: prescription
                )
            }
            .padding()
        }
        .navigationTitle(prescription.name)
        .navigationBarTitleDisplayMode(.large)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.mint.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [generateSharingText()])
        }
    }
    
    private func updateReminderTimes(count: Int) {
        var updatedTimes = prescription.reminderTimes
        
        if count > updatedTimes.count {
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
            updatedTimes = Array(updatedTimes.prefix(count))
        }
        
        prescription.reminderTimes = updatedTimes
    }
    
    private func reminderTimeBinding(for index: Int) -> Binding<Date> {
        Binding(
            get: { 
                guard index < prescription.reminderTimes.count else { return Date() }
                return prescription.reminderTimes[index].time 
            },
            set: { newTime in
                guard index < prescription.reminderTimes.count else { return }
                var updatedTimes = prescription.reminderTimes
                updatedTimes[index].time = newTime
                prescription.reminderTimes = updatedTimes
            }
        )
    }
    
    private func reminderEnabledBinding(for index: Int) -> Binding<Bool> {
        Binding(
            get: { 
                guard index < prescription.reminderTimes.count else { return true }
                return prescription.reminderTimes[index].isEnabled 
            },
            set: { newValue in
                guard index < prescription.reminderTimes.count else { return }
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

struct MedicationHeaderCard: View {
    let prescription: Prescription
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prescription.name)
                        .font(DesignSystem.Typography.titleLarge(weight: .bold, family: .avenir))
                        .foregroundColor(.primary)
                    
                    Text(prescription.dose)
                        .font(DesignSystem.Typography.bodyMedium(weight: .regular, family: .sfPro))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Image(systemName: prescription.isTaken ? "checkmark.circle.fill" : "circle")
                        .font(.title)
                        .foregroundColor(prescription.isTaken ? .green : .gray)
                    
                    Text(prescription.isTaken ? "Taken" : "Pending")
                        .font(DesignSystem.Typography.statusText())
                        .foregroundColor(prescription.isTaken ? .green : .gray)
                }
            }
            
            if prescription.hasConflicts {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Potential conflicts")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct MedicationDetailsCard: View {
    @Binding var prescription: Prescription
    @Binding var selectedMethod: String
    let methods: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(DesignSystem.Typography.headingMedium(weight: .semibold, family: .avenir))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                CustomTextField(title: "Name", text: $prescription.name, icon: "pills.fill")
                CustomTextField(title: "Dose", text: $prescription.dose, icon: "scalemass.fill")
                CustomTextField(title: "Frequency", text: $prescription.frequency, icon: "clock.fill")
                
                HStack {
                    Image(systemName: "syringe.fill")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Method")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Method", selection: $selectedMethod) {
                            ForEach(methods, id: \.self) { method in
                                Text(method)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField(title, text: $text)
                    .font(.body)
            }
        }
        .padding(.vertical, 8)
    }
}

struct DateSettingsCard: View {
    @Binding var prescription: Prescription
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Schedule")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.green)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start Date")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        DatePicker("", selection: $prescription.startDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                
                if let endDate = prescription.endDate {
                    HStack {
                        Image(systemName: "calendar.badge.minus")
                            .foregroundColor(.red)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("End Date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            DatePicker("", selection: Binding(
                                get: { endDate },
                                set: { prescription.endDate = $0 }
                            ), displayedComponents: .date)
                            .labelsHidden()
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct RemindersCard: View {
    @Binding var prescription: Prescription
    @Binding var dailyFrequency: Int
    let updateReminderTimes: (Int) -> Void
    let reminderTimeBinding: (Int) -> Binding<Date>
    let reminderEnabledBinding: (Int) -> Binding<Bool>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Reminders")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.orange)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Number of reminders")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Stepper("\(dailyFrequency)", value: $dailyFrequency, in: 1...4)
                            .onChange(of: dailyFrequency) { newValue in
                                updateReminderTimes(newValue)
                            }
                    }
                }
                .padding(.vertical, 8)
                
                ForEach(Array(prescription.reminderTimes.enumerated()), id: \.element.id) { index, reminder in
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reminder \(index + 1)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            DatePicker(
                                "",
                                selection: reminderTimeBinding(index),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: reminderEnabledBinding(index))
                            .labelsHidden()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct StatusCard: View {
    @Binding var prescription: Prescription
    let formatDate: (Date) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Status")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: prescription.isTaken ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(prescription.isTaken ? .green : .gray)
                        .frame(width: 20)
                    
                    Toggle("Taken Today", isOn: $prescription.isTaken)
                        .font(.body)
                }
                
                if let lastTaken = prescription.lastTaken {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        Text("Last taken: \(formatDate(lastTaken))")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct NotesCard: View {
    @Binding var prescriptionNotes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextEditor(text: $prescriptionNotes)
                .frame(minHeight: 100)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct ActionsCard: View {
    @Binding var showingShareSheet: Bool
    let prescriptionStore: PrescriptionStore
    let prescription: Prescription
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingShareSheet = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                    Text("Share Status")
                        .font(.body.weight(.medium))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Button("Save Changes") {
                prescriptionStore.updatePrescription(prescription)
                NotificationManager.shared.updateNotifications(for: prescription)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .font(.body.weight(.medium))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

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