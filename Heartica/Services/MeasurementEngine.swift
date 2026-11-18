import AVFoundation
import Foundation
import SwiftUI

// MARK: - Measurement engine (frame -> peaks -> NN intervals -> metrics)

@MainActor
final class MeasurementEngine: ObservableObject {
    enum Step: Equatable {
        case idle
        case calibrating
        case measuring
        case finished
        case failed(String)
    }

    @Published private(set) var step: Step = .idle
    @Published private(set) var pulse: Int = 0
    @Published private(set) var lastNN: Int = 0
    @Published private(set) var progress: Double = 0
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var waveform: [Double] = []
    @Published private(set) var intervalCount: Int = 0

    private(set) var mode: MeasuringMode = .fast
    private var running = false
    private var phaseStart = Date()
    private var measureStart: Date?
    private var samples: [(time: TimeInterval, red: Double)] = []
    private var lastPeakTime: TimeInterval?
    private var validIntervals: [Double] = []
    private var recentBPM: [Int] = []
    private var lastUIUpdate = Date.distantPast
    private var completionHandler: ((DerivedMetrics, [Double]) -> Void)?
    private var failureHandler: ((String) -> Void)?

    private let config = RemoteConfig.heartRate
    private let calibrationDuration: TimeInterval = 3.0

    func configure(mode: MeasuringMode,
                   onComplete: @escaping (DerivedMetrics, [Double]) -> Void,
                   onFailure: @escaping (String) -> Void) {
        self.mode = mode
        self.completionHandler = onComplete
        self.failureHandler = onFailure
    }

    func start() {
        reset()
        running = true
        step = .calibrating
        phaseStart = Date()
        measureStart = nil
    }

    func stop() {
        running = false
        samples.removeAll()
    }

    func reset() {
        running = false
        step = .idle
        pulse = 0
        lastNN = 0
        progress = 0
        elapsed = 0
        waveform = []
        intervalCount = 0
        samples = []
        lastPeakTime = nil
        validIntervals = []
        recentBPM = []
        measureStart = nil
    }

    /// Called from the camera (or the simulator sensor) ~30 times per second.
    func ingest(red: Double, green: Double, blue: Double, at time: TimeInterval) {
        guard running else { return }
        let now = Date()
        if step == .calibrating {
            elapsed = now.timeIntervalSince(phaseStart)
            if elapsed >= calibrationDuration {
                step = .measuring
                measureStart = now
                phaseStart = now
                elapsed = 0
                samples.removeAll()
            }
            return
        }
        guard step == .measuring else { return }

        // Heart-rate threshold gate (§5.5, heartRateConfig defaults).
        guard red >= config.redMin, green <= config.greenMax, blue <= config.blueMax else { return }

        samples.append((time, red))
        if samples.count > 150 { samples.removeFirst(samples.count - 150) }
        waveform.append(red)
        if waveform.count > 120 { waveform.removeFirst(waveform.count - 120) }

        detectPeakIfNeeded()
        updateProgress(now: now)

        if now.timeIntervalSince(lastUIUpdate) > 0.12 {
            lastUIUpdate = now
            objectWillChange.send()
        }
    }

    func tick() {
        guard running else { return }
        let now = Date()
        if step == .calibrating {
            elapsed = now.timeIntervalSince(phaseStart)
            if elapsed >= calibrationDuration {
                step = .measuring
                measureStart = now
                phaseStart = now
                elapsed = 0
                samples.removeAll()
            }
        } else if step == .measuring {
            updateProgress(now: now)
        }
    }

    private func updateProgress(now: Date) {
        guard let measureStart else { return }
        elapsed = now.timeIntervalSince(measureStart)
        progress = clamp(elapsed / mode.duration, 0, 1)
        if elapsed >= mode.duration {
            finish()
        }
    }

    private func detectPeakIfNeeded() {
        guard samples.count >= 6 else { return }
        let n = samples.count
        let a = samples[n - 3].red
        let b = samples[n - 2].red
        let c = samples[n - 1].red
        guard b > a, b >= c else { return }

        let recent = samples.suffix(30).map(\.red)
        let mean = recent.reduce(0, +) / Double(recent.count)
        let variance = recent.reduce(0) { $0 + pow($1 - mean, 2) } / Double(recent.count)
        let deviation = sqrt(variance)
        guard b > mean + max(2.0, deviation * 0.35) else { return }

        let peakTime = samples[n - 2].time
        if let lastPeakTime {
            let intervalMs = (peakTime - lastPeakTime) * 1000
            // The peak time is updated even when the interval is invalid (§5.5).
            self.lastPeakTime = peakTime
            let average = validIntervals.isEmpty ? nil : validIntervals.suffix(6).reduce(0, +) / Double(min(validIntervals.count, 6))
            guard HRVCalculationService.validateInterval(intervalMs, recentAverageMs: average) else { return }
            validIntervals.append(intervalMs)
            intervalCount = validIntervals.count
            lastNN = Int(intervalMs.rounded())
            let window = validIntervals.suffix(5)
            pulse = Int((60000 / (window.reduce(0, +) / Double(window.count))).rounded())
            recentBPM.append(pulse)
        } else {
            self.lastPeakTime = peakTime
        }

        if validIntervals.count >= mode.minimumValidIntervals, elapsed >= mode.duration * 0.55 {
            finish()
        }
    }

