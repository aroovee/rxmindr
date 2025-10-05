import SwiftUI

// MARK: - Supporting Classes
class ImageProcessingDelegate: NSObject, PrescriptionScannerDelegate {
    let prescriptionStore: PrescriptionStore
    
    init(prescriptionStore: PrescriptionStore) {
        self.prescriptionStore = prescriptionStore
    }
    
    func didScanPrescription(_ prescriptionInfo: PrescriptionInfo) {
        let newPrescription = Prescription(
            name: prescriptionInfo.medicineName ?? "Unknown",
            dose: prescriptionInfo.dose ?? "Unknown",
            frequency: prescriptionInfo.frequency ?? "Unknown",
            startDate: Date()
        )
        prescriptionStore.addPrescription(newPrescription)
    }
}

struct ScanView: View {
    @ObservedObject var prescriptionStore: PrescriptionStore
    @State private var isShowingScanner = false
    @State private var isShowingImagePicker = false
    @State private var isShowingAddPrescription = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                DesignSystem.Gradients.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: max(24, UIScreen.main.bounds.height * 0.025)) {
                        // Header Card
                        ScanHeaderCard()
                        
                        // Scan Options
                        ScanOptionsCard(
                            onCameraScan: {
                                isShowingScanner = true
                            },
                            onImageScan: {
                                isShowingImagePicker = true
                            }
                        )
                        
                        // Instructions Card
                        ScanInstructionsCard()
                        
                        // Alternative Action
                        AlternativeActionCard {
                            isShowingAddPrescription = true
                        }
                    }
                    .padding(.horizontal, max(16, UIScreen.main.bounds.width * 0.04))
                    .padding(.vertical, max(16, UIScreen.main.bounds.height * 0.02))
                }
            }
            .navigationTitle("Scan Prescription")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $isShowingScanner) {
            ModernCameraScanView(isPresented: $isShowingScanner, prescriptionStore: prescriptionStore)
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(isPresented: $isShowingImagePicker, prescriptionStore: prescriptionStore) { image in
                // Process the selected image using the same OCR logic
                processSelectedImage(image)
            }
        }
        .sheet(isPresented: $isShowingAddPrescription) {
            AddPrescriptionView(prescriptionStore: prescriptionStore)
        }
    }
    
    private func createScannerView() -> AnyView? {
        return AnyView(ScannerView(isPresented: $isShowingScanner, prescriptionStore: prescriptionStore))
    }
    
    @State private var imageProcessor: ImageProcessingDelegate?
    
    private func processSelectedImage(_ image: UIImage) {
        // Create and retain delegate
        imageProcessor = ImageProcessingDelegate(prescriptionStore: prescriptionStore)
        
        // Create a temporary scanner to process the image
        let scanner = PrescriptionScannerViewController()
        scanner.delegate = imageProcessor
        
        // Process the image directly
        DispatchQueue.main.async {
            scanner.processSelectedImage(image)
        }
    }
}

// MARK: - UI Components

struct ScanHeaderCard: View {
    @State private var animateGlow = false
    @State private var animateFloat = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Enhanced animated icon with floating effect
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.1))
                    .frame(width: min(140, UIScreen.main.bounds.width * 0.35), height: min(140, UIScreen.main.bounds.width * 0.35))
                    .scaleEffect(animateGlow ? 1.2 : 1.0)
                    .opacity(animateGlow ? 0.3 : 0.6)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateGlow)
                
                // Main background circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.primary.opacity(0.3),
                                DesignSystem.Colors.primaryDark.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: min(110, UIScreen.main.bounds.width * 0.28), height: min(110, UIScreen.main.bounds.width * 0.28))
                    .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // Camera icon with floating animation
                VStack(spacing: 4) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: min(40, UIScreen.main.bounds.width * 0.1), weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [DesignSystem.Colors.primary, DesignSystem.Colors.primaryDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .offset(y: animateFloat ? -2 : 2)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateFloat)
                    
                    // Subtle scan line animation
                    Rectangle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 30, height: 1.5)
                        .opacity(animateFloat ? 0.8 : 0.4)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateFloat)
                }
            }
            
            VStack(spacing: 8) {
                Text("Scan Prescription")
                    .font(DesignSystem.Typography.displaySmall(weight: .bold, family: .avenir))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.textPrimary, DesignSystem.Colors.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)
                
                Text("Quick & accurate medication capture")
                    .font(DesignSystem.Typography.bodyMedium(weight: .regular, family: .sfPro))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Quick stats row
            HStack(spacing: 24) {
                QuickFeature(icon: "bolt.fill", text: "Fast & Accurate", color: DesignSystem.Colors.warning)
                QuickFeature(icon: "shield.fill", text: "Secure", color: DesignSystem.Colors.success)
                QuickFeature(icon: "checkmark.seal.fill", text: "Verified", color: DesignSystem.Colors.primary)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(min(28, UIScreen.main.bounds.width * 0.07))
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(DesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.primary.opacity(0.2),
                                    DesignSystem.Colors.primaryLight.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: DesignSystem.Colors.primary.opacity(0.15), radius: 12, x: 0, y: 6)
        )
        .onAppear {
            animateGlow = true
            animateFloat = true
        }
    }
}

