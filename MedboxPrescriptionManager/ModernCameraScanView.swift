import SwiftUI
import AVFoundation
import Vision

struct ModernCameraScanView: View {
    @Binding var isPresented: Bool
    let prescriptionStore: PrescriptionStore
    @StateObject private var cameraManager = CameraManager()
    
    @State private var isScanning = false
    @State private var scanResult: String?
    @State private var showingResult = false
    @State private var flashMode = false
    @State private var showingManualEntry = false
    @State private var scaleEffect: CGFloat = 1.0
    @State private var showingHelpSheet = false
    
    var body: some View {
        ZStack {
            // Camera preview background
            CameraPreviewView(cameraManager: cameraManager)
                .ignoresSafeArea()
            
            // Dark overlay with scanning frame
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .overlay(
                    scanningFrameOverlay
                )
            
            // Top bar with controls
            VStack {
                topControlBar
                
                Spacer()
                
                // Bottom control bar
                bottomControlBar
            }
            
            // Scanning animation overlay
            if isScanning {
                scanningAnimation
            }
            
            // Success overlay
            if showingResult && scanResult != nil {
                successOverlay
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            cameraManager.checkPermissions()
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .sheet(isPresented: $showingManualEntry) {
            AddPrescriptionView(prescriptionStore: prescriptionStore)
        }
        .sheet(isPresented: $showingHelpSheet) {
            ScanningHelpView()
        }
    }
    
    private var topControlBar: some View {
        HStack {
            // Close button
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            
            Spacer()
            
            // Title
            Text("Scan Prescription")
                .font(DesignSystem.Typography.titleMedium(weight: .semibold, family: .avenir))
                .foregroundColor(.white)
                .shadow(radius: 2)
            
            Spacer()
            
            // Flash toggle
            Button(action: { 
                flashMode.toggle()
                cameraManager.toggleFlash(flashMode) 
            }) {
                Image(systemName: flashMode ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(flashMode ? .yellow : .white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.horizontal, max(DesignSystem.Spacing.lg, 16))
        .padding(.top, max(DesignSystem.Spacing.sm, 8))
    }
    
    private var scanningFrameOverlay: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let frameWidth: CGFloat = min(screenWidth * 0.85, screenWidth - 40)
            let frameHeight: CGFloat = min(frameWidth * 0.6, screenHeight * 0.4)
            
            ZStack {
                // Create hole in overlay for scanning area
                Rectangle()
                    .foregroundColor(.clear)
                    .background(Color.black.opacity(0.6))
                    .mask(
                        Rectangle()
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .frame(width: frameWidth, height: frameHeight)
                                    .blendMode(.destinationOut)
                            )
                            .compositingGroup()
                    )
                
                // Scanning frame with animated corners
                VStack {
                    Spacer()
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.clear, lineWidth: 0)
                            .frame(width: frameWidth, height: frameHeight)
                        
                        // Animated corner indicators
                        scanningCorners
                            .frame(width: frameWidth, height: frameHeight)
                        
                        // Center instructions (only when not scanning)
                        if !isScanning {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.text.viewfinder")
                                    .font(.system(size: 32, weight: .ultraLight))
                                    .foregroundColor(.white)
                                
                                Text("Position label in frame")
                                    .font(DesignSystem.Typography.captionLarge(weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var scanningCorners: some View {
        VStack {
            HStack {
                ScanCorner(position: .topLeft)
                    .scaleEffect(scaleEffect)
                Spacer()
                ScanCorner(position: .topRight)
                    .scaleEffect(scaleEffect)
            }
            
            Spacer()
            
            HStack {
                ScanCorner(position: .bottomLeft)
                    .scaleEffect(scaleEffect)
                Spacer()
                ScanCorner(position: .bottomRight)
                    .scaleEffect(scaleEffect)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                scaleEffect = 1.1
            }
        }
    }
    
    private var bottomControlBar: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let horizontalPadding = max(min(screenWidth * 0.1, 40), 20)
            let buttonSize: CGFloat = min(max(screenWidth * 0.12, 44), 60)
            let captureButtonSize: CGFloat = min(max(screenWidth * 0.18, 65), 85)

            HStack {
                // Manual entry button
                Button(action: { showingManualEntry = true }) {
                    VStack(spacing: 4) {
                        Image(systemName: "keyboard")
                            .font(.system(size: min(22, buttonSize * 0.4), weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: buttonSize, height: buttonSize)
                            .background(.ultraThinMaterial, in: Circle())

                        Text("Manual")
                            .font(.system(size: min(12, buttonSize * 0.2)))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .frame(width: max(buttonSize + 10, 60))

                Spacer()

                // Main scan button
                Button(action: captureAndScan) {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: captureButtonSize, height: captureButtonSize)
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            .scaleEffect(isScanning ? 0.9 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: isScanning)

                        Circle()
                            .stroke(.black, lineWidth: 3)
                            .frame(width: captureButtonSize - 13, height: captureButtonSize - 13)

                        if isScanning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
                                .scaleEffect(1.1)
                        } else {
                            Image(systemName: "camera.fill")
                                .font(.system(size: min(26, captureButtonSize * 0.35), weight: .medium))
                                .foregroundColor(.black)
                        }
                    }
                }
                .disabled(isScanning)

                Spacer()

                // Settings/help button
                Button(action: {
                    showingHelpSheet = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: min(22, buttonSize * 0.4), weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: buttonSize, height: buttonSize)
                            .background(.ultraThinMaterial, in: Circle())

                        Text("Help")
                            .font(.system(size: min(12, buttonSize * 0.2)))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .frame(width: max(buttonSize + 10, 60))
            }
            .frame(width: geometry.size.width)
            .padding(.horizontal, horizontalPadding)
        }
        .frame(height: max(100, UIScreen.main.bounds.height * 0.12))
        .padding(.bottom, max(DesignSystem.Spacing.lg, 16))
    }
    
    private var scanningAnimation: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2.0)
                
                Text("Scanning...")
                    .font(DesignSystem.Typography.titleMedium(weight: .bold, family: .avenir))
                    .foregroundColor(.white)
                
                Text("Hold still while we read your prescription")
                    .font(DesignSystem.Typography.bodyMedium(weight: .medium, family: .sfPro))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(40)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }
    
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Success checkmark
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.success)
                        .frame(width: 80, height: 80)
                        .shadow(color: DesignSystem.Colors.success.opacity(0.4), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(scaleEffect)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        scaleEffect = 1.0
                    }
                }
                
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text("Scan Successful!")
                        .font(DesignSystem.Typography.titleLarge(weight: .bold, family: .avenir))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                    
                    Text("Prescription information captured")
                        .font(DesignSystem.Typography.bodyMedium(weight: .medium, family: .sfPro))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                
                // Action buttons
                VStack(spacing: 16) {
                    Button("Review & Save") {
                        // Process the scan result
                        processScanResult()
                    }
                    .font(DesignSystem.Typography.buttonText())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.lg)
                    .background(DesignSystem.Colors.success, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    .shadow(color: DesignSystem.Colors.success.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Button("Scan Again") {
                        resetScan()
                    }
                    .font(DesignSystem.Typography.bodyMedium(weight: .medium, family: .sfPro))
                    .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 40)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 32)
        }
    }
    
    private func captureAndScan() {
        guard !isScanning else { return }
        
        isScanning = true
        
        cameraManager.capturePhoto { image in
            DispatchQueue.main.async {
                if let image = image {
                    self.performOCR(on: image)
                } else {
                    self.isScanning = false
                }
            }
        }
    }
    
    private func performOCR(on image: UIImage) {
        let request = VNRecognizeTextRequest { request, error in
            DispatchQueue.main.async {
                self.isScanning = false
                
                if let observations = request.results as? [VNRecognizedTextObservation] {
                    let recognizedStrings = observations.compactMap { observation in
                        return observation.topCandidates(1).first?.string
                    }
                    
                    let fullText = recognizedStrings.joined(separator: "\n")
                    if !fullText.isEmpty {
                        self.scanResult = fullText
                        self.showingResult = true
                    }
                }
            }
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        
        guard let cgImage = image.cgImage else { return }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
    
    private func processScanResult() {
        guard let result = scanResult else { return }
        
        // Parse the scanned text to extract prescription info
        let prescriptionInfo = parsePrescriptionText(result)
        
        // Create and add prescription
        let prescription = Prescription(
            name: prescriptionInfo.medicineName ?? "Unknown Medicine",
            dose: prescriptionInfo.dose ?? "Unknown Dose",
            frequency: prescriptionInfo.frequency ?? "Daily",
            startDate: Date()
        )
        
        prescriptionStore.addPrescription(prescription)
        isPresented = false
    }
    
    private func resetScan() {
        scanResult = nil
        showingResult = false
        scaleEffect = 1.0
    }
    
    private func parsePrescriptionText(_ text: String) -> PrescriptionInfo {
        // Simple parsing logic - in production you'd want more sophisticated NLP
        let lines = text.components(separatedBy: .newlines)
        
        var medicineName: String?
        var dose: String?
        var frequency: String?
        
        // Look for common patterns
        for line in lines {
            let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Medicine name (usually contains drug-like words)
            if medicineName == nil && containsDrugLikeWord(cleanLine) {
                medicineName = cleanLine
            }
            
            // Dose (contains mg, ml, units, etc.)
            if dose == nil && containsDosePattern(cleanLine) {
                dose = extractDose(from: cleanLine)
            }
            
            // Frequency (contains daily, twice, etc.)
            if frequency == nil && containsFrequencyPattern(cleanLine) {
                frequency = extractFrequency(from: cleanLine)
            }
        }
        
        return PrescriptionInfo(
            fullText: text,
            medicineName: medicineName,
            dose: dose,
            frequency: frequency,
            prescriptionNumber: nil,
            fillDate: nil,
            dateOfBirth: nil
        )
    }
    
    private func containsDrugLikeWord(_ text: String) -> Bool {
        let commonSuffixes = ["pril", "statin", "olol", "sartan", "zole", "cin", "mycin"]
        return commonSuffixes.contains { suffix in
            text.lowercased().contains(suffix)
        } || text.count > 4 && text.count < 20 && text.rangeOfCharacter(from: .letters) != nil
    }
    
    private func containsDosePattern(_ text: String) -> Bool {
        let doseRegex = try! NSRegularExpression(pattern: "\\d+\\s*(mg|ml|mcg|g|units?|iu|%)", options: .caseInsensitive)
        return doseRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }
    
    private func extractDose(from text: String) -> String {
        let doseRegex = try! NSRegularExpression(pattern: "\\d+\\s*(mg|ml|mcg|g|units?|iu|%)", options: .caseInsensitive)
        if let match = doseRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            return String(text[Range(match.range, in: text)!])
        }
        return text
    }
    
    private func containsFrequencyPattern(_ text: String) -> Bool {
        let frequencyWords = ["daily", "twice", "once", "morning", "evening", "times", "per day", "every"]
        return frequencyWords.contains { word in
            text.lowercased().contains(word)
        }
    }
    
    private func extractFrequency(from text: String) -> String {
        let lowercased = text.lowercased()
        if lowercased.contains("twice") || lowercased.contains("2") {
            return "Twice Daily"
        } else if lowercased.contains("three") || lowercased.contains("3") {
            return "Three Times Daily"
        } else if lowercased.contains("four") || lowercased.contains("4") {
            return "Four Times Daily"
        } else if lowercased.contains("morning") && lowercased.contains("evening") {
            return "Twice Daily (Morning & Evening)"
        } else if lowercased.contains("morning") {
            return "Once Daily (Morning)"
        } else if lowercased.contains("evening") {
            return "Once Daily (Evening)"
        }
        return "Once Daily"
    }
}

// MARK: - Supporting Views

struct ScanCorner: View {
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
                            .frame(width: 30, height: 4)
                        Rectangle()
                            .frame(width: 4, height: 30)
                    }
                    Rectangle()
                        .frame(width: 4, height: 30)
                        .offset(x: 26)
                }
            case .topRight:
                VStack(alignment: .trailing, spacing: 0) {
                    HStack(alignment: .top, spacing: 0) {
                        Rectangle()
                            .frame(width: 4, height: 30)
                        Rectangle()
                            .frame(width: 30, height: 4)
                    }
                    Rectangle()
                        .frame(width: 4, height: 30)
                        .offset(x: -26)
                }
            case .bottomLeft:
                VStack(alignment: .leading, spacing: 0) {
                    Rectangle()
                        .frame(width: 4, height: 30)
                        .offset(x: 26)
                    HStack(alignment: .bottom, spacing: 0) {
                        Rectangle()
                            .frame(width: 30, height: 4)
                        Rectangle()
                            .frame(width: 4, height: 30)
                    }
                }
            case .bottomRight:
                VStack(alignment: .trailing, spacing: 0) {
                    Rectangle()
                        .frame(width: 4, height: 30)
                        .offset(x: -26)
                    HStack(alignment: .bottom, spacing: 0) {
                        Rectangle()
                            .frame(width: 4, height: 30)
                        Rectangle()
                            .frame(width: 30, height: 4)
                    }
                }
            }
        }
        .foregroundColor(.white)
        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 0)
    }
}

