import Foundation

/// Values produced from a set of NN intervals (milliseconds). Field order mirrors
/// the domain model in report §7.2.
struct DerivedMetrics: Equatable {
    var pulse: Double
    var sdnn: Double
    var rmssd: Double
    var pnn50: Double
    var stress: Double
    var energy: Double
    var healthIndex: Double
    var csi: Double

    init(pulse: Double = 0, sdnn: Double = 0, rmssd: Double = 0, pnn50: Double = 0,
         stress: Double = 0, energy: Double = 0, healthIndex: Double = 0, csi: Double = 0) {
        self.pulse = pulse
        self.sdnn = sdnn
        self.rmssd = rmssd
        self.pnn50 = pnn50
        self.stress = stress
        self.energy = energy
        self.healthIndex = healthIndex
        self.csi = csi
    }
}

/// HRV calculation service. Formulas for pulse / SDNN / RMSSD / pNN50 are the
/// exact pseudocode recovered from the binary (§7.2). The stress / energy /
/// health-index conversions are not recoverable from the binary; a documented
/// linear mapping over the same 0–100 / 0–120 / 0–10 ranges is used.
enum HRVCalculationService {

    /// IQR outlier removal (§5.6: "calculateMeasurementResults(intervals:) … IQR method").
    static func filteredIntervals(_ intervals: [Double]) -> [Double] {
        let sorted = intervals.sorted()
        guard sorted.count >= 4 else { return intervals }
        func percentile(_ p: Double) -> Double {
            let rank = p / 100 * Double(sorted.count - 1)
            let lower = Int(rank.rounded(.down))
            let upper = Int(rank.rounded(.up))
            if lower == upper { return sorted[lower] }
            let weight = rank - Double(lower)
            return sorted[lower] * (1 - weight) + sorted[upper] * weight
        }
        let q1 = percentile(25)
        let q3 = percentile(75)
        let iqr = q3 - q1
        let lowerFence = q1 - 1.5 * iqr
        let upperFence = q3 + 1.5 * iqr
        let filtered = intervals.filter { $0 >= lowerFence && $0 <= upperFence }
        return filtered.count >= 2 ? filtered : intervals
    }

    static func calculate(intervals rawIntervals: [Double]) -> DerivedMetrics {
        let intervals = filteredIntervals(rawIntervals.filter { $0 > 0 })
        guard !intervals.isEmpty else { return DerivedMetrics() }
        let n = Double(intervals.count)
        let sum = intervals.reduce(0, +)
        let mean = sum / n

        // pulse = Int(60000 / mean)
        let pulse = mean > 0 ? Double(Int(60000.0 / mean)) : 0

        // SDNN: population standard deviation
        let variance = intervals.reduce(0) { $0 + pow($1 - mean, 2) } / n
        let sdnn = sqrt(variance)

        // Adjacent differences
        var diffs: [Double] = []
        for index in 1..<intervals.count {
            diffs.append(intervals[index] - intervals[index - 1])
        }

        // RMSSD = sqrt(ΣΔNN² / (n−1))
        var rmssd = 0.0
        if intervals.count >= 2 {
            let squared = diffs.reduce(0) { $0 + $1 * $1 }
            rmssd = sqrt(squared / Double(diffs.count))
        }

        // pNN50 = count(|ΔNN| > 50) / (n−1) * 100
        var pnn50 = 0.0
        if !diffs.isEmpty {
            let count = diffs.filter { abs($0) > 50 }.count
            pnn50 = Double(count) / Double(diffs.count) * 100
        }

        // Documented implementer mapping (the binary only confirms ranges):
        // variability is the common driver so the four derived values stay
        // mutually consistent. Low variability -> high stress, low energy and
        // a low health index.
        let normalized = clamp(sdnn / 100.0, 0, 1)
        let energy = clamp(normalized * 120.0, 0, 120)
        let stress = clamp((1.0 - normalized) * 100.0, 0, 100)
        let healthIndex = clamp(normalized * 10.0, 0, 10)
        let csi = clamp(6000.0 / max(sdnn, 10), 20, 900)

        return DerivedMetrics(pulse: pulse,
                              sdnn: (sdnn * 10).rounded() / 10,
                              rmssd: (rmssd * 10).rounded() / 10,
                              pnn50: (pnn50 * 10).rounded() / 10,
                              stress: stress.rounded(),
                              energy: energy.rounded(),
                              healthIndex: (healthIndex * 10).rounded() / 10,
                              csi: csi.rounded())
    }

    // MARK: - Individual validators used by the measuring pipeline

    /// Initial absolute NN bounds (ms adapt to seconds). Recovered semantics only;
    /// exact constants are unknown (§5.10).
    static func validateInterval(_ intervalMs: Double,
                                 recentAverageMs: Double?) -> Bool {
        let initialLower = 300.0
        let initialUpper = 2000.0
        guard intervalMs >= initialLower, intervalMs <= initialUpper else { return false }
        guard let average = recentAverageMs, average > 0 else { return true }
        let dynamicLower = average * 0.65
        let dynamicUpper = average * 1.35
        return intervalMs >= dynamicLower && intervalMs <= dynamicUpper
    }
}
