import SwiftUI

struct RefillAlertsView: View {
    @ObservedObject var refillManager: SmartRefillManager
    @State private var showingRefillDetails = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                DesignSystem.Gradients.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        if refillManager.refillAlerts.isEmpty {
                            EmptyRefillStateView()
                        } else {
                            // Summary Card
                            RefillSummaryCard(refillManager: refillManager)
                            
                            // Critical Alerts
                            let criticalAlerts = refillManager.refillAlerts.filter { $0.alertType == .critical }
                            if !criticalAlerts.isEmpty {
                                RefillAlertSection(
                                    title: "Critical - Refill Immediately",
                                    alerts: criticalAlerts,
                                    color: .red
                                )
                            }
                            
                            // Warning Alerts
                            let warningAlerts = refillManager.refillAlerts.filter { $0.alertType == .warning }
                            if !warningAlerts.isEmpty {
                                RefillAlertSection(
                                    title: "Upcoming Refills",
                                    alerts: warningAlerts,
                                    color: .orange
                                )
                            }
                            
                            // Recommendations
                            RefillRecommendationsCard(refillManager: refillManager)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Refill Alerts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Details") {
                        showingRefillDetails = true
                    }
                }
            }
            .sheet(isPresented: $showingRefillDetails) {
                RefillDetailsView(refillManager: refillManager)
            }
        }
    }
}

struct RefillSummaryCard: View {
    @ObservedObject var refillManager: SmartRefillManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "pills.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Refill Status")
                        .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("\(refillManager.refillAlerts.count) medication\(refillManager.refillAlerts.count == 1 ? "" : "s") need attention")
                        .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
            }
            
            // Quick stats
            HStack(spacing: 20) {
                RefillStatItem(
                    title: "Critical",
                    count: refillManager.refillAlerts.filter { $0.alertType == .critical }.count,
                    color: .red
                )
                
                RefillStatItem(
                    title: "Warning",
                    count: refillManager.refillAlerts.filter { $0.alertType == .warning }.count,
                    color: .orange
                )
                
                RefillStatItem(
                    title: "Low Stock",
                    count: refillManager.lowInventoryMedications.count,
                    color: .yellow
                )
            }
        }
        .padding(20)
        .cardStyle()
    }
}


