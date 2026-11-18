import AVFoundation
import Combine
import SwiftUI

struct MeasureFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var dataStore: HealthDataStore

    @StateObject private var engine = MeasurementEngine()
    @StateObject private var camera = CameraService()

    @State private var mode: MeasuringMode
    @State private var permission: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var useFrontCamera = UserDefaults.standard.bool(forKey: UDKey.useFrontCamera)
    @State private var sensor: SimulatedSensor?
    @State private var resultMeasurement: HRMeasurement?
    @State private var showTutorial = false
    @State private var showTagPicker = false
    @State private var showCameraTutorial = false
    @State private var showMetricInfo: ResultMetric?
    @State private var showRetakeConfirm = false
    @State private var showDeleteConfirm = false
    @State private var originalBrightness: CGFloat?

    init() {
        let stored = UserDefaults.standard.string(forKey: UDKey.measuringMode)
            .flatMap(MeasuringMode.init(rawValue:))
        let defaultMode: MeasuringMode = UserDefaults.standard.bool(forKey: UDKey.isPostOnboardingPassed)
            ? RemoteConfig.measuringMode.afterOnboarding
            : RemoteConfig.measuringMode.default
        _mode = State(initialValue: stored ?? defaultMode)
    }

    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    private var cameraDenied: Bool {
        permission == .denied || permission == .restricted
    }

    var body: some View {
        ZStack {
            background
            if let resultMeasurement {
                MeasureResultView(measurement: resultMeasurement,
                                  onContinue: { dismiss() },
                                  onRetake: { showRetakeConfirm = true },
                                  onDelete: { showDeleteConfirm = true },
                                  onTag: { showTagPicker = true },
                                  onMetricInfo: { showMetricInfo = $0 })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                measuringContent
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            beginAppearance()
            #if DEBUG
            if ProcessInfo.processInfo.environment["HEARTICA_AUTOSTART"] == "1" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { startTapped() }
            }
            #endif
        }
        .onDisappear { endAppearance() }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            engine.tick()
        }
        .sheet(isPresented: $showTutorial) {
            TutorialSheet()
        }
        .sheet(isPresented: $showCameraTutorial) {
            CameraTutorialSheet {
                showCameraTutorial = false
                requestCameraAndStart()
            }
        }
        .sheet(isPresented: $showTagPicker) {
            if let id = resultMeasurement?.id {
                TagPickerView(selectedTagId: resultMeasurement?.tagId) { tagId in
                    dataStore.setTag(measurementID: id, tagId: tagId)
                    resultMeasurement = dataStore.measurement(id: id)
                }
                .presentationDetents([.large])
            }
        }
        .sheet(item: $showMetricInfo) { metric in
            MetricInfoSheet(metric: metric)
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog("Delete this measurement and take a new one?",
                            isPresented: $showRetakeConfirm, titleVisibility: .visible) {
            Button("Retake", role: .destructive) { retake() }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Are you sure you want to delete this measurement?",
                            isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let id = resultMeasurement?.id { dataStore.deleteMeasurement(id: id) }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: Background

    private var background: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.055, green: 0.035, blue: 0.075),
                                    Color(red: 0.16, green: 0.02, blue: 0.09),
                                    Color(red: 0.03, green: 0.02, blue: 0.04)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            Circle()
                .fill(AppColor.brand.opacity(0.14))
                .frame(width: 420, height: 420)
                .blur(radius: 100)
                .offset(y: -80)
        }
    }

    // MARK: Measuring content

    private var measuringContent: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: 4)
            cameraCircle
            stepLabels
            Spacer(minLength: 8)
            bottomPanel
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                engine.stop()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white.opacity(0.10)))
            }
            Spacer()
            Text("Measurement")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Button {
                useFrontCamera.toggle()
                UserDefaults.standard.set(useFrontCamera, forKey: UDKey.useFrontCamera)
                if engine.step == .measuring || engine.step == .calibrating {
                    engine.stop()
                    engine.reset()
                }
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white.opacity(0.10)))
            }
            .opacity(RemoteConfig.frontCameraEnabled ? 1 : 0)
            .disabled(engine.step == .measuring || engine.step == .calibrating)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var cameraCircle: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 286, height: 286)
            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
                .frame(width: 306, height: 306)

            if !isSimulator, permission == .authorized {
                CameraPreviewView(session: camera.previewSession)
                    .frame(width: 258, height: 258)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
            } else {
                Circle()
                    .fill(LinearGradient(colors: [Color(red: 0.36, green: 0.06, blue: 0.14),
                                                  Color(red: 0.12, green: 0.03, blue: 0.07)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 258, height: 258)
                    .overlay(
                        Group {
                            if engine.step == .idle {
                                VStack(spacing: 10) {
                                    Image(systemName: fingerSymbol)
                                        .font(.system(size: 52, weight: .light))
                                        .foregroundColor(.white.opacity(0.45))
                                    Text("Place your fingertip\nover the camera")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white.opacity(0.55))
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                    )
            }

            progressRing

            if engine.step == .measuring || engine.step == .calibrating {
                VStack(spacing: 2) {
                    if engine.step == .measuring {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(engine.pulse > 0 ? "\(engine.pulse)" : "—")
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .contentTransition(.numericText())
                            Text("bpm")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Text(engine.lastNN > 0 ? LF("NN %d ms", engine.lastNN) : L("Detecting pulse…"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.55))
                    } else {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(.white.opacity(0.55))
                    }
                }
            }
        }
        .frame(height: 310)
        .animation(.easeInOut(duration: 0.25), value: engine.step)
    }

    private var fingerSymbol: String {
        useFrontCamera ? "camera.front" : "hand.point.up.left.fill"
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 5)
                .frame(width: 268, height: 268)
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    AngularGradient(colors: [AppColor.brand, Color(red: 1, green: 0.62, blue: 0.45), AppColor.brand],
                                    center: .center),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: 268, height: 268)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: ringProgress)
        }
    }

    private var ringProgress: Double {
        switch engine.step {
        case .idle: return 1
        case .calibrating: return min(engine.elapsed / 3.0, 1) * 0.12
        case .measuring: return 0.12 + engine.progress * 0.88
        case .finished: return 1
        case .failed: return 0
        }
    }

    private var stepLabels: some View {
        VStack(spacing: 7) {
            switch engine.step {
            case .idle:
                Text("Measure your heart rate")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(hintText)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 36)
            case .calibrating:
                HStack(spacing: 8) {
                    Text("Step 1")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppColor.brand)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AppColor.brand.opacity(0.18)))
                    Text("Calibrating")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Text("Keep your finger steady and well lit")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
            case .measuring:
                HStack(spacing: 8) {
                    Text("Step 2")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppColor.brand)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AppColor.brand.opacity(0.18)))
                    Text("Measuring")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Text(LF("%d%% · %ds remaining", Int(engine.progress * 100), max(0, Int(mode.duration - engine.elapsed))))
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
            case .failed(let message):
                Text("Measurement Failed")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(L(message))
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            case .finished:
                Text("Done")
                    .foregroundColor(.white)
            }
        }
        .frame(height: 86)
        .padding(.top, 12)
    }

    private var hintText: String {
        if useFrontCamera {
            return L("Place your finger over the selfie camera; ensure bright, even lighting.")
        }
        return L("Place your finger over the rear camera and flash until the window turns red.")
    }

    // MARK: Bottom panel

    private var bottomPanel: some View {
        VStack(spacing: 14) {
            if engine.step == .idle || isFailed {
                modePicker
            }

            Button {
                showTutorial = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 13))
                        .foregroundColor(AppColor.warning)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("Quick Tip"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        Text(L("Don't press your finger too hard. Stay relaxed, breathe calmly, and wait for the measurement to complete."))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.07)))
            }
            .buttonStyle(.plain)

            if cameraDenied && !isSimulator {
                VStack(spacing: 8) {
                    Text("No Access to Camera")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Enable Camera access to measure your heart rate.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                    Button("Go to Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(color: AppColor.brand))
                }
            } else if engine.step == .idle || isFailed {
                Button(action: startTapped) {
                    Text("Start Measurement")
                }
                .buttonStyle(PrimaryButtonStyle(color: AppColor.brand))
            } else if engine.step == .measuring || engine.step == .calibrating {
                Button {
                    engine.stop()
                    engine.reset()
                    stopSensors()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Capsule().fill(Color.white.opacity(0.10)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 12)
    }

    private var isFailed: Bool {
        if case .failed = engine.step { return true }
        return false
    }

    private var modePicker: some View {
        HStack(spacing: 4) {
            ForEach(MeasuringMode.allCases) { item in
                Button {
                    withAnimation(.easeOut(duration: 0.15)) { mode = item }
                    UserDefaults.standard.set(item.rawValue, forKey: UDKey.measuringMode)
                } label: {
                    VStack(spacing: 2) {
                        Text(item.title)
                            .font(.system(size: 13, weight: .semibold))
                        Text(LF("%ds", Int(item.duration)))
                            .font(.system(size: 9, weight: .medium))
                            .opacity(0.6)
                    }
                    .foregroundColor(mode == item ? .black : .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(mode == item ? Color.white : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.08)))
    }

    // MARK: Actions

    private func startTapped() {
        if isSimulator {
            start()
        } else if permission == .notDetermined {
            showCameraTutorial = true
        } else if permission == .denied || permission == .restricted {
            showCameraTutorial = true
        } else {
            start()
        }
    }

    private func requestCameraAndStart() {
        Task {
            let granted = await camera.requestAccess()
            await MainActor.run {
                permission = AVCaptureDevice.authorizationStatus(for: .video)
                if granted {
                    start()
                }
            }
        }
    }

    private func start() {
        engine.configure(mode: mode, onComplete: { metrics, _ in
            let measurement = dataStore.addHeartMeasurement(metrics, kind: .camera,
                                                            tagId: nil,
                                                            time: Date())
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.easeInOut(duration: 0.3)) {
                self.resultMeasurement = measurement
            }
            stopSensors()
            restoreBrightness()
        }, onFailure: { _ in
            stopSensors()
        })
        engine.start()
        UISelectionFeedbackGenerator().selectionChanged()
        UIScreen.main.brightness = 1.0

        if isSimulator {
            let sensor = SimulatedSensor()
            self.sensor = sensor
            sensor.start { red, green, blue, time in
                engine.ingest(red: red, green: green, blue: blue, at: time)
            }
        } else {
            camera.onSample = { red, green, blue, time in
                engine.ingest(red: red, green: green, blue: blue, at: time)
            }
            camera.start(position: useFrontCamera ? .front : .back, torch: !useFrontCamera)
        }
    }

    private func stopSensors() {
        sensor?.stop()
        sensor = nil
        camera.stop()
        restoreBrightness()
    }

    private func retake() {
        if let id = resultMeasurement?.id { dataStore.deleteMeasurement(id: id) }
        resultMeasurement = nil
        engine.reset()
        showRetakeConfirm = false
    }

    private func beginAppearance() {
        originalBrightness = UIScreen.main.brightness
        if permission == .notDetermined {
            // The explanation sheet is shown the first time the user presses Start.
        }
    }

    private func restoreBrightness() {
        if let originalBrightness {
            UIScreen.main.brightness = originalBrightness
            self.originalBrightness = nil
        }
    }

    private func endAppearance() {
        engine.stop()
        stopSensors()
        restoreBrightness()
    }
}

// MARK: - Camera preview

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.previewLayer.session = session
    }

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

// MARK: - Tutorial sheet (§3.9)

struct TutorialSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expanded: Set<String> = []

    private let items: [(id: String, title: String, body: String)] = [
        ("withOneHand", "Basic Setup",
         "Place your fingertip over the rear camera and flash until the window turns red.\nStay still and relaxed—no need to press hard."),
        ("frontCamera", "Front Camera Mode",
         "Place your fingertip over the selfie camera. Since the front camera has no flash, use steady, bright, indirect light."),
        ("withTwoHands", "With Two Hands",
         "Place a finger over the rear camera and use your other hand to cover both the flash and your finger. This keeps the fingertip well lit and ensures a stable reading.")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Keep Your Finger Well Lit")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("Make sure light passes through your fingertip so the camera can accurately detect tiny changes in blood flow — that's how PPG works.")
                            .font(.system(size: 13))
                            .foregroundColor(AppColor.textSecondary)
                    }
                    ForEach(items, id: \.id) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if expanded.contains(item.id) { expanded.remove(item.id) }
                                    else { expanded.insert(item.id) }
                                }
                            } label: {
                                HStack {
                                    Text(item.title)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppColor.textPrimary)
                                    Spacer()
                                    Image(systemName: expanded.contains(item.id) ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(AppColor.textSecondary)
                                }
                            }
                            if expanded.contains(item.id) {
                                Text(L(item.body))
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColor.textSecondary)
                                    .lineSpacing(3)
                            }
                        }
                        .card(padding: 16, radius: 18)
                    }
                    Text("These instructions are not a substitute for professional medical advice.")
                        .font(.system(size: 11))
                        .foregroundColor(AppColor.textSecondary)
                }
                .padding(20)
            }
            .screenBackground()
            .navigationTitle("How It Works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Camera permission tutorial

struct CameraTutorialSheet: View {
    let onAllow: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppColor.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(AppColor.surfaceAlt))
                }
            }
            Spacer()
            ZStack {
                Circle().fill(AppColor.brandSoft).frame(width: 140, height: 140)
                Image(systemName: "camera.fill")
                    .font(.system(size: 54))
                    .foregroundColor(AppColor.brand)
            }
            Text("Heartica Works Only with Camera Permission")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(AppColor.textPrimary)
            Text("You'll see a prompt asking for access to your iPhone camera on the next screen.")
                .font(.system(size: 14))
                .foregroundColor(AppColor.textSecondary)
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 12) {
                point("Don't worry — here's what this means:")
                point("Heartica **will not** have access to your photos")
                point("Heartica **will never** take or save photos")
                point("Heartica **will only** run its algorithms when your finger covers the camera")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Button("Allow") { onAllow() }
                .buttonStyle(PrimaryButtonStyle())
            Button("Not Now") { dismiss() }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColor.textSecondary)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 18)
        .screenBackground()
    }

    private func point(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(AppColor.brand).frame(width: 5, height: 5).padding(.top, 6)
            Text(.init(L(text)))
                .font(.system(size: 13))
                .foregroundColor(AppColor.textSecondary)
                .lineSpacing(2)
        }
    }
}
