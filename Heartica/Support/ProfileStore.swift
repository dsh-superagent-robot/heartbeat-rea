import Foundation
import SwiftUI

// MARK: - Persisted keys (mirrors the analytical report §2.2 / §2.3)

enum UDKey {
    static let isOnboardingPassed = "isOnboardingPassed"
    static let isPostOnboardingPassed = "isPostOnboardingPassed"
    static let needToShowPostOb = "needToShowPostOb"
    static let didPurchasedApp = "didPurchasedApp"

    static let appearance = "settings.appearance"
    static let whatsNewLastSeenVersion = "whatsNew.lastSeenVersion"

    static let achievementStartDate = "achievement.start.progress.date"
    static let csiStartDate = "CSIService.startDate"
    static let csiReminderDot = "CSIReminderDotVisible"
    static let heartAgeStartDate = "HeartAgeService.startDate"
    static let heartAgeReminderDot = "HeartAgeReminderDotVisible"
    static let lastHeartAgeShown = "last_heartage_shown"
    static let lastHeartAgeCalculated = "last_heartage_calculated"

    static let healthKitLastSync = "health.kit.last.sync.date"
    static let healthKitReadShown = "HealthKitPermissions.read.request.shown"

    static let notificationAuthStatus = "notification_auth_status"
    static let notificationsEnable = "UserNotificationPermissonStorage.notificationsEnable"
    static let systemNotificationsEnable = "UserNotificationPermissonStorage.systemNotificationsEnable"
    static let notificationsRequestShown = "UserNotificationPermissonStorage.requestShown"

    static let glucoseUnit = "selected_glucose_unit"
    static let lastGlucoseBeforeMeal = "last_glucose_before_meal"
    static let lastGlucoseAfterMeal = "last_glucose_after_meal"
    static let didPresentInitialSetReminder = "didPresentInitialSetReminder"

    static let rateShowedDate = "RateService.showedDate"
    static let rateCounters = "RateService.Counters"
    static let noSubOfferFirstPaywall = "NoSubOffer.firstPaywallShown"
    static let noSubOfferFeedbackSent = "NoSubOffer.feedbackSent"
    static let cancelSurveyActivationDate = "CancelSurvey.activationDate"
    static let cancelSurveyFeedbackSent = "CancelSurvey.feedbackSent"
    static let hardPaywallActivationDate = "HardPaywall.activationDate"

    static let graphPulseDot = "graphSettingsPulseDotVisibleKey"
    static let meInfoPulseDot = "meInfoPulseDotVisibleKey"
    static let measuringMode = "measuringModeKey"
    static let useFrontCamera = "useFrontCameraKey"

    static let graphTimeRange = "graph.settings.default.time.range"
    static let graphShowTrendLine = "graph.settings.default.show.trend.line"
    static let graphShowThresholds = "graph.settings.default.show.thresholds"
    static let graphChartType = "graph.settings.default.chart.type"

    // Profile storage keys (§2.2)
    static let name = "name"
    static let surname = "surname"
    static let age = "age"
    static let photo = "photo"
    static let gender = "gender"
    static let weight = "weight"
    static let height = "height"

    // Tutorial one-shot hints
    static let hintBasicShown = "tutorial.hintBasic.shown"
    static let hintFrontCameraShown = "tutorial.hintFrontCamera.shown"
    static let hintTwoHandsShown = "tutorial.hintTwoHands.shown"
}

// MARK: - Profile

enum Gender: Int, CaseIterable, Identifiable {
    case female = 0
    case male = 1
    case notSet = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .female: return "Female"
        case .male: return "Male"
        case .notSet: return "Not Set"
        }
    }
}

struct Profile {
    var name: String = ""
    var surname: String = ""
    var age: Int?
    var gender: Gender = .notSet
    var weightKg: Double?
    var heightCm: Double?
    var photoData: Data?

    var displayName: String {
        let full = [name, surname].filter { !$0.isEmpty }.joined(separator: " ")
        return full.isEmpty ? "Friend" : full
    }

    var bmi: Double? {
        guard let weightKg, let heightCm, heightCm > 0 else { return nil }
        return weightKg / pow(heightCm / 100, 2)
    }

    var bmiBand: String? {
        guard let bmi else { return nil }
        switch bmi {
        case ..<18.5: return "Low"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }

    enum HeightUnit { case metric, imperial }

    static var heightUnit: HeightUnit {
        Locale.current.measurementSystem == .us ? .imperial : .metric
    }
}

enum ProfileStore {
    private static var defaults: UserDefaults { .standard }

    static func load() -> Profile {
        var profile = Profile()
        profile.name = defaults.string(forKey: UDKey.name) ?? ""
        profile.surname = defaults.string(forKey: UDKey.surname) ?? ""
        let age = defaults.integer(forKey: UDKey.age)
        profile.age = age > 0 ? age : nil
        profile.gender = Gender(rawValue: defaults.integer(forKey: UDKey.gender)) ?? .notSet
        let weight = defaults.double(forKey: UDKey.weight)
        profile.weightKg = weight > 0 ? weight : nil
        let height = defaults.double(forKey: UDKey.height)
        profile.heightCm = height > 0 ? height : nil
        profile.photoData = defaults.data(forKey: UDKey.photo)
        return profile
    }

    static func save(_ profile: Profile) {
        if profile.name.isEmpty { defaults.removeObject(forKey: UDKey.name) }
        else { defaults.set(profile.name, forKey: UDKey.name) }
        if profile.surname.isEmpty { defaults.removeObject(forKey: UDKey.surname) }
        else { defaults.set(profile.surname, forKey: UDKey.surname) }
        if let age = profile.age { defaults.set(age, forKey: UDKey.age) }
        else { defaults.removeObject(forKey: UDKey.age) }
        defaults.set(profile.gender.rawValue, forKey: UDKey.gender)
        if let weight = profile.weightKg { defaults.set(weight, forKey: UDKey.weight) }
        else { defaults.removeObject(forKey: UDKey.weight) }
        if let height = profile.heightCm { defaults.set(height, forKey: UDKey.height) }
        else { defaults.removeObject(forKey: UDKey.height) }
        if let photo = profile.photoData { defaults.set(photo, forKey: UDKey.photo) }
        else { defaults.removeObject(forKey: UDKey.photo) }
    }
}

// MARK: - Appearance & measuring mode

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum MeasuringMode: String, CaseIterable, Identifiable {
    case fast, standard, precise
    var id: String { rawValue }
    var title: String {
        switch self {
        case .fast: return "Fast"
        case .standard: return "Standard"
        case .precise: return "Precise"
        }
    }
    var duration: TimeInterval {
        switch self {
        case .fast: return 15
        case .standard: return 30
        case .precise: return 60
        }
    }
    var minimumValidIntervals: Int {
        switch self {
        case .fast: return 8
        case .standard: return 16
        case .precise: return 30
        }
    }
}
