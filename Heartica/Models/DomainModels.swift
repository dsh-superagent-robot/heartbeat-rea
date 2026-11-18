import Foundation

// MARK: - Domain models (decoupled from Core Data)

enum MeasurementKind: String {
    case camera
    case manual
}

struct HRMeasurement: Identifiable, Equatable {
    let id: String
    var time: Date
    var kind: MeasurementKind
    var tagId: String?
    var createdAt: Date
    var pulse: Double
    var hrv: Double
    var rmssd: Double
    var sdnn: Double
    var pnn50: Double
    var stress: Double
    var energy: Double
    var healthIndex: Double
    var csi: Double
    var source: String
}

struct PressureRecord: Identifiable, Equatable {
    let id: String
    var tagId: String?
    var sys: Int
    var dia: Int
    var createdAt: Date
}

struct OxygenRecord: Identifiable, Equatable {
    let id: String
    var tagId: String?
    var value: Int
    var createdAt: Date
}

struct GlucoseRecord: Identifiable, Equatable {
    let id: String
    var tagId: String?
    var value: Double
    var createdAt: Date
}

struct CustomTag: Identifiable, Equatable {
    let id: String
    var name: String
    var colorName: String
    var cluster: String
    var createdAt: String
}

struct Reminder: Identifiable, Equatable {
    let id: String
    var time: Date
    var type: String
}

// MARK: - Preset tag catalog (§9.2, §9.3)

struct TagCategory: Identifiable, Equatable {
    let id: Int
    let title: String
    var identifier: String {
        switch id {
        case 0: return "sleep"
        case 1: return "activity"
        case 2: return "stress"
        case 3: return "relax"
        default: return "eating"
        }
    }

    static let all: [TagCategory] = [
        TagCategory(id: 0, title: "Sleep"),
        TagCategory(id: 1, title: "Activity"),
        TagCategory(id: 2, title: "Stress"),
        TagCategory(id: 3, title: "Mindfulness"),
        TagCategory(id: 4, title: "Eating")
    ]

    var displayTitle: String { L(title) }
}

struct PresetTag: Identifiable, Equatable {
    let id: String
    let title: String

    var displayTitle: String { L(title) }
    let colorName: String
    let categoryID: Int
    let cluster: String

    static let all: [PresetTag] = [
        PresetTag(id: "sleep-before", title: "Before Sleep", colorName: "blue", categoryID: 0, cluster: "rest"),
        PresetTag(id: "sleep-after", title: "After Sleep", colorName: "blue", categoryID: 0, cluster: "rest"),
        PresetTag(id: "activity-before", title: "Before Exercise", colorName: "green", categoryID: 1, cluster: "readiness"),
        PresetTag(id: "activity-after", title: "After Exercise", colorName: "green", categoryID: 1, cluster: "stress"),
        PresetTag(id: "stress-before", title: "Before Stress", colorName: "purple", categoryID: 2, cluster: "stress"),
        PresetTag(id: "stress-during", title: "During Stress", colorName: "purple", categoryID: 2, cluster: "stress"),
        PresetTag(id: "stress-after", title: "After Stress", colorName: "purple", categoryID: 2, cluster: "stress"),
        PresetTag(id: "relax-before", title: "Before Meditation", colorName: "teal", categoryID: 3, cluster: "readiness"),
        PresetTag(id: "relax-after", title: "After Meditation", colorName: "teal", categoryID: 3, cluster: "rest"),
        PresetTag(id: "eating-before", title: "Before Meal", colorName: "red", categoryID: 4, cluster: "readiness"),
        PresetTag(id: "eating-after", title: "After Meal", colorName: "orange", categoryID: 4, cluster: "food")
    ]
}

struct TagCluster: Identifiable, Equatable {
    let id: String
    let title: String
    let shortDescription: String
    let longDescription: String

    var displayTitle: String { L(title) }
    var displayShort: String { L(shortDescription) }
    var displayLong: String { L(longDescription) }

    static let all: [TagCluster] = [
        TagCluster(id: "rest", title: "Rest & Recovery",
                   shortDescription: "Track how rest and recovery affect your heart.",
                   longDescription: "Rest & Recovery clusters measurements taken before sleep, after sleep and after meditation."),
        TagCluster(id: "stress", title: "Load & Stress",
                   shortDescription: "Understand your body's response to load and stress.",
                   longDescription: "Load & Stress clusters measurements taken after exercise and around stressful moments."),
        TagCluster(id: "readiness", title: "Readiness",
                   shortDescription: "See how prepared your body is for the day.",
                   longDescription: "Readiness clusters measurements taken before exercise, before meditation, before stress and before meals."),
        TagCluster(id: "food", title: "Food Impact",
                   shortDescription: "Learn how meals influence your heart rate.",
                   longDescription: "Food Impact clusters measurements taken after meals.")
    ]

    static func titled(_ id: String) -> TagCluster? { all.first { $0.id == id } }
}

// MARK: - All tag lookup helpers

@MainActor
struct TagResolver {
    static func title(for id: String?) -> String? {
        guard let id else { return nil }
        if let preset = PresetTag.all.first(where: { $0.id == id }) { return preset.displayTitle }
        if let custom = HealthDataStore.shared.customTags().first(where: { $0.id == id }) { return custom.name }
        return nil
    }

    static func colorName(for id: String?) -> String? {
        guard let id else { return nil }
        if let preset = PresetTag.all.first(where: { $0.id == id }) { return preset.colorName }
        if let custom = HealthDataStore.shared.customTags().first(where: { $0.id == id }) { return custom.colorName }
        return nil
    }
}

// MARK: - Status bands (§7.3)

