import Foundation
import HealthKit
import SwiftUI

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    @Published var connected: Bool
    @Published var lastSync: Date?
    @Published var sampleCount: Int?
    @Published var errorMessage: String?
    @Published var isWorking = false

    private let store = HKHealthStore()
    private var defaults: UserDefaults { .standard }

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) { types.insert(heartRate) }
        if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { types.insert(hrv) }
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) { types.insert(steps) }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        types.insert(HKObjectType.workoutType())
        return types
    }

    init() {
        connected = UserDefaults.standard.bool(forKey: "appleHealth.connected")
        lastSync = UserDefaults.standard.object(forKey: UDKey.healthKitLastSync) as? Date
    }

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func connect() async {
        guard isAvailable else {
            errorMessage = "Apple Health is not available on this device."
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            connected = true
            defaults.set(true, forKey: "appleHealth.connected")
            defaults.set(true, forKey: UDKey.healthKitReadShown)
        } catch {
            errorMessage = error.localizedDescription
            connected = false
        }
    }

    func disconnect() {
        connected = false
        defaults.set(false, forKey: "appleHealth.connected")
    }

    /// Reads recent Apple Health heart-rate samples and reports how many are new.
    /// Importing full HealthKit history is intentionally out of scope for this build;
    /// only connection state and sync metadata are persisted.
    func sync() async {
        guard connected else { return }
        guard isAvailable else {
            errorMessage = "Apple Health is not available on this device."
            return
        }
        isWorking = true
        defer { isWorking = false }
        let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
                                                    end: Date())
        let samples: [HKSample] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: heartRate,
                                      predicate: predicate,
                                      limit: 500,
                                      sortDescriptors: nil) { _, samples, error in
                if let error { self.errorMessage = error.localizedDescription }
                continuation.resume(returning: samples ?? [])
            }
            store.execute(query)
        }
        sampleCount = samples.count
        lastSync = Date()
        defaults.set(lastSync, forKey: UDKey.healthKitLastSync)
    }
}

struct AppleHealthView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var health = HealthKitService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack(spacing: 14) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 26))
                        .foregroundColor(AppColor.brand)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(AppColor.brandSoft))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Apple Health Sync")
                            .font(.system(size: 18, weight: .bold))
                        Text(health.connected ? "Connected" : "Not connected")
                            .font(.system(size: 12))
                            .foregroundColor(health.connected ? AppColor.success : AppColor.textSecondary)
                    }
                    Spacer()
                }
                .card()

                VStack(alignment: .leading, spacing: 8) {
                    Text("About Apple Health")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Heartica can read heart rate, HRV, sleep and activity data from Apple Health to enrich your insights. We only access the data needed to provide your health insights.")
                        .font(.system(size: 13))
                        .foregroundColor(AppColor.textSecondary)
                        .lineSpacing(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()

                if let lastSync = health.lastSync {
                    Text("Last sync: \(Fmt.date(lastSync, format: "MMM d, yyyy · h:mm a"))")
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.textSecondary)
                }
                if let count = health.sampleCount {
                    Text("\(count) heart-rate samples available in the last 7 days")
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.textSecondary)
                }
                if let error = health.errorMessage {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.danger)
                        .multilineTextAlignment(.center)
                }

                if health.connected {
                    Button {
                        Task { await health.sync() }
                    } label: {
                        if health.isWorking {
                            ProgressView().tint(.white)
                        } else {
                            Text("Sync Now")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    Button("Disconnect") { health.disconnect() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColor.danger)
                } else {
                    Button {
                        Task { await health.connect() }
                    } label: {
                        if health.isWorking {
                            ProgressView().tint(.white)
                        } else {
                            Text("Connect Apple Health")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!health.isAvailable)
                }

                Text("This build connects to HealthKit for authorization and sample preview. Importing historical HealthKit records into the app's own trend charts is not included.")
                    .font(.system(size: 11))
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(18)
        }
        .screenBackground()
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
    }
}
