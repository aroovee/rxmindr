import SwiftUI
import MapKit

struct TravelSetupView: View {
    @ObservedObject var travelManager: TravelModeManager
    @Environment(\.dismiss) private var dismiss
    @State private var destination = ""
    @State private var departureDate = Date()
    @State private var returnDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 1 week default
    @State private var selectedTimeZone = TimeZone.current
    @State private var showingTimeZonePicker = false
    @State private var travelNotes = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 48))
                            .foregroundColor(DesignSystem.Colors.primary)
                        
                        Text("Setup Travel Mode")
                            .font(DesignSystem.Typography.headingLarge(weight: .bold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("Configure your medication schedule for travel")
                            .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Travel Details Card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Travel Details")
                            .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        // Destination
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Destination")
                                .font(DesignSystem.Typography.captionLarge(weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            TextField("Enter destination city", text: $destination)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                        }
                        
                        // Dates
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Travel Dates")
                                .font(DesignSystem.Typography.captionLarge(weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Departure")
                                        .font(DesignSystem.Typography.captionMedium(weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    
                                    DatePicker("", selection: $departureDate, displayedComponents: [.date])
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Return")
                                        .font(DesignSystem.Typography.captionMedium(weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    
                                    DatePicker("", selection: $returnDate, displayedComponents: [.date])
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                }
                            }
                        }
                        
                        // Time Zone
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Destination Time Zone")
                                .font(DesignSystem.Typography.captionLarge(weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Button(action: {
                                showingTimeZonePicker = true
                            }) {
                                HStack {
                                    Text(timeZoneDisplayName(selectedTimeZone))
                                        .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(DesignSystem.Colors.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .strokeBorder(DesignSystem.Colors.neutral300, lineWidth: 1)
                                        )
                                )
                            }
                        }
                        
                        // Travel Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Travel Notes (Optional)")
                                .font(DesignSystem.Typography.captionLarge(weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            TextField("Add any special notes for your trip...", text: $travelNotes, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                                .lineLimit(3...6)
                        }
                    }
                    .padding(20)
                    .cardStyle()
                    
                    // Travel Duration Info
                    if returnDate > departureDate {
                        TravelDurationCard(departureDate: departureDate, returnDate: returnDate)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Travel Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Start Travel") {
                        startTravelMode()
                    }
                    .disabled(destination.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingTimeZonePicker) {
            TimeZonePickerView(selectedTimeZone: $selectedTimeZone)
        }
    }
    
    private func timeZoneDisplayName(_ timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        let offset = timeZone.secondsFromGMT() / 3600
        let offsetString = String(format: "UTC%+d", offset)
        
        if let identifier = timeZone.localizedName(for: .generic, locale: .current) {
            return "\(identifier) (\(offsetString))"
        }
        return "\(timeZone.identifier) (\(offsetString))"
    }
    
    private func startTravelMode() {
        let travelPlan = TravelPlan(
            destination: destination,
            startDate: departureDate,
            endDate: returnDate,
            destinationTimeZone: selectedTimeZone,
            isInternational: false, // Could be enhanced to detect based on timezone/destination
            notes: travelNotes.isEmpty ? nil : travelNotes
        )
        
        travelManager.activateTravelMode(with: travelPlan)
        dismiss()
    }
}

struct TravelDurationCard: View {
    let departureDate: Date
    let returnDate: Date
    
    private var duration: TimeInterval {
        returnDate.timeIntervalSince(departureDate)
    }
    
    private var durationText: String {
        let days = Int(duration / (24 * 60 * 60))
        return "\(days) day\(days == 1 ? "" : "s")"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(DesignSystem.Colors.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Trip Duration")
                    .font(DesignSystem.Typography.bodyMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(durationText)
                    .font(DesignSystem.Typography.captionLarge(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Medications Needed")
                    .font(DesignSystem.Typography.captionMedium(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text("Will be calculated")
                    .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignSystem.Colors.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct TimeZonePickerView: View {
    @Binding var selectedTimeZone: TimeZone
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var timeZones: [TimeZone] {
        let allTimeZones = TimeZone.knownTimeZoneIdentifiers.compactMap { TimeZone(identifier: $0) }
        
        if searchText.isEmpty {
            return allTimeZones.sorted { tz1, tz2 in
                let offset1 = tz1.secondsFromGMT()
                let offset2 = tz2.secondsFromGMT()
                return offset1 < offset2
            }
        } else {
            return allTimeZones.filter { timeZone in
                timeZone.identifier.localizedCaseInsensitiveContains(searchText) ||
                (timeZone.localizedName(for: .generic, locale: .current)?.localizedCaseInsensitiveContains(searchText) ?? false)
            }.sorted { tz1, tz2 in
                let offset1 = tz1.secondsFromGMT()
                let offset2 = tz2.secondsFromGMT()
                return offset1 < offset2
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List(timeZones, id: \.identifier) { timeZone in
                TimeZoneRow(
                    timeZone: timeZone,
                    isSelected: timeZone.identifier == selectedTimeZone.identifier
                ) {
                    selectedTimeZone = timeZone
                    dismiss()
                }
            }
            .searchable(text: $searchText, prompt: "Search time zones")
            .navigationTitle("Select Time Zone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TimeZoneRow: View {
    let timeZone: TimeZone
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var displayName: String {
        timeZone.localizedName(for: .generic, locale: .current) ?? timeZone.identifier
    }
    
    private var offsetText: String {
        let offset = timeZone.secondsFromGMT() / 3600
        return String(format: "UTC%+d", offset)
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(DesignSystem.Typography.bodyMedium(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(offsetText)
                        .font(DesignSystem.Typography.captionMedium(weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TravelSetupView_Previews: PreviewProvider {
    static var previews: some View {
        TravelSetupView(travelManager: TravelModeManager(prescriptionStore: PrescriptionStore.shared))
    }
}