struct RefillAlertSection: View {
    let title: String
    let alerts: [RefillAlert]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .medium))
                
                Text(title)
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(alerts, id: \.id) { alert in
                    RefillAlertCard(alert: alert)
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct RefillAlertCard: View {
    let alert: RefillAlert
    
    var body: some View {
        HStack(spacing: 16) {
            // Medication icon
            Circle()
                .fill(alert.alertType.color.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: alert.alertType.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(alert.alertType.color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.prescription.name)
                    .font(DesignSystem.Typography.bodyMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                if let prediction = alert.prediction {
                    Text("\(prediction.daysRemaining) days remaining")
                        .font(DesignSystem.Typography.captionLarge(weight: .medium))
                        .foregroundColor(alert.alertType.color)
                    
                    if let pillsRemaining = alert.prescription.pillsRemaining {
                        Text("\(pillsRemaining) pills left")
                            .font(DesignSystem.Typography.captionMedium(weight: .regular))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let prediction = alert.prediction {
                    Text("Refill by")
                        .font(DesignSystem.Typography.captionSmall(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text(formatDate(prediction.recommendedRefillDate))
                        .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(alert.alertType.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct RefillRecommendationsCard: View {
    @ObservedObject var refillManager: SmartRefillManager
    
    private var recommendations: [RefillRecommendation] {
        refillManager.getRefillRecommendations()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .medium))
                
                Text("Smart Recommendations")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            if recommendations.isEmpty {
                Text("No recommendations at this time")
                    .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(recommendations) { recommendation in
                        RecommendationRow(recommendation: recommendation)
                    }
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct RecommendationRow: View {
    let recommendation: RefillRecommendation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: recommendation.urgency == .immediate ? "exclamationmark.circle.fill" : "clock.fill")
                .foregroundColor(recommendation.urgency.color)
                .font(.system(size: 14, weight: .medium))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.prescription.name)
                    .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(recommendation.reason)
                    .font(DesignSystem.Typography.captionMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(recommendation.urgency.displayName)
                    .font(DesignSystem.Typography.captionSmall(weight: .semibold))
                    .foregroundColor(recommendation.urgency.color)
                
                Circle()
                    .fill(recommendation.confidence.color)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(recommendation.urgency.color.opacity(0.05))
        )
    }
}

struct EmptyRefillStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.success)
            
            VStack(spacing: 8) {
                Text("All Set!")
                    .font(DesignSystem.Typography.headingLarge(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("No refills needed at this time. We'll monitor your medications and alert you when it's time to refill.")
                    .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .cardStyle()
    }
}

struct RefillDetailsView: View {
    @ObservedObject var refillManager: SmartRefillManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(refillManager.refillAlerts, id: \.id) { alert in
                        DetailedRefillCard(alert: alert)
                    }
                }
                .padding()
            }
            .navigationTitle("Refill Details")
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

struct DetailedRefillCard: View {
    let alert: RefillAlert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(alert.prescription.name)
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Text(alert.alertType == .critical ? "CRITICAL" : "WARNING")
                    .font(DesignSystem.Typography.captionSmall(weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(alert.alertType.color)
                    )
            }
            
            if let prediction = alert.prediction {
                // Prediction details
                VStack(spacing: 12) {
                    PredictionDetailRow(
                        title: "Days Remaining",
                        value: "\(prediction.daysRemaining) days",
                        color: alert.alertType.color
                    )
                    
                    PredictionDetailRow(
                        title: "Predicted Refill Date",
                        value: formatDate(prediction.predictedRefillDate),
                        color: DesignSystem.Colors.textSecondary
                    )
                    
                    PredictionDetailRow(
                        title: "Recommended Refill By",
                        value: formatDate(prediction.recommendedRefillDate),
                        color: DesignSystem.Colors.primary
                    )
                    
                    PredictionDetailRow(
                        title: "Average Daily Usage",
                        value: String(format: "%.1f pills/day", prediction.averageDailyUsage),
                        color: DesignSystem.Colors.textSecondary
                    )
                    
                    PredictionDetailRow(
                        title: "Adherence Rate",
                        value: "\(Int(prediction.adherenceRate * 100))%",
                        color: prediction.adherenceRate > 0.8 ? DesignSystem.Colors.success : DesignSystem.Colors.warning
                    )
                    
                    PredictionDetailRow(
                        title: "Prediction Confidence",
                        value: prediction.confidence.rawValue,
                        color: prediction.confidence.color
                    )
                }
            }
            
            // Prescription details
            if let pillsRemaining = alert.prescription.pillsRemaining,
               let totalPills = alert.prescription.totalPills {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Inventory")
                        .font(DesignSystem.Typography.bodyMedium(weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    HStack {
                        Text("Pills Remaining:")
                        Spacer()
                        Text("\(pillsRemaining) of \(totalPills)")
                            .fontWeight(.semibold)
                    }
                    .font(DesignSystem.Typography.captionLarge(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    // Visual pill count indicator
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(DesignSystem.Colors.neutral300)
                                .frame(height: 6)
                                .cornerRadius(3)
                            
                            Rectangle()
                                .fill(pillsRemaining <= 10 ? Color.red : pillsRemaining <= 30 ? Color.orange : DesignSystem.Colors.success)
                                .frame(width: geometry.size.width * (Double(pillsRemaining) / Double(totalPills)), height: 6)
                                .cornerRadius(3)
                                .animation(.easeInOut(duration: 0.3), value: pillsRemaining)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct PredictionDetailRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(DesignSystem.Typography.captionLarge(weight: .regular))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                .foregroundColor(color)
        }
    }
}

struct RefillStatItem: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(DesignSystem.Typography.headingMedium(weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(DesignSystem.Typography.captionMedium(weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// Preview
struct RefillAlertsView_Previews: PreviewProvider {
    static var previews: some View {
        RefillAlertsView(refillManager: SmartRefillManager(medicationRecordManager: MedicationRecordManager()))
    }
}
