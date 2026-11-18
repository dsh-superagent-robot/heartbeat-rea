import SwiftUI

enum MePeriod: String, CaseIterable, Identifiable {
    case day, week, month, quarter, year
    var id: String { rawValue }
    var short: String {
        switch self {
        case .day: return L("D")
        case .week: return L("W")
        case .month: return L("M")
        case .quarter: return L("3M")
        case .year: return L("Y")
        }
    }
    var localTitle: String {
        switch self {
        case .day: return L("Daily average")
        case .week: return L("Weekly average")
        case .month: return L("Monthly average")
        case .quarter: return L("Quarterly average")
        case .year: return L("Yearly average")
        }
    }
}

struct MeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var dataStore: HealthDataStore
    @ObservedObject private var achievements = AchievementService.shared

    @State private var period: MePeriod = .week
    @State private var offset = 0
    @State private var tagFilter: String?
    @State private var showFilter = false
    @State private var showProfile = false
    @State private var showSettings = false
    @State private var showInfo = false
    @State private var showAppleHealth = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                profileCard
                periodHeader
                statisticsCard
                achievementsCard
                journeyCard
                appleHealthCard
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .screenBackground()
        .navigationBarHidden(true)
        .sheet(isPresented: $showProfile) {
            ProfileView().environmentObject(appState)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(appState)
        }
        .sheet(isPresented: $showFilter) {
            TagFilterView(selected: $tagFilter).environmentObject(dataStore)
        }
        .sheet(isPresented: $showInfo) {
            InfoDocumentSheet(title: L("Information"), markdown: localizedMeInfo)
        }
        .sheet(isPresented: $showAppleHealth) {
            NavigationView {
                AppleHealthView().environmentObject(appState)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showAppleHealth = false }
                        }
                    }
            }
        }
    }

    // MARK: Profile

    private var profileCard: some View {
        HStack(spacing: 14) {
            avatar
            VStack(alignment: .leading, spacing: 3) {
                Text(appState.profile.displayName)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(AppColor.textPrimary)
                Text(profileSubtitle)
                    .font(.system(size: 12))
                    .foregroundColor(AppColor.textSecondary)
            }
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppColor.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(AppColor.surface))
            }
            .buttonStyle(.plain)
            Button {
                showProfile = true
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColor.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    private var profileSubtitle: String {
        var parts: [String] = []
        if let age = appState.profile.age { parts.append(LF("%d years", age)) }
        if appState.profile.gender != .notSet { parts.append(appState.profile.gender.title) }
        if parts.isEmpty { parts.append(L("Complete your profile")) }
        return parts.joined(separator: " · ")
    }

    private var avatar: some View {
        Group {
            if let data = appState.profile.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    AppColor.brandGradient
                    Text(initials)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(Circle())
    }

    private var initials: String {
        let name = appState.profile.displayName
        let parts = name.split(separator: " ")
        return parts.prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    // MARK: Period

    private var periodHeader: some View {
        VStack(spacing: 10) {
            HStack(spacing: 4) {
                ForEach(MePeriod.allCases) { item in
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) { period = item; offset = 0 }
                    } label: {
                        Text(item.short)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(period == item ? .white : AppColor.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(period == item ? AppColor.brand : Color.clear))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Capsule().fill(AppColor.surfaceAlt))

            HStack {
                Text(period.localTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
                Spacer()
                Button {
                    offset -= 1
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColor.textPrimary)
                }
                Text(windowLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColor.textPrimary)
                    .frame(minWidth: 110)
                Button {
                    if offset < 0 { offset += 1 }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(offset < 0 ? AppColor.textPrimary : AppColor.textSecondary.opacity(0.4))
                }
                .disabled(offset >= 0)
                Button {
                    showFilter = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(tagFilter == nil ? AppColor.textSecondary : AppColor.brand)
                }
            }
        }
    }

    private var windowLabel: String {
        let window = currentWindow
        switch period {
        case .day: return Fmt.date(window.start, format: "MMM d")
        case .week: return "\(Fmt.date(window.start, format: "MMM d"))–\(Fmt.date(window.end, format: "MMM d"))"
        case .month, .quarter, .year: return Fmt.date(window.start, format: "MMM yyyy")
        }
    }

    // MARK: Statistics

    private var statisticsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("My Statistics")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColor.textPrimary)
                Spacer()
                Button {
                    showInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(AppColor.textSecondary)
                }
            }
            .padding(.bottom, 10)

            if filteredMeasurements.isEmpty {
                EmptyStateView(icon: "chart.bar", title: "No Data",
                               message: "Keep measuring to see how your metrics change over time based on recent data.")
            } else {
                statRow(title: "Health Index", value: average(\.healthIndex), format: "%.1f", unit: "")
                Divider()
                statRow(title: "Chronic Stress Index", value: CSIService.shared.result.map(Double.init), format: "%.0f", unit: "SI")
                Divider()
                statRow(title: "Heart Rate Variability", value: average(\.sdnn), format: "%.0f", unit: "ms")
                Divider()
                statRow(title: "Heart Age", value: HeartAgeService.shared.result.map(Double.init), format: "%.0f", unit: L("years"))
                Divider()
                statRow(title: "RMSSD", value: average(\.rmssd), format: "%.0f", unit: "ms")
                Divider()
                statRow(title: "pNN50", value: average(\.pnn50), format: "%.0f", unit: "%")
            }
        }
        .card()
    }

    private func statRow(title: String, value: Double?, format: String, unit: String) -> some View {
        HStack {
            Text(L(title))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColor.textPrimary)
            Spacer()
            if let value {
                Text(String(format: format, value))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppColor.textPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 10))
                        .foregroundColor(AppColor.textSecondary)
                        .frame(width: 40, alignment: .leading)
                } else {
                    Spacer().frame(width: 40)
                }
            } else {
                Text(L("No Data"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
                    .frame(width: 90, alignment: .trailing)
            }
        }
        .padding(.vertical, 12)
    }

    private var filteredMeasurements: [HRMeasurement] {
        let window = currentWindow
        return dataStore.measurements(from: window.start, to: window.end)
            .filter { measurement in
                guard let tagFilter else { return true }
                if tagFilter.isEmpty { return measurement.tagId == nil }
                return measurement.tagId == tagFilter
            }
    }

    private func average(_ keyPath: KeyPath<HRMeasurement, Double>) -> Double? {
        let values = filteredMeasurements.map { $0[keyPath: keyPath] }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private var currentWindow: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        switch period {
        case .day:
            let day = calendar.date(byAdding: .day, value: offset, to: now) ?? now
            let start = calendar.startOfDay(for: day)
            return (start, calendar.date(byAdding: .day, value: 1, to: start) ?? now)
        case .week:
            let base = calendar.date(byAdding: .weekOfYear, value: offset, to: DateRange.startOfWeek(now)) ?? now
            return (base, calendar.date(byAdding: .weekOfYear, value: 1, to: base) ?? now)
        case .month:
            let base = calendar.date(byAdding: .month, value: offset, to: DateRange.startOfMonth(now)) ?? now
            return (base, calendar.date(byAdding: .month, value: 1, to: base) ?? now)
        case .quarter:
            let base = calendar.date(byAdding: .month, value: offset * 3, to: DateRange.startOfMonth(now)) ?? now
            return (base, calendar.date(byAdding: .month, value: 3, to: base) ?? now)
        case .year:
            var components = calendar.dateComponents([.year], from: now)
            components.year = (components.year ?? 2024) + offset
            components.month = 1
            components.day = 1
            let base = calendar.date(from: components) ?? now
            return (base, calendar.date(byAdding: .year, value: 1, to: base) ?? now)
        }
    }

    private var achievementsCard: some View {
        NavigationLink {
            AchievementsView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppColor.brandGradient)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(AppColor.brandSoft))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Achievements")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColor.textPrimary)
                    Text(LF("%d completed", achievements.completedCount))
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColor.textSecondary)
            }
            .card(padding: 14, radius: 20)
        }
        .buttonStyle(PressableCardStyle())
    }

    private var journeyCard: some View {
        NavigationLink {
            JourneyView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColor.purple)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(AppColor.purple.opacity(0.12)))
                VStack(alignment: .leading, spacing: 3) {
                    Text("My Journey")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColor.textPrimary)
                    Text(LF("Level %d", JourneyService.shared.currentLevel.id) + " · " + L(JourneyService.shared.currentLevel.title))
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColor.textSecondary)
            }
            .card(padding: 14, radius: 20)
        }
        .buttonStyle(PressableCardStyle())
    }

    private var appleHealthCard: some View {
        Button {
            showAppleHealth = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColor.success)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(AppColor.success.opacity(0.12)))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Apple Health Sync")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColor.textPrimary)
                    Text(L(HealthKitService.shared.connected ? "Connected" : "Connect your Apple Watch data"))
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColor.textSecondary)
            }
            .card(padding: 14, radius: 20)
        }
        .buttonStyle(PressableCardStyle())
    }
}