// MARK: - Camera Manager

class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var isAuthorized = false
    @Published var session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    if granted {
                        self.setupCamera()
                    }
                }
            }
        default:
            isAuthorized = false
        }
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        session.commitConfiguration()
    }
    
    func startSession() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    func stopSession() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .background).async {
            self.session.stopRunning()
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func toggleFlash(_ isOn: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        if device.hasTorch {
            try? device.lockForConfiguration()
            device.torchMode = isOn ? .on : .off
            device.unlockForConfiguration()
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            captureCompletion?(nil)
            return
        }
        
        captureCompletion?(image)
        captureCompletion = nil
    }
}

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraManager.session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Help View

struct ScanningHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "camera.metering.center.weighted")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.primary)
                        
                        Text("How to Scan Prescriptions")
                            .font(DesignSystem.Typography.displaySmall(weight: .bold, family: .avenir))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Tips
                    VStack(spacing: 20) {
                        HelpTip(
                            icon: "light.max",
                            title: "Good Lighting",
                            description: "Ensure the prescription label is well-lit and easy to read."
                        )
                        
                        HelpTip(
                            icon: "camera.macro",
                            title: "Get Close",
                            description: "Position the camera close enough to clearly read the text on the label."
                        )
                        
                        HelpTip(
                            icon: "rectangle.on.rectangle",
                            title: "Frame the Label",
                            description: "Make sure the entire prescription label fits within the scanning frame."
                        )
                        
                        HelpTip(
                            icon: "hand.raised",
                            title: "Stay Steady",
                            description: "Hold the device steady to avoid blurry images during scanning."
                        )
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .background(DesignSystem.Gradients.backgroundGradient)
            .navigationTitle("Scanning Help")
            .navigationBarTitleDisplayMode(.inline)
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

struct HelpTip: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.headingSmall(weight: .semibold, family: .avenir))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(description)
                    .font(DesignSystem.Typography.bodyMedium(weight: .regular, family: .sfPro))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(20)
        .cardStyle()
    }
}