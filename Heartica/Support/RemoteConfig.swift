import Foundation

/// Local fallbacks for the remote configuration described in report §2.4.
/// The app is fully functional offline with these values.
enum RemoteConfig {
    struct HeartRateConfig {
        var redMin: Double = 25
        var greenMax: Double = 75
        var blueMax: Double = 50
        var isRedDiffEnabled: Bool = true
        var redDiffValue: Double = 50
        var stability: Double = 50
    }

    struct MeasuringModeConfig {
        var afterOnboarding: MeasuringMode = .standard
        var `default`: MeasuringMode = .fast
    }

    static let heartRate = HeartRateConfig()
    static let measuringMode = MeasuringModeConfig()
    static let frontCameraEnabled = true

    static let homeCarouselPages = ["heart_rate", "csi", "heart_age", "promo_banner"]
    static let homeCarouselDuration: TimeInterval = 7

    static let availableProducts: [String] = [
        "weekly.01", "weekly.02", "weekly.03", "weekly.05", "weekly.06",
        "yearly.01", "yearly.02", "yearly.03"
    ]

    static let defaultChartType = ChartType.bar
    static let defaultShowTrendLine = true
    static let defaultShowThresholds = false
    static let defaultTimeRange = ChartTimeRange.week
}

enum ChartType: String, CaseIterable, Identifiable {
    case bar, line
    var id: String { rawValue }
    var title: String { L(rawValue.capitalized) }
}

enum ChartTimeRange: String, CaseIterable, Identifiable {
    case day, week, month, threeMonths, year
    var id: String { rawValue }
    var title: String {
        switch self {
        case .day: return L("Day")
        case .week: return L("Week")
        case .month: return L("Month")
        case .threeMonths: return L("3 Months")
        case .year: return L("Year")
        }
    }
    var days: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        }
    }
    var shortTitle: String {
        switch self {
        case .day: return "1D"
        case .week: return "7D"
        case .month: return "30D"
        case .threeMonths: return "3M"
        case .year: return "1Y"
        }
    }
}

@MainActor
final class ChartSettingsStore: ObservableObject {
    static let shared = ChartSettingsStore()
    @Published var settings: ChartSettings

    private init() {
        settings = ChartSettings.load()
    }

    func save() {
        settings.save()
        objectWillChange.send()
    }

    func reset() {
        settings = ChartSettings()
        settings.save()
        objectWillChange.send()
    }
}

struct ChartSettings {
    var timeRange: ChartTimeRange = RemoteConfig.defaultTimeRange
    var showTrendLine: Bool = RemoteConfig.defaultShowTrendLine
    var showThresholds: Bool = RemoteConfig.defaultShowThresholds
    var chartType: ChartType = RemoteConfig.defaultChartType

    static func load() -> ChartSettings {
        let defaults = UserDefaults.standard
        var settings = ChartSettings()
        if let raw = defaults.string(forKey: UDKey.graphTimeRange),
           let range = ChartTimeRange(rawValue: raw) {
            settings.timeRange = range
        }
        if defaults.object(forKey: UDKey.graphShowTrendLine) != nil {
            settings.showTrendLine = defaults.bool(forKey: UDKey.graphShowTrendLine)
        }
        if defaults.object(forKey: UDKey.graphShowThresholds) != nil {
            settings.showThresholds = defaults.bool(forKey: UDKey.graphShowThresholds)
        }
        if let raw = defaults.string(forKey: UDKey.graphChartType),
           let type = ChartType(rawValue: raw) {
            settings.chartType = type
        }
        return settings
    }

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(timeRange.rawValue, forKey: UDKey.graphTimeRange)
        defaults.set(showTrendLine, forKey: UDKey.graphShowTrendLine)
        defaults.set(showThresholds, forKey: UDKey.graphShowThresholds)
        defaults.set(chartType.rawValue, forKey: UDKey.graphChartType)
    }
}
