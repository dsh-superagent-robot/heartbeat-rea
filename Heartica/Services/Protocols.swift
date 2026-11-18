import Foundation

// MARK: - Chronic Stress Index (7-day protocol, §16)

@MainActor
final class CSIService {
    static let shared = CSIService()

    struct Progress {
        var started: Bool
        var day: Int
        var completed: Bool
        var result: Int?
        var hasMeasurementToday: Bool
    }

    private var defaults: UserDefaults { .standard }

    var startDate: Date? {
        defaults.object(forKey: UDKey.csiStartDate) as? Date
    }

    func beginProtocolIfNeeded() {
        if startDate == nil {
            defaults.set(Date(), forKey: UDKey.csiStartDate)
        }
    }

    private var measurements: [HRMeasurement] {
        let all = HealthDataStore.shared.measurements()
        guard let startDate else { return all }
        return all.filter { $0.time >= startDate }
    }

    private var uniqueDays: [Date] {
        let calendar = Calendar.current
        var seen: Set<Date> = []
        var days: [Date] = []
        for measurement in measurements.sorted(by: { $0.time < $1.time }) {
            let day = calendar.startOfDay(for: measurement.time)
            if !seen.contains(day) {
                seen.insert(day)
                days.append(day)
            }
        }
        return days
    }

    var result: Int? {
        let days = uniqueDays
        guard days.count >= 7 else { return nil }
        let windowStart = days[days.count - 7]
        let window = measurements.filter { $0.time >= windowStart }
        guard !window.isEmpty else { return nil }
        let sum = window.reduce(0) { $0 + $1.csi }
        return Int((sum / Double(window.count)).rounded())
    }

    var progress: Progress {
        let days = uniqueDays
        let hasToday = measurements.contains { Calendar.current.isDateInToday($0.time) }
        return Progress(started: !measurements.isEmpty,
                        day: min(days.count, 7),
                        completed: days.count >= 7,
                        result: result,
                        hasMeasurementToday: hasToday)
    }

    var weeklyAverage: [Int] {
        let calendar = Calendar.current
        let days = uniqueDays
        guard days.count >= 7 else { return [] }
        return measurements.suffix(30).map { _ in 0 }.isEmpty ? [] : stride(from: 0, to: 7, by: 1).compactMap { offset in
            let index = days.count - 7 + offset
            guard index >= 0, index < days.count else { return nil }
            let day = days[index]
            let dayMeasurements = measurements.filter { calendar.isDate($0.time, inSameDayAs: day) }
            guard !dayMeasurements.isEmpty else { return nil }
            return dayMeasurements.reduce(0) { $0 + Int($1.csi) } / dayMeasurements.count
        }
    }

    func startOver() {
        defaults.set(Date(), forKey: UDKey.csiStartDate)
    }

    func markReminderSeen() {
        defaults.set(false, forKey: UDKey.csiReminderDot)
    }
}

// MARK: - Heart Age (3-measurement protocol, §17)

@MainActor
final class HeartAgeService {
    static let shared = HeartAgeService()

    struct Progress {
        var count: Int
        var started: Bool
        var hasMeasurementToday: Bool
    }

    private var defaults: UserDefaults { .standard }

    var startDate: Date? {
        defaults.object(forKey: UDKey.heartAgeStartDate) as? Date
    }

    func beginProtocolIfNeeded() {
        if startDate == nil {
            defaults.set(Date(), forKey: UDKey.heartAgeStartDate)
        }
    }

    private var measurements: [HRMeasurement] {
        var all = HealthDataStore.shared.measurements().filter { $0.rmssd > 0 }
        if let startDate { all = all.filter { $0.time >= startDate } }
        return Array(all.prefix(3))
    }

    private var profile: Profile { ProfileStore.load() }

    var hasRequiredProfile: Bool {
        profile.age != nil && profile.gender != .notSet
    }

    var result: Int? {
        guard hasRequiredProfile, let age = profile.age else { return nil }
        let window = measurements
        guard window.count >= 3 else { return nil }
        let gender = profile.gender
        let ageBucket = HeartAgeCalculator.ageBucket(age)
        var sum = 0
        for measurement in window {
            let bucket = HeartAgeCalculator.rmssdBucket(measurement.rmssd, gender: gender)
            let bounded = HeartAgeCalculator.clampBucket(bucket, ageBucket: ageBucket)
            sum += HeartAgeCalculator.ageTable[bounded]
        }
        return Int((Double(sum) / Double(window.count)).rounded())
    }

    var progress: Progress {
        let hasToday = measurements.contains { Calendar.current.isDateInToday($0.time) }
        return Progress(count: measurements.count,
                        started: !measurements.isEmpty,
                        hasMeasurementToday: hasToday)
    }

    var status: (title: String, color: String, interpretation: String)? {
        guard let result, let age = profile.age else { return nil }
        let diff = result - age
        if abs(diff) <= 6 {
            return (L("Equal"), "yellow", L("Heart age matches your biological age"))
        } else if diff >= 7 {
            return (L("High"), "red", L("Heart age is above your biological age"))
        } else {
            return (L("Good"), "green", L("Heart age is below your biological age"))
        }
    }

    var averagePrevious: Int? {
        guard measurements.count >= 3 else { return nil }
        let avg = measurements.map(\.rmssd).reduce(0, +) / Double(measurements.count)
        return Int(avg.rounded())
    }

    func startOver() {
        defaults.set(Date(), forKey: UDKey.heartAgeStartDate)
        defaults.removeObject(forKey: UDKey.lastHeartAgeCalculated)
    }
}

enum HeartAgeCalculator {
    static let ageTable = [10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70]

    static let femaleThresholds: [Double] = [
        100.0, 80.1, 70.1, 60.1, 55.1, 50.1, 45.1, 40.1, 33.76, 27.6, 21.26, 15.0
    ]

    static let maleThresholds: [Double] = [
        91.0, 90.1, 80.1, 70.1, 63.76, 57.6, 51.26, 45.1, 38.76, 32.6, 26.26, 20.0
    ]

    static func rmssdBucket(_ rmssd: Double, gender: Gender) -> Int {
        let thresholds = gender == .female ? femaleThresholds : maleThresholds
        for (index, threshold) in thresholds.enumerated() where rmssd >= threshold {
            return index
        }
        return 12
    }

    static func ageBucket(_ age: Int) -> Int {
        if age < 15 { return 0 }
        if age >= 70 { return 12 }
        return min(12, max(0, (age - 10) / 5))
    }

    static func clampBucket(_ bucket: Int, ageBucket: Int) -> Int {
        min(12, max(max(0, ageBucket - 3), min(bucket, min(12, ageBucket + 3))))
    }
}
