import SwiftUI

struct ModernPrescriptionCard: View {
    let prescription: Prescription
    let onTap: () -> Void
    let onMarkTaken: () -> Void
    
    @State private var isPressed = false
    @State private var showingDetails = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Main content area
                VStack(spacing: DesignSystem.Spacing.lg) {
                    headerSection
                    medicationInfo
                    statusSection
                }
                .padding(DesignSystem.Spacing.xl)
                
                // Action area with glassmorphism effect
                actionSection
            }
        }
        .buttonStyle(PlainButtonStyle())
        .modernCard(elevation: prescription.isTaken ? .minimal : .medium)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        } perform: { }
        .overlay(
            // Taken indicator overlay
            prescription.isTaken ? takenOverlay : nil
        )
    }
    
    private var headerSection: some View {
        HStack {
            // Medication icon with gradient background
            ZStack {
                Circle()
                    .fill(gradientForMedication)
                    .frame(width: 56, height: 56)
                
                Image(systemName: "pills.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
            .shadow(
                color: colorForMedication.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(prescription.name)
                    .font(DesignSystem.Typography.headingMedium(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                
                Text(prescription.dose)
                    .font(DesignSystem.Typography.bodyMedium(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Time and frequency info
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                if let nextReminderTime = prescription.reminderTimes.first?.time {
                    Text(timeFormatter.string(from: nextReminderTime))
                        .font(DesignSystem.Typography.headingSmall(weight: .bold))
                        .foregroundColor(prescription.isTaken ? DesignSystem.Colors.success : DesignSystem.Colors.primary)
                }
                
                Text(prescription.frequency)
                    .font(DesignSystem.Typography.captionLarge(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(DesignSystem.Colors.neutral100)
                    )
            }
        }
    }
    
    private var medicationInfo: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            // Progress indicator
            progressIndicator
            
            Spacer()
            
            // Additional info badges
            HStack(spacing: DesignSystem.Spacing.sm) {
                if prescription.hasConflicts {
                    InfoBadge(
                        icon: "exclamationmark.triangle.fill",
                        text: "Conflicts",
                        color: DesignSystem.Colors.warning
                    )
                }
                
                if prescription.isEssentialForTravel {
                    InfoBadge(
                        icon: "airplane",
                        text: "Travel",
                        color: DesignSystem.Colors.accent
                    )
                }
                
                if let remainingPills = prescription.pillsRemaining, remainingPills < 7 {
                    InfoBadge(
                        icon: "exclamationmark.circle.fill",
                        text: "Low",
                        color: DesignSystem.Colors.error
                    )
                }
            }
        }
    }
    
    private var progressIndicator: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text("Today's Progress")
                    .font(DesignSystem.Typography.captionLarge(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Text("\(prescription.recordTaken.count)/\(prescription.dailyFrequency)")
                    .font(DesignSystem.Typography.captionLarge(weight: .bold))
                    .foregroundColor(prescription.isTaken ? DesignSystem.Colors.success : DesignSystem.Colors.textPrimary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                        .fill(DesignSystem.Colors.neutral200)
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                        .fill(
                            LinearGradient(
                                colors: prescription.isTaken ? 
                                    [DesignSystem.Colors.success, DesignSystem.Colors.success.opacity(0.8)] :
                                    [DesignSystem.Colors.primary, DesignSystem.Colors.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * progressPercentage,
                            height: 4
                        )
                        .animation(.easeInOut(duration: 0.3), value: progressPercentage)
                }
            }
            .frame(height: 4)
        }
    }
    
    private var statusSection: some View {
        HStack {
            // Last taken info
            if let lastTaken = prescription.lastTaken {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.Colors.success)
                    
                    Text("Taken \(RelativeDateTimeFormatter().localizedString(for: lastTaken, relativeTo: Date()))")
                        .font(DesignSystem.Typography.captionMedium(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            } else {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    Text("Not taken today")
                        .font(DesignSystem.Typography.captionMedium(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            Spacer()
        }
    }
    
    private var actionSection: some View {
        HStack {
            Spacer()
            
            Button(action: onMarkTaken) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: prescription.isTaken ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(prescription.isTaken ? "Taken" : "Mark Taken")
                        .font(DesignSystem.Typography.bodyMedium(weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    Capsule()
                        .fill(prescription.isTaken ? DesignSystem.Gradients.successGradient : DesignSystem.Gradients.primaryGradient)
                        .shadow(
                            color: (prescription.isTaken ? DesignSystem.Colors.success : DesignSystem.Colors.primary).opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(prescription.isTaken ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: prescription.isTaken)
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.8)
        )
    }
    
    private var takenOverlay: some View {
        VStack {
            HStack {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.success)
                        .frame(width: 28, height: 28)
                        .shadow(
                            color: DesignSystem.Colors.success.opacity(0.4),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: -8, y: 8)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties
    
    private var progressPercentage: Double {
        guard prescription.dailyFrequency > 0 else { return 0 }
        return min(Double(prescription.recordTaken.count) / Double(prescription.dailyFrequency), 1.0)
    }
    
    private var colorForMedication: Color {
        // Simple hash-based color assignment
        let colors: [Color] = [
            DesignSystem.Colors.primary,
            DesignSystem.Colors.secondary,
            DesignSystem.Colors.accent,
            DesignSystem.Colors.success,
            DesignSystem.Colors.warning
        ]
        let hash = prescription.name.hash
        return colors[abs(hash) % colors.count]
    }
    
    private var gradientForMedication: LinearGradient {
        LinearGradient(
            colors: [colorForMedication, colorForMedication.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

struct InfoBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)
            
            Text(text)
                .font(DesignSystem.Typography.captionSmall(weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        ModernPrescriptionCard(
            prescription: Prescription(
                name: "Lisinopril",
                dose: "10mg",
                frequency: "Daily",
                startDate: Date(),
                reminderTimes: [.init(time: Date())],
                isTaken: false
            ),
            onTap: {},
            onMarkTaken: {}
        )
        
        ModernPrescriptionCard(
            prescription: Prescription(
                name: "Metformin",
                dose: "500mg",
                frequency: "Twice Daily",
                startDate: Date(),
                reminderTimes: [.init(time: Date())],
                isTaken: true
            ),
            onTap: {},
            onMarkTaken: {}
        )
    }
    .padding()
    .background(DesignSystem.Gradients.backgroundGradient)
}