let meInfoMarkdown = """
## My Statistics
It's critically important to track your heart metrics. For this reason, you can see detailed information about your health trends on the Me screen.

You can customize the filters to make them easier to use and better suited to your needs.

> ### Filters & Features
>
> - **Tag filtering:** It's much easier to monitor your metrics' progress by filtering them with the tags you applied to each measurement.
>
> - **Time filtering:** As you add more measurements, view your progress over broader periods.
>
> - **Switching between time periods:** Sometimes it's necessary to step back and compare your current average values with previous ones.
>
> - **Trend line:** We use one general smoothing algorithm for all trend lines across all charts in the app.

Make sure to add a tag for deeper trend analysis and to connect lifestyle quality with your metrics.

You can also create Custom Tags to track and follow your unique patterns.
"""


private let meInfoMarkdownZh = """
## 我的统计
追踪心脏指标非常重要，因此你可以在“我的”页面查看详细的健康趋势。

你可以自定义筛选条件，让数据更符合你的需要。

> ### 筛选与功能
>
> - **标签筛选：** 使用测量标签筛选数据，更容易观察某一情境下的变化，例如整个月“睡醒后”的状态。
>
> - **时间筛选：** 随着测量增多，可以把时间窗口切换为月、季度或年。
>
> - **切换时间段：** 有时需要回顾过去的平均值，使用箭头即可在不同时间段之间切换。
>
> - **趋势线：** 数据有时会有波动，趋势线可以帮助你理解整体方向。应用内所有图表使用同一套平滑算法。

建议为测量添加标签，以便进行更深入的关联分析。

你也可以创建自定义标签，追踪自己独特的生活模式。
"""

private var localizedMeInfo: String {
    LanguageStore.shared.effective == .chinese ? meInfoMarkdownZh : meInfoMarkdown
}