struct QuickFeature: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(text)
                .font(DesignSystem.Typography.statusText())
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct ScanOptionsCard: View {
    let onCameraScan: () -> Void
    let onImageScan: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "viewfinder")
                    .foregroundColor(DesignSystem.Colors.primary)
                    .font(DesignSystem.Typography.headingMedium(weight: .medium, family: .avenir))
                
                Text("Choose Scan Method")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold, family: .avenir))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                ScanOptionButton(
                    title: "Scan with Camera",
                    subtitle: "Point your camera at the prescription label",
                    icon: "camera.fill",
                    color: DesignSystem.Colors.primary,
                    action: onCameraScan
                )
                
                ScanOptionButton(
                    title: "Choose from Photos",
                    subtitle: "Select an existing photo from your library",
                    icon: "photo.fill",
                    color: DesignSystem.Colors.secondary,
                    action: onImageScan
                )
            }
        }
        .padding(24)
        .cardStyle()
    }
}

struct ScanOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: max(16, UIScreen.main.bounds.width * 0.04)) {
                let iconSize = min(max(UIScreen.main.bounds.width * 0.12, 44), 60)

                ZStack {
                    RoundedRectangle(cornerRadius: min(14, iconSize * 0.25))
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.15), color.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: iconSize, height: iconSize)

                    Image(systemName: icon)
                        .font(.system(size: min(24, iconSize * 0.45), weight: .medium))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(DesignSystem.Typography.cardTitle())
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.bodySmall(weight: .regular, family: .sfPro))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color.opacity(0.7))
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isPressed)
            }
            .padding(max(18, UIScreen.main.bounds.width * 0.045))
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(DesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [color.opacity(0.3), color.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: color.opacity(0.2), radius: isPressed ? 2 : 8, x: 0, y: isPressed ? 1 : 4)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct ScanInstructionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(DesignSystem.Colors.warning)
                
                Text("Scanning Tips")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold, family: .avenir))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                InstructionRow(
                    icon: "camera.viewfinder",
                    text: "Ensure good lighting and hold your device steady"
                )
                
                InstructionRow(
                    icon: "text.alignleft",
                    text: "Make sure the prescription label text is clear and readable"
                )
                
                InstructionRow(
                    icon: "hand.raised.fill",
                    text: "Avoid shadows and reflections on the label"
                )
                
                InstructionRow(
                    icon: "checkmark.shield.fill",
                    text: "Review the scanned information before saving"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignSystem.Colors.warningLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DesignSystem.Colors.warning.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct InstructionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 20)
            
            Text(text)
                .font(DesignSystem.Typography.bodyMedium(weight: .regular))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct AlternativeActionCard: View {
    let onAddManually: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Can't scan right now?")
                .font(DesignSystem.Typography.statusText())
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Button(action: onAddManually) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("Add Prescription Manually")
                        .font(DesignSystem.Typography.bodyMedium(weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(DesignSystem.Colors.primaryLight)
                        )
                )
                .foregroundColor(DesignSystem.Colors.primary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Placeholder Views

struct PlaceholderScannerView: View {
    @Binding var isPresented: Bool
    let prescriptionStore: PrescriptionStore
    @State private var isShowingAddPrescription = false
    @State private var pulseAnimation = false
    @State private var scanLinePosition: CGFloat = 0
    @State private var isScanning = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Black camera background
                Color.black
                    .ignoresSafeArea()
                
                // Camera viewfinder overlay
                CameraOverlayView(scanLinePosition: $scanLinePosition, isScanning: $isScanning)
                
                VStack {
                    Spacer()
                    
                    // Bottom control panel
                    VStack(spacing: min(24, UIScreen.main.bounds.height * 0.03)) {
                        // Instructions
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "doc.text.viewfinder")
                                    .font(.system(size: min(24, UIScreen.main.bounds.width * 0.06), weight: .medium))
                                    .foregroundColor(.white)

                                Text("Position prescription label in frame")
                                    .font(.system(size: min(18, UIScreen.main.bounds.width * 0.045), weight: .medium))
                                    .foregroundColor(.white)
                            }

                            Text("Ensure good lighting and keep text clear")
                                .font(.system(size: min(14, UIScreen.main.bounds.width * 0.035)))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, max(24, UIScreen.main.bounds.width * 0.06))
                        
                        // Action buttons
                        HStack(spacing: max(20, UIScreen.main.bounds.width * 0.05)) {
                            let buttonSize = min(max(UIScreen.main.bounds.width * 0.12, 44), 60)
                            let captureButtonSize = min(max(UIScreen.main.bounds.width * 0.18, 70), 90)

                            // Cancel button
                            Button(action: {
                                isPresented = false
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: min(20, buttonSize * 0.4), weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: buttonSize, height: buttonSize)
                                    .background(
                                        Circle()
                                            .fill(.ultraThickMaterial)
                                            .overlay(
                                                Circle()
                                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                            }

                            Spacer()

                            // Camera capture button
                            Button(action: {
                                // Start scanning animation
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    isScanning = true
                                }

                                // Simulate scan completion
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    isPresented = false
                                    isShowingAddPrescription = true
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: captureButtonSize, height: captureButtonSize)

                                    Circle()
                                        .stroke(.black, lineWidth: min(4, captureButtonSize * 0.05))
                                        .frame(width: captureButtonSize - 10, height: captureButtonSize - 10)

                                    if isScanning {
                                        Circle()
                                            .fill(DesignSystem.Colors.primary)
                                            .frame(width: captureButtonSize - 20, height: captureButtonSize - 20)
                                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                            .opacity(pulseAnimation ? 0.6 : 1.0)
                                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)
                                    }
                                }
                            }
                            .scaleEffect(isScanning ? 0.95 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: isScanning)

                            Spacer()

                            // Manual add button
                            Button(action: {
                                isPresented = false
                                isShowingAddPrescription = true
                            }) {
                                Image(systemName: "keyboard")
                                    .font(.system(size: min(20, buttonSize * 0.4), weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: buttonSize, height: buttonSize)
                                    .background(
                                        Circle()
                                            .fill(.ultraThickMaterial)
                                            .overlay(
                                                Circle()
                                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                        .padding(.horizontal, max(24, UIScreen.main.bounds.width * 0.06))
                    }
                    .padding(.bottom, max(40, UIScreen.main.bounds.height * 0.05))
                }
        }
        .navigationBarHidden(true)
        .onAppear {
            pulseAnimation = true
            // Start scan line animation
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                scanLinePosition = 1.0
            }
        }
        .onChange(of: isScanning) { scanning in
            if scanning {
                pulseAnimation = true
            }
        }
        .sheet(isPresented: $isShowingAddPrescription) {
            AddPrescriptionView(prescriptionStore: prescriptionStore)
        }
    }
}

