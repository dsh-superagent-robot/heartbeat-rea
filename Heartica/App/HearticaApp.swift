import SwiftUI

@MainActor
final class AppState: ObservableObject {
    enum Phase {
        case splash
        case onboarding
        case postOnboarding
        case main
    }

    @Published var phase: Phase = .splash
    @Published var profile: Profile = ProfileStore.load()
    @Published var appearance: AppearanceMode
    @Published var isPremium: Bool
    @Published var showPaywall = false
    @Published var paywallSource: String = "general"
    @Published var toast: String?
    @Published var autoPresentMeasure = false
    @Published var previewArticle: Article?

    let dataStore = HealthDataStore.shared

    init() {
        let raw = UserDefaults.standard.string(forKey: UDKey.appearance) ?? "system"
        appearance = AppearanceMode(rawValue: raw) ?? .system
        isPremium = UserDefaults.standard.bool(forKey: UDKey.didPurchasedApp)
    }

    var colorScheme: ColorScheme? { appearance.colorScheme }

    func bootstrap() async {
        // Splash gate: config fetch + minimum wait (§3.2). Local fallback config is
        // already available, so only the minimum display time is observed.
        try? await Task.sleep(nanoseconds: 1_300_000_000)
        let defaults = UserDefaults.standard
        #if DEBUG
        if ProcessInfo.processInfo.environment["HEARTICA_DEMO"] == "1" {
            defaults.set(true, forKey: UDKey.isOnboardingPassed)
            defaults.set(true, forKey: UDKey.isPostOnboardingPassed)
            defaults.set(false, forKey: UDKey.needToShowPostOb)
            if dataStore.measurements().isEmpty {
                dataStore.seedDemoData()
            }
            defaults.set(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.10",
                         forKey: UDKey.whatsNewLastSeenVersion)
            if defaults.object(forKey: UDKey.achievementStartDate) == nil {
                defaults.set(Date(), forKey: UDKey.achievementStartDate)
            }
            var demoProfile = ProfileStore.load()
            if demoProfile.age == nil {
                demoProfile.name = "Alex"
                demoProfile.age = 32
                demoProfile.gender = .male
                demoProfile.weightKg = 74
                demoProfile.heightCm = 178
                ProfileStore.save(demoProfile)
                profile = demoProfile
            }
            if ProcessInfo.processInfo.environment["HEARTICA_PREMIUM"] == "1" {
                isPremium = true
            }
            phase = .main
            return
        }
        #endif
        if !defaults.bool(forKey: UDKey.isOnboardingPassed) {
            phase = .onboarding
        } else if defaults.bool(forKey: UDKey.needToShowPostOb)
                    && !defaults.bool(forKey: UDKey.isPostOnboardingPassed) {
            phase = .postOnboarding
        } else {
            phase = .main
        }
    }

    func completeOnboarding(profile newProfile: Profile, purchased: Bool = false) {
        profile = newProfile
        ProfileStore.save(newProfile)
        UserDefaults.standard.set(true, forKey: UDKey.isOnboardingPassed)
        UserDefaults.standard.set(true, forKey: UDKey.needToShowPostOb)
        UserDefaults.standard.set(false, forKey: UDKey.isPostOnboardingPassed)
        if purchased {
            setPremium(true)
        }
        phase = .postOnboarding
    }

    func completePostOnboarding() {
        UserDefaults.standard.set(true, forKey: UDKey.isPostOnboardingPassed)
        UserDefaults.standard.set(false, forKey: UDKey.needToShowPostOb)
        if UserDefaults.standard.object(forKey: UDKey.achievementStartDate) == nil {
            UserDefaults.standard.set(Date(), forKey: UDKey.achievementStartDate)
        }
        phase = .main
    }

    func setAppearance(_ mode: AppearanceMode) {
        appearance = mode
        UserDefaults.standard.set(mode.rawValue, forKey: UDKey.appearance)
    }

    func setPremium(_ value: Bool) {
        isPremium = value
        UserDefaults.standard.set(value, forKey: UDKey.didPurchasedApp)
    }

    func updateProfile(_ newProfile: Profile) {
        profile = newProfile
        ProfileStore.save(newProfile)
    }

    func presentPaywall(source: String) {
        paywallSource = source
        showPaywall = true
    }

    func showToast(_ message: String) {
        toast = message
    }

    func resetForOnboarding() {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: UDKey.isOnboardingPassed)
        defaults.set(false, forKey: UDKey.isPostOnboardingPassed)
        defaults.set(false, forKey: UDKey.needToShowPostOb)
        phase = .onboarding
    }
}

@main
struct HearticaApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var language = LanguageStore.shared

    init() {
        UITabBar.appearance().isHidden = true
        UINavigationBar.appearance().tintColor = UIColor(AppColor.brand)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(appState.dataStore)
                .environmentObject(ChartSettingsStore.shared)
                .preferredColorScheme(appState.colorScheme)
                .environmentObject(language)
                .environment(\.locale, language.effectiveLocale)
                .tint(AppColor.brand)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            switch appState.phase {
            case .splash:
                SplashView()
                    .transition(.opacity)
            case .onboarding:
                OnboardingView()
                    .transition(.opacity)
            case .postOnboarding:
                PostOnboardingView()
                    .transition(.opacity)
            case .main:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: phaseKey)
        .sheet(isPresented: $appState.showPaywall) {
            PaywallView(source: appState.paywallSource)
                .environmentObject(appState)
        }
    }

    private var phaseKey: Int {
        switch appState.phase {
        case .splash: return 0
        case .onboarding: return 1
        case .postOnboarding: return 2
        case .main: return 3
        }
    }
}
