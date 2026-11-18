import SwiftUI

struct MainTabView: View {
    enum Tab: Int {
        case home, dashboard, insights, me
    }

    @EnvironmentObject private var appState: AppState
    @State private var selection: Tab = .home
    @State private var showMeasure = false
    @State private var showWhatsNew = false
    @State private var didApplyDebugRoute = false
    @State private var debugRoute: DebugRoute?

    var body: some View {
        Group {
            switch selection {
            case .home:
                NavigationStack { HomeView() }
            case .dashboard:
                NavigationStack { DashboardView() }
            case .insights:
                NavigationStack { InsightsView() }
            case .me:
                NavigationStack { MeView() }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            tabBar
        }
        .fullScreenCover(isPresented: $showMeasure) {
            MeasureFlowView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showWhatsNew) {
            WhatsNewView()
        }
        .fullScreenCover(item: $appState.previewArticle) { article in
            ArticleReaderView(article: article)
                .environmentObject(appState)
        }
        .fullScreenCover(item: $debugRoute) { route in
            NavigationView {
                debugDestination(route.id)
            }
            .environmentObject(appState)
            .environmentObject(appState.dataStore)
            .environmentObject(ChartSettingsStore.shared)
        }
        .onChange(of: appState.autoPresentMeasure) { newValue in
            if newValue {
                showMeasure = true
                appState.autoPresentMeasure = false
            }
        }
        .task {
            applyDebugRouteIfNeeded()
            checkWhatsNew()
        }
    }

    private func applyDebugRouteIfNeeded() {
        guard !didApplyDebugRoute else { return }
        didApplyDebugRoute = true
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if let raw = environment["HEARTICA_TAB"], let value = Int(raw), let tab = Tab(rawValue: value) {
            selection = tab
        }
        if environment["HEARTICA_MEASURE"] == "1" {
            showMeasure = true
        }
        if appState.autoPresentMeasure {
            showMeasure = true
            appState.autoPresentMeasure = false
        }
        if let screen = environment["HEARTICA_SCREEN"] {
            debugRoute = DebugRoute(id: screen)
        }
        if environment["HEARTICA_PAYWALL"] == "1" {
            appState.presentPaywall(source: "settings")
        }
        #endif
    }

    @ViewBuilder
    private func debugDestination(_ id: String) -> some View {
        switch id {
        case "history": HistoryView()
        case "achievements": AchievementsView()
        case "journey": JourneyView()
        case "csi": CSIView()
        case "heartage": HeartAgeView()
        case "monthly": MonthlyInsightsView()
        case "settings": SettingsView()
        case "insights": InsightsView()
        default: HomeView()
        }
    }

    private func checkWhatsNew() {
        guard !showMeasure else { return }
        let defaults = UserDefaults.standard
        let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.10"
        let seen = defaults.string(forKey: UDKey.whatsNewLastSeenVersion) ?? ""
        if seen != current {
            defaults.set(current, forKey: UDKey.whatsNewLastSeenVersion)
            showWhatsNew = true
        }
    }

    private struct DebugRoute: Identifiable {
        let id: String
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(.home, icon: "house.fill", title: "Home")
            tabButton(.dashboard, icon: "chart.bar.xaxis", title: "Dashboard")
            measureButton
            tabButton(.insights, icon: "lightbulb.fill", title: "Insights")
            tabButton(.me, icon: "person.fill", title: "Me")
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .background(
            AppColor.surface
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) {
                    Rectangle().fill(AppColor.separator).frame(height: 0.5)
                }
        )
    }

    private func tabButton(_ tab: Tab, icon: String, title: String) -> some View {
        Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                Text(L(title))
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(selection == tab ? AppColor.brand : AppColor.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var measureButton: some View {
        Button {
            showMeasure = true
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(AppColor.brandGradient)
                        .frame(width: 58, height: 58)
                        .shadow(color: AppColor.brand.opacity(0.45), radius: 12, x: 0, y: 6)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text(L("Measure"))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppColor.brand)
            }
            .offset(y: -14)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
