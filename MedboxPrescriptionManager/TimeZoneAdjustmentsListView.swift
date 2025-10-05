import SwiftUI

struct TimeZoneAdjustmentsListView: View {
    @ObservedObject var travelManager: TravelModeManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingAdjustmentDetails = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if let travelPlan = travelManager.currentTravelPlan {
                        let adjustments = travelManager.timeZoneAdjustments
                        
                        // Current Status Card
                        TimeZoneStatusCard(travelPlan: travelPlan)
                        
                        // Medication Schedule Adjustments
                        MedicationAdjustmentsSection(
                            adjustments: adjustments,
                            travelManager: travelManager
                        )
                        
                        // Adjustment Recommendations
                        AdjustmentRecommendationsCard(
                            travelPlan: travelPlan,
                            adjustments: adjustments
                        )
                        
                    } else {
                        EmptyTimeZoneAdjustmentsView()
                    }
                }
                .padding()
            }
            .navigationTitle("Time Zone Adjustments")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TimeZoneStatusCard: View {
    let travelPlan: TravelPlan
    
    private var timeDifference: Int {
        let homeOffset = TimeZone.current.secondsFromGMT() / 3600
        let destinationOffset = travelPlan.destinationTimeZone.secondsFromGMT() / 3600
        return destinationOffset - homeOffset
    }
    
    private var timeDifferenceText: String {
        let difference = abs(timeDifference)
        let direction = timeDifference > 0 ? "ahead" : "behind"
        
        if difference == 0 {
            return "Same time zone"
        } else {
            return "\(difference) hour\(difference == 1 ? "" : "s") \(direction)"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time Zone Status")
                        .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(travelPlan.destination)
                        .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
            }
            
            // Time comparison
            VStack(spacing: 12) {
                TimeComparisonRow(
                    location: "Home",
                    timeZone: TimeZone.current,
                    isDestination: false
                )
                
                TimeComparisonRow(
                    location: travelPlan.destination,
                    timeZone: travelPlan.destinationTimeZone,
                    isDestination: true
                )
            }
            
            // Difference summary
            HStack {
                Text("Time Difference:")
                    .font(DesignSystem.Typography.captionLarge(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Text(timeDifferenceText)
                    .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                    .foregroundColor(timeDifference == 0 ? DesignSystem.Colors.success : DesignSystem.Colors.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignSystem.Colors.primary.opacity(0.05))
            )
        }
        .padding(20)
        .cardStyle()
    }
}

struct TimeComparisonRow: View {
    let location: String
    let timeZone: TimeZone
    let isDestination: Bool
    @State private var currentTime = Date()
    @State private var timer: Timer?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(location)
                    .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                    .foregroundColor(isDestination ? DesignSystem.Colors.primary : DesignSystem.Colors.textPrimary)
                
                Text(timeZoneAbbreviation)
                    .font(DesignSystem.Typography.captionMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            Text(formattedTime)
                .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isDestination ? DesignSystem.Colors.primary.opacity(0.1) : DesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isDestination ? DesignSystem.Colors.primary.opacity(0.3) : DesignSystem.Colors.neutral300, lineWidth: 1)
                )
        )
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private var timeZoneAbbreviation: String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "zzz"
        return formatter.string(from: currentTime)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.timeStyle = .short
        return formatter.string(from: currentTime)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            currentTime = Date()
        }
    }
}

struct MedicationAdjustmentsSection: View {
    let adjustments: [TimeZoneAdjustment]
    @ObservedObject var travelManager: TravelModeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "pills.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text("Medication Schedule Adjustments")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            if adjustments.isEmpty {
                Text("No medications require time adjustment")
                    .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(adjustments, id: \.id) { adjustment in
                        MedicationAdjustmentCard(adjustment: adjustment)
                    }
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct MedicationAdjustmentCard: View {
    let adjustment: TimeZoneAdjustment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Medication name and dose
            HStack {
                Text(adjustment.prescriptionName)
                    .font(DesignSystem.Typography.bodyMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            // Time adjustment
            VStack(spacing: 8) {
                TimeAdjustmentRow(
                    label: "Home Time",
                    time: adjustment.originalTime,
                    isOriginal: true
                )
                
                Image(systemName: "arrow.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                
                TimeAdjustmentRow(
                    label: "Travel Time",
                    time: adjustment.adjustedTime,
                    isOriginal: false
                )
            }
            
            // Adjustment explanation
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text(adjustment.adjustmentDescription)
                    .font(DesignSystem.Typography.captionMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignSystem.Colors.primary.opacity(0.05))
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(DesignSystem.Colors.neutral300, lineWidth: 1)
                )
        )
    }
}

struct TimeAdjustmentRow: View {
    let label: String
    let time: Date
    let isOriginal: Bool
    
    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.captionLarge(weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Spacer()
            
            Text(timeString)
                .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                .foregroundColor(isOriginal ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.primary)
                .monospacedDigit()
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
}

struct AdjustmentRecommendationsCard: View {
    let travelPlan: TravelPlan
    let adjustments: [TimeZoneAdjustment]
    
    private var recommendations: [String] {
        var recs: [String] = []
        
        let timeDifference = abs((travelPlan.destinationTimeZone.secondsFromGMT() - TimeZone.current.secondsFromGMT()) / 3600)
        
        if timeDifference > 6 {
            recs.append("Consider gradual time adjustment 2-3 days before departure")
        }
        
        if timeDifference > 3 {
            recs.append("Use phone alarms for new medication times initially")
        }
        
        if !adjustments.isEmpty {
            recs.append("Update medication reminders in your phone before traveling")
        }
        
        recs.append("Maintain consistent spacing between doses regardless of time zone")
        recs.append("Consult your doctor for complex medication schedules")
        
        return recs
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.yellow)
                
                Text("Adjustment Tips")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(recommendations, id: \.self) { recommendation in
                    TimeZoneRecommendationRow(text: recommendation)
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct TimeZoneRecommendationRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(DesignSystem.Colors.primary)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            
            Text(text)
                .font(DesignSystem.Typography.captionLarge(weight: .regular))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct EmptyTimeZoneAdjustmentsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            VStack(spacing: 8) {
                Text("No Active Travel Mode")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Start travel mode to see time zone adjustments for your medications.")
                    .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .cardStyle()
    }
}

struct TimeZoneAdjustmentsListView_Previews: PreviewProvider {
    static var previews: some View {
        TimeZoneAdjustmentsListView(travelManager: TravelModeManager(prescriptionStore: PrescriptionStore.shared))
    }
}