struct MetricStatus {
    let status: String
    let indicator: String
    let color: String
    let range: String

    var displayStatus: String {
        switch status {
        case "veryHigh": return L("Very High")
        case "veryLow": return L("Very Low")
        case "very_low": return L("Very Low")
        case "high": return L("High")
        case "low": return L("Low")
        case "normal": return L("Normal")
        case "elevated": return L("Elevated")
        case "average": return L("Average")
        case "excellent": return L("Excellent")
        case "good": return L("Good")
        case "athlete": return L("Athlete")
        case "reduced": return L("Reduced")
        case "relaxed": return L("Relaxed")
        default: return status.capitalized
        }
    }
}

enum MetricCatalog {
    static func pulseStatus(_ value: Double) -> MetricStatus {
        switch value {
        case 120...: return MetricStatus(status: "veryHigh", indicator: L("Severe Tachycardia"), color: "red", range: "120+ bpm")
        case 100..<120: return MetricStatus(status: "high", indicator: L("Mild Tachycardia"), color: "orange", range: "100–120 bpm")
        case 60..<100: return MetricStatus(status: "normal", indicator: L("Normal Heart Rate"), color: "green", range: "60–100 bpm")
        default: return MetricStatus(status: "low", indicator: L("Bradycardia"), color: "blue", range: "<60 bpm")
        }
    }

    static func hrvStatus(_ value: Double) -> MetricStatus {
        switch value {
        case 100...: return MetricStatus(status: "high", indicator: L("Excellent variability"), color: "green", range: "≥100 ms")
        case 50..<100: return MetricStatus(status: "normal", indicator: L("Moderate stress"), color: "green", range: "50–100 ms")
        default: return MetricStatus(status: "low", indicator: L("Possible chronic stress"), color: "yellow", range: "<50 ms")
        }
    }

    static func rmssdStatus(_ value: Double) -> MetricStatus {
        switch value {
        case 80...: return MetricStatus(status: "excellent", indicator: L("Elite athlete"), color: "green", range: "≥80 ms")
        case 50..<80: return MetricStatus(status: "good", indicator: L("Well-trained individual"), color: "green", range: "50–80 ms")
        case 30..<50: return MetricStatus(status: "average", indicator: L("Balanced state"), color: "yellow", range: "30–50 ms")
        case 20..<30: return MetricStatus(status: "low", indicator: L("Possible chronic stress"), color: "orange", range: "20–30 ms")
        default: return MetricStatus(status: "veryLow", indicator: L("High stress"), color: "red", range: "<20 ms")
        }
    }

    static func pnn50Status(_ value: Double) -> MetricStatus {
        switch value {
        case 30...: return MetricStatus(status: "excellent", indicator: L("Good stress recovery"), color: "green", range: "≥30%")
        case 20..<30: return MetricStatus(status: "normal", indicator: L("Healthy level"), color: "green", range: "20–30%")
        case 10..<20: return MetricStatus(status: "reduced", indicator: L("Possible mild stress"), color: "yellow", range: "10–20%")
        default: return MetricStatus(status: "low", indicator: L("Chronic stress"), color: "orange", range: "<10%")
        }
    }

    static func stressStatus(_ value: Double) -> MetricStatus {
        let v = Int(value.rounded())
        switch v {
        case 80...: return MetricStatus(status: "veryHigh", indicator: L("Highly tense"), color: "red", range: "80–100")
        case 70..<80: return MetricStatus(status: "high", indicator: L("Slightly tense"), color: "orange", range: "70–80")
        case 35..<70: return MetricStatus(status: "average", indicator: L("Mildly calm"), color: "yellow", range: "35–70")
        case 25..<35: return MetricStatus(status: "low", indicator: L("Quite relaxed"), color: "green", range: "25–35")
        default: return MetricStatus(status: "relaxed", indicator: L("Deeply relaxed"), color: "blue", range: "0–25")
        }
    }

    static func energyStatus(_ value: Double) -> MetricStatus {
        switch value {
        case 100...: return MetricStatus(status: "excellent", indicator: L("Strong recovery"), color: "green", range: "100–120")
        case 80..<100: return MetricStatus(status: "good", indicator: L("Balanced state"), color: "yellow", range: "80–100")
        case 60..<80: return MetricStatus(status: "average", indicator: L("Increased stress"), color: "orange", range: "60–80")
        default: return MetricStatus(status: "low", indicator: L("High stress"), color: "red", range: "0–60")
        }
    }

    static func healthIndexStatus(_ value: Double) -> MetricStatus {
        switch value {
        case 6.5...: return MetricStatus(status: "athlete", indicator: L("Strong recovery"), color: "green", range: "6.5+")
        case 5.5..<6.5: return MetricStatus(status: "excellent", indicator: L("Optimal recovery"), color: "green", range: "5.5–6.5")
        case 4.5..<5.5: return MetricStatus(status: "good", indicator: L("Normal recovery"), color: "yellow", range: "4.5–5.5")
        case 3.5..<4.5: return MetricStatus(status: "average", indicator: L("Moderate stress"), color: "orange", range: "3.5–4.5")
        default: return MetricStatus(status: "low", indicator: L("High stress"), color: "red", range: "<3.5")
        }
    }

    static func csiStatus(_ value: Double) -> (title: String, color: String) {
        switch value {
        case ..<50: return (L("Low stress"), "green")
        case 50..<150: return (L("Normal"), "green")
        case 150..<300: return (L("Moderate stress"), "yellow")
        case 300..<500: return (L("High stress"), "orange")
        default: return (L("Very High"), "red")
        }
    }
}

extension Double {
    var cleanInt: Int { Int(rounded()) }
}

func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
    min(max(value, lower), upper)
}