    private func finish() {
        guard running else { return }
        running = false
        guard validIntervals.count >= 2 else {
            step = .failed("Not enough signal. Cover the camera and flash with your fingertip and try again.")
            failureHandler?("Not enough signal")
            return
        }
        let metrics = HRVCalculationService.calculate(intervals: validIntervals)
        pulse = Int(metrics.pulse)
        progress = 1
        step = .finished
        completionHandler?(metrics, validIntervals)
    }
}

// MARK: - Simulated PPG sensor (simulator / camera-less environments)

@MainActor
final class SimulatedSensor {
    private var timer: Timer?
    private var startTime = Date()
    private var beatTimes: [Double] = []
    private var nextBeatTime: Double = 0.4
    private var handler: ((Double, Double, Double, TimeInterval) -> Void)?
    private let baseBPM: Double = 74

    func start(handler: @escaping (Double, Double, Double, TimeInterval) -> Void) {
        self.handler = handler
        startTime = Date()
        beatTimes = []
        nextBeatTime = 0.4
        timer?.invalidate()
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.emit() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func emit() {
        let t = Date().timeIntervalSince(startTime)

        // Schedule heartbeats with realistic beat-to-beat and respiratory
        // variability so the derived HRV metrics are non-degenerate.
        while nextBeatTime < t + 0.5 {
            let respiratory = 0.028 * sin(2 * Double.pi * 0.11 * nextBeatTime)
            let beatJitter = Double.random(in: -0.055...0.055)
            let rr = 60.0 / baseBPM + respiratory + beatJitter
            beatTimes.append(nextBeatTime)
            nextBeatTime += max(0.6, rr)
        }
        beatTimes.removeAll { t - $0 > 2.0 }

        // PPG-like pulse train: a sharp systolic peak per beat.
        var pulse = 0.0
        for beat in beatTimes where t >= beat && t - beat < 0.5 {
            let dt = (t - beat) / 0.075
            pulse += exp(-dt * dt)
        }
        let drift = sin(2 * Double.pi * 0.20 * t) * 4
        let noise = Double.random(in: -2.0...2.0)
        let red = clamp(148 + pulse * 42 + drift + noise, 0, 255)
        let green = 38 + pulse * 3
        let blue = 30.0
        handler?(red, green, blue, t)
    }
}

// MARK: - Camera

@MainActor
final class CameraService: NSObject, ObservableObject {
    enum Status: Equatable {
        case unknown
        case denied
        case unavailable
        case ready
        case running
    }

    @Published private(set) var status: Status = .unknown

    var onSample: ((Double, Double, Double, TimeInterval) -> Void)?

    private let session = AVCaptureSession()

    var previewSession: AVCaptureSession { session }
    private let output = AVCaptureVideoDataOutput()
    private let frameQueue = DispatchQueue(label: "pro.heartica.camera.frames")
    private var position: AVCaptureDevice.Position = .back
    private var wantsTorch = false

    func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted
        default:
            return false
        }
    }

    func start(position: AVCaptureDevice.Position, torch: Bool) {
        self.position = position
        self.wantsTorch = torch
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            status = .denied
            return
        }
        #if targetEnvironment(simulator)
        status = .unavailable
        return
        #else
        configureSession()
        #endif
    }

    func stop() {
        frameQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
        setTorch(false)
        status = .unknown
    }

    #if !targetEnvironment(simulator)
    private func configureSession() {
        frameQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .medium
            self.session.inputs.forEach { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.position),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input) else {
                Task { @MainActor in self.status = .unavailable }
                self.session.commitConfiguration()
                return
            }
            self.session.addInput(input)

            self.output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            self.output.alwaysDiscardsLateVideoFrames = true
            self.output.setSampleBufferDelegate(self, queue: self.frameQueue)
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }
            self.session.commitConfiguration()
            if self.wantsTorch { self.setTorch(true) }
            self.session.startRunning()
            Task { @MainActor in self.status = .running }
        }
    }
    #endif

    private func setTorch(_ enabled: Bool) {
        #if !targetEnvironment(simulator)
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              device.hasTorch else { return }
        try? device.lockForConfiguration()
        if enabled, device.isTorchAvailable {
            try? device.setTorchModeOn(level: 1.0)
        } else {
            device.torchMode = .off
        }
        device.unlockForConfiguration()
        #endif
    }
}

#if !targetEnvironment(simulator)
extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let bytes = base.assumingMemoryBound(to: UInt8.self)

        let roiSize = min(width, height) / 6
        let startX = width / 2 - roiSize / 2
        let startY = height / 2 - roiSize / 2
        var sumR = 0.0, sumG = 0.0, sumB = 0.0
        var count = 0.0
        for y in stride(from: startY, to: startY + roiSize, by: 2) {
            for x in stride(from: startX, to: startX + roiSize, by: 2) {
                let offset = y * bytesPerRow + x * 4
                sumB += Double(bytes[offset])
                sumG += Double(bytes[offset + 1])
                sumR += Double(bytes[offset + 2])
                count += 1
            }
        }
        guard count > 0 else { return }
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        let result = (sumR / count, sumG / count, sumB / count, time)
        DispatchQueue.main.async { [weak self] in
            self?.onSample?(result.0, result.1, result.2, result.3)
        }
    }
}
#endif