struct CameraOverlayView: View {
    @Binding var scanLinePosition: CGFloat
    @Binding var isScanning: Bool
    @State private var cornerAnimation = false
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let maxWidth = min(size.width * 0.8, size.width - 40)
            let maxHeight = min(size.height * 0.5, size.height - 200)
            let frameWidth: CGFloat = maxWidth
            let frameHeight: CGFloat = min(frameWidth * 0.7, maxHeight)
            
            VStack {
                Spacer()
                
                ZStack {
                    // Semi-transparent overlay with cutout
                    Rectangle()
                        .fill(.black.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .frame(width: frameWidth, height: frameHeight)
                                .blendMode(.destinationOut)
                        )
                        .compositingGroup()
                    
                    // Frame corners
                    VStack {
                        HStack {
                            CornerFrame(position: .topLeft)
                            Spacer()
                            CornerFrame(position: .topRight)
                        }
                        
                        Spacer()
                        
                        HStack {
                            CornerFrame(position: .bottomLeft)
                            Spacer()
                            CornerFrame(position: .bottomRight)
                        }
                    }
                    .frame(width: frameWidth, height: frameHeight)
                    .scaleEffect(cornerAnimation ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: cornerAnimation)
                    
                    // Scanning line
                    if isScanning {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        DesignSystem.Colors.primary,
                                        DesignSystem.Colors.primary,
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: frameWidth - 40, height: 3)
                            .offset(y: (frameHeight * scanLinePosition) - (frameHeight / 2))
                            .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: scanLinePosition)
                    }
                    
