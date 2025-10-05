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
    @StateObject private var searchService = MedicationSearchService.shared
    
    let frequencies = ["Daily", "Twice Daily", "Three Times Daily", "Four Times Daily", "Weekly", "As Needed"]
    
    init(prescriptionStore: PrescriptionStore, prefilledDrugName: String? = nil) {
        self.prescriptionStore = prescriptionStore
        _name = State(initialValue: prefilledDrugName ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                DesignSystem.Gradients.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 20) {
                        // Header Card
                        AddPrescriptionHeaderCard()
                        
                        // Basic Details Card
                        BasicDetailsCard(
                            name: $name,
                            dose: $dose,
                            frequency: $frequency,
                            frequencies: frequencies,
                            onFrequencyChange: handleFrequencyChange,
                            searchService: searchService,
                            onScrollToInput: {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo("medicationInput", anchor: .top)
                                }
                            }
                        )
                        .id("medicationInput")
                        
                        // Schedule Card
                        ScheduleCard(
                            startDate: $startDate,
                            endDate: $endDate
                        )
                        
                        // Reminders Card
                        AddRemindersCard(
                            dailyFrequency: $dailyFrequency,
                            reminderTimes: $reminderTimes,
                            updateReminderTimes: updateReminderTimes,
                            binding: binding,
                            enabledBinding: enabledBinding
                        )
                        
                        // Action Buttons
                        ActionButtonsCard(
                            onCancel: {
                                presentationMode.wrappedValue.dismiss()
                            },
                            onSave: savePrescription,
                            canSave: !name.isEmpty && !dose.isEmpty
                        )
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    private func binding(for index: Int) -> Binding<Date> {
        Binding(
            get: { 
                guard index < self.reminderTimes.count else { return Date() }
                return self.reminderTimes[index].time 
            },
            set: { newValue in
                guard index < self.reminderTimes.count else { return }
                self.reminderTimes[index].time = newValue
            }
        )
    }
    
    private func enabledBinding(for index: Int) -> Binding<Bool> {
        Binding(
            get: { 
                guard index < self.reminderTimes.count else { return true }
                return self.reminderTimes[index].isEnabled 
            },
            set: { newValue in
                guard index < self.reminderTimes.count else { return }
                self.reminderTimes[index].isEnabled = newValue
            }
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
    
    private func handleFrequencyChange(_ newFrequency: String) {
        frequency = newFrequency
        
        // Auto-set daily frequency based on selected frequency
        let frequencyMap = [
            "Daily": 1,
            "Twice Daily": 2,
            "Three Times Daily": 3,
            "Four Times Daily": 4,
            "Weekly": 1,  // Once per week, but still 1 per day when taken
            "As Needed": 1
        ]
        
        if let suggestedFrequency = frequencyMap[newFrequency] {
            dailyFrequency = suggestedFrequency
            updateReminderTimes(count: suggestedFrequency)
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

// MARK: - UI Components

struct AddPrescriptionHeaderCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "pills.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 4) {
                Text("Add New Medication")
                    .font(DesignSystem.Typography.titleLarge(weight: .bold, family: .avenir))
                    .foregroundColor(.primary)
                
                Text("Fill in the details below to add your prescription")
                    .font(DesignSystem.Typography.bodyMedium(weight: .regular, family: .sfPro))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct BasicDetailsCard: View {
    @Binding var name: String
    @Binding var dose: String
    @Binding var frequency: String
    let frequencies: [String]
    let onFrequencyChange: (String) -> Void
    let searchService: MedicationSearchService
    let onScrollToInput: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(DesignSystem.Typography.headingLarge(weight: .semibold, family: .avenir))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                MedicationSearchField(
                    title: "Medicine Name",
                    text: $name,
                    icon: "pills.fill",
                    placeholder: "e.g., Amoxicillin",
                    searchService: searchService,
                    onScrollToInput: onScrollToInput
                )
                
                CustomInputField(
                    title: "Dosage",
                    text: $dose,
                    icon: "scalemass.fill",
                    placeholder: "e.g., 500mg"
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        Text("Frequency")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                    }
                    
                    Menu {
                        ForEach(frequencies, id: \.self) { freq in
                            Button(freq) {
                                onFrequencyChange(freq)
                            }
                        }
                    } label: {
                        HStack {
                            Text(frequency.isEmpty ? "Select frequency" : frequency)
                                .foregroundColor(frequency.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
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

struct CustomInputField: View {
    let title: String
    @Binding var text: String
    let icon: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
            }
            
            TextField(placeholder, text: $text)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(text.isEmpty ? Color.gray.opacity(0.3) : Color.blue.opacity(0.5), lineWidth: 1)
                )
        }
    }
}

struct ScheduleCard: View {
    @Binding var startDate: Date
    @Binding var endDate: Date?
    @State private var hasEndDate = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Schedule")
                .font(DesignSystem.Typography.headingLarge(weight: .semibold, family: .avenir))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.green)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start Date")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                        
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                HStack {
                    Image(systemName: "calendar.badge.checkmark")
                        .foregroundColor(.orange)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Set End Date", isOn: $hasEndDate)
                            .font(.subheadline.weight(.medium))
                        
                        if hasEndDate {
                            DatePicker("", selection: Binding(
                                get: { endDate ?? Date() },
                                set: { endDate = $0 }
                            ), displayedComponents: .date)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
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
        .onChange(of: hasEndDate) {
            if !hasEndDate {
                endDate = nil
            }
        }
    }
}

struct AddRemindersCard: View {
    @Binding var dailyFrequency: Int
    @Binding var reminderTimes: [Prescription.ReminderTime]
    let updateReminderTimes: (Int) -> Void
    let binding: (Int) -> Binding<Date>
    let enabledBinding: (Int) -> Binding<Bool>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Reminders")
                .font(DesignSystem.Typography.headingLarge(weight: .semibold, family: .avenir))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.orange)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Number of daily reminders")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                        
                        HStack {
                            ForEach(1...4, id: \.self) { count in
                                Button(action: {
                                    dailyFrequency = count
                                    updateReminderTimes(count)
                                }) {
                                    Text("\(count)")
                                        .font(.body.weight(.medium))
                                        .foregroundColor(dailyFrequency == count ? .white : .blue)
                                        .frame(width: 36, height: 36)
                                        .background(
                                            Circle()
                                                .fill(dailyFrequency == count ? Color.blue : Color.blue.opacity(0.1))
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            Spacer()
                        }
                    }
                }
                
                ForEach(Array(reminderTimes.enumerated()), id: \.element.id) { index, _ in
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reminder \(index + 1)")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)
                            
                            DatePicker("", selection: binding(index), displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: enabledBinding(index))
                            .labelsHidden()
                            .scaleEffect(0.9)
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

struct MedicationSearchField: View {
    let title: String
    @Binding var text: String
    let icon: String
    let placeholder: String
    let searchService: MedicationSearchService
    let onScrollToInput: () -> Void
    @State private var showingSuggestions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 0) {
                TextField(placeholder, text: $text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: text.isEmpty ? 12 : 12)
                            .stroke(text.isEmpty ? Color.gray.opacity(0.3) : Color.blue.opacity(0.5), lineWidth: 1)
                    )
                    .onChange(of: text) { newValue in
                        searchService.performSearch(query: newValue)
                        let shouldShow = !newValue.isEmpty && !searchService.searchResults.isEmpty
                        showingSuggestions = shouldShow
                        
                        // Auto-scroll to make suggestions visible
                        if shouldShow {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                onScrollToInput()
                            }
                        }
                    }
                    .onTapGesture {
                        if !text.isEmpty {
                            searchService.performSearch(query: text)
                            let shouldShow = !searchService.searchResults.isEmpty
                            showingSuggestions = shouldShow
                            
                            // Auto-scroll when tapping and suggestions appear
                            if shouldShow {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    onScrollToInput()
                                }
                            }
                        }
                    }
                
                if showingSuggestions && !searchService.searchResults.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(searchService.searchResults.enumerated()), id: \.offset) { index, result in
                            Button(action: {
                                text = result.name
                                showingSuggestions = false
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.name)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        HStack(spacing: 8) {
                                            if let generic = result.genericName {
                                                Text("Generic: \(generic)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            if let category = result.category {
                                                Text(category)
                                                    .font(.caption)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.blue.opacity(0.1))
                                                    .foregroundColor(.blue)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .background(Color(.systemGray6).opacity(0.5))
                            
                            if index < searchService.searchResults.count - 1 {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                    .padding(.top, 4)
                }
            }
        }
        .onTapGesture {
            // Dismiss suggestions when tapping outside
            if showingSuggestions {
                showingSuggestions = false
            }
        }
    }
}

struct ActionButtonsCard: View {
    let onCancel: () -> Void
    let onSave: () -> Void
    let canSave: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: onSave) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                    Text("Save Medication")
                        .font(.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canSave ? Color.green : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(!canSave)
            
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.body.weight(.medium))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
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
