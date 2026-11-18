import Foundation

// MARK: - App language

enum AppLanguage: String, CaseIterable, Identifiable {
    case chinese
    case english
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chinese: return "简体中文"
        case .english: return "English"
        case .system: return "跟随系统"
        }
    }

    var locale: Locale? {
        switch self {
        case .chinese: return Locale(identifier: "zh-Hans")
        case .english: return Locale(identifier: "en")
        case .system: return nil
        }
    }
}

final class LanguageStore: ObservableObject {
    static let shared = LanguageStore()
    private static let key = "settings.appLanguage"

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.key)
        }
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.key)
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            language = .english
        } else if let override = ProcessInfo.processInfo.environment["HEARTICA_LANG"],
                  let value = AppLanguage(rawValue: override) {
            language = value
        } else {
            language = stored.flatMap(AppLanguage.init(rawValue:)) ?? .chinese
        }
    }

    /// Chinese is the default presentation language; "system" follows the device.
    var effective: AppLanguage {
        if language == .system {
            let identifier = Locale.current.language.languageCode?.identifier ?? "en"
            return identifier == "zh" ? .chinese : .english
        }
        return language
    }

    var effectiveLocale: Locale {
        switch effective {
        case .chinese: return Locale(identifier: "zh-Hans")
        case .english: return Locale(identifier: "en")
        case .system: return Locale.current
        }
    }

    private lazy var chineseBundle: Bundle? = {
        guard let path = Bundle.main.path(forResource: "zh-Hans", ofType: "lproj") else {
            return nil
        }
        return Bundle(path: path)
    }()

    func string(_ key: String) -> String {
        guard effective == .chinese, let chineseBundle else { return key }
        return chineseBundle.localizedString(forKey: key, value: key, table: nil)
    }
}

/// Localizes a dynamic string (model titles, statuses, copy) into the selected language.
func L(_ key: String) -> String {
    LanguageStore.shared.string(key)
}

/// Localized format with arguments, e.g. LF("Level %d", 3).
func LF(_ format: String, _ arguments: CVarArg...) -> String {
    String(format: L(format), arguments: arguments)
}