                    // Center target indicator
                    if !isScanning {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 32, weight: .thin))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("Prescription Label")
                                .font(DesignSystem.Typography.captionMedium(weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            cornerAnimation = true
        }
        .onChange(of: isScanning) { scanning in
            if scanning {
                // Reset and start scan line animation
                scanLinePosition = 0
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    scanLinePosition = 1.0
                }
            }
        }
    }
}

struct CornerFrame: View {
    let position: CornerPosition
    
    enum CornerPosition {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    var body: some View {
        Group {
            switch position {
            case .topLeft:
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 0) {
                        Rectangle()
                            .frame(width: 25, height: 3)
                        Rectangle()
                            .frame(width: 3, height: 25)
                    }
                    Rectangle()
                        .frame(width: 3, height: 25)
                        .offset(x: 22)
                }
            case .topRight:
                VStack(alignment: .trailing, spacing: 0) {
                    HStack(alignment: .top, spacing: 0) {
                        Rectangle()
                            .frame(width: 3, height: 25)
                        Rectangle()
                            .frame(width: 25, height: 3)
                    }
                    Rectangle()
                        .frame(width: 3, height: 25)
                        .offset(x: -22)
                }
            case .bottomLeft:
                VStack(alignment: .leading, spacing: 0) {
                    Rectangle()
                        .frame(width: 3, height: 25)
                        .offset(x: 22)
                    HStack(alignment: .bottom, spacing: 0) {
                        Rectangle()
                            .frame(width: 25, height: 3)
                        Rectangle()
                            .frame(width: 3, height: 25)
                    }
                }
            case .bottomRight:
                VStack(alignment: .trailing, spacing: 0) {
                    Rectangle()
                        .frame(width: 3, height: 25)
                        .offset(x: -22)
                    HStack(alignment: .bottom, spacing: 0) {
                        Rectangle()
                            .frame(width: 3, height: 25)
                        Rectangle()
                            .frame(width: 25, height: 3)
                    }
                }
            }
        }
        .foregroundColor(.white)
        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 0)
    }
}

struct ImagePickerView: View {
    let prescriptionStore: PrescriptionStore
    @Environment(\.presentationMode) var presentationMode
    @State private var isShowingAddPrescription = false
    @State private var shimmerAnimation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                DesignSystem.Gradients.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Animated photo icon
                    VStack(spacing: 20) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .frame(width: 140, height: 140)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green.opacity(0.15), .mint.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.green.opacity(0.3), .mint.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .scaleEffect(shimmerAnimation ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: shimmerAnimation)
                            
                            Image(systemName: "photo.fill")
                                .font(.system(size: 64, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(spacing: 12) {
                            Text("Photo Library")
                                .font(DesignSystem.Typography.headingLarge(weight: .bold))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text("Select a photo of your prescription from your library")
                                .font(DesignSystem.Typography.bodyMedium(weight: .regular, family: .sfPro))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .lineLimit(nil)
                        }
                    }
                    
                    // Instruction card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(DesignSystem.Colors.success)
                                .font(DesignSystem.Typography.headingMedium(weight: .semibold, family: .avenir))
                            
                            Text("Best Results Tips")
                                .font(DesignSystem.Typography.headingMedium(weight: .semibold, family: .avenir))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            InstructionTip(icon: "camera", text: "Clear, well-lit photos work best")
                            InstructionTip(icon: "text.alignleft", text: "Ensure text is readable and unblurred")
                            InstructionTip(icon: "rectangle.inset.filled", text: "Frame the entire prescription label")
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(DesignSystem.Colors.successLight)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(DesignSystem.Colors.success.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 24)
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button("Choose from Photos") {
                            // Photo picker functionality would go here
                            // For now, we'll show the manual add option
                            presentationMode.wrappedValue.dismiss()
                            isShowingAddPrescription = true
                        }
                        .font(DesignSystem.Typography.cardTitle())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(DesignSystem.Gradients.successGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 24)
                        .shadow(color: DesignSystem.Colors.success.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Button("Add Manually Instead") {
                            presentationMode.wrappedValue.dismiss()
                            isShowingAddPrescription = true
                        }
                        .font(DesignSystem.Typography.bodyMedium(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.success)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(DesignSystem.Colors.success.opacity(0.3), lineWidth: 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(DesignSystem.Colors.successLight)
                                )
                        )
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Select Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.success)
                }
            }
        }
        .onAppear {
            shimmerAnimation = true
        }
        .sheet(isPresented: $isShowingAddPrescription) {
            AddPrescriptionView(prescriptionStore: prescriptionStore)
        }
    }
}

struct InstructionTip: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(DesignSystem.Colors.success)
                .frame(width: 20)
            
            Text(text)
                .font(DesignSystem.Typography.captionLarge(weight: .regular))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
}
