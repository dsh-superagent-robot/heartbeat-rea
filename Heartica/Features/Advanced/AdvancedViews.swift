import SwiftUI

struct CSIView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var dataStore: HealthDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var showInfo = false
    @State private var showStartOver = false
    @State private var shareText: String?

    private var progress: CSIService.Progress { CSIService.shared.progress }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                hero
                if progress.completed, let result = progress.result {
                    chartCard(result: result)
                }
                actionButton
                Text(progress.completed
                     ? "Keep measuring, and the Stress Index will update daily based on your last 7 measurements."
                     : "The Chronic Stress Index is calculated as the 7-day average of Stress Index (SI) measures.")
                    .font(.system(size: 12))
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            .padding(18)
        }
        .screenBackground()
        .navigationTitle("Stress Index")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showInfo = true
                    } label: {
                        Label("About Stress Index", systemImage: "info.circle")
                    }
                    Button {
                        shareText = exportText
                    } label: {
                        Label("Export Results", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        showStartOver = true
                    } label: {
                        Label("Start Over", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showInfo) {
            InfoDocumentSheet(title: L("Chronic Stress Index"), markdown: localizedCSIInfo)
        }
        .sheet(item: Binding(get: { shareText.map(SharePayload.init) },
                             set: { if $0 == nil { shareText = nil } })) { payload in
            ShareSheet(items: [payload.text])
        }
        .alert("Delete current results and start from Day 1?", isPresented: $showStartOver) {
            Button("Cancel", role: .cancel) {}
            Button("Delete and Start Over", role: .destructive) {
                CSIService.shared.startOver()
                dataStore.objectWillChange.send()
            }
        }
    }

    private var hero: some View {
        let band = progress.result.map { MetricCatalog.csiStatus(Double($0)) }
        return VStack(spacing: 14) {
            HStack {
                Text("Chronic Stress Index")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
                Spacer()
                if let band {
                    StatusBadge(text: band.title, color: bandColor(band.color))
                }
            }
            if let result = progress.result {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(result)")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(AppColor.textPrimary)
                    Text("SI")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColor.textSecondary)
                    Spacer()
                }
                HStack {
                    Text("Weekly average")
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.textSecondary)
                    Spacer()
                    if let band {
                        Text(band.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(bandColor(band.color))
                    }
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(progress.started ? "Day \(max(progress.day, 1))" : "Day 1")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(AppColor.textPrimary)
                    Text("of 7")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColor.textSecondary)
                    Spacer()
                }
                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { index in
                        Capsule()
                            .fill(index < progress.day ? AppColor.purple : AppColor.separator)
                            .frame(height: 6)
                    }
                }
                Text(progress.hasMeasurementToday ? "Day \(max(progress.day, 1)) is logged!" : "Time to Measure")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .card()
    }

    private func chartCard(result: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L("Last 7 Stress Index readings"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColor.textSecondary)
            let values = lastSeven()
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                    VStack(spacing: 4) {
                        Capsule()
                            .fill(value >= 300 ? AppColor.orange : (value >= 150 ? AppColor.warning : AppColor.success))
                            .frame(width: 22, height: CGFloat(min(Double(value), 500) / 500 * 100 + 10))
                        Text("\(value)")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(AppColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 130, alignment: .bottom)
        }
        .card()
    }

    private func lastSeven() -> [Int] {
        let calendar = Calendar.current
        var values: [Int] = []
        let measurements = dataStore.measurements().reversed()
        var seen: Set<Date> = []
        for measurement in measurements {
            let day = calendar.startOfDay(for: measurement.time)
            guard !seen.contains(day) else { continue }
            seen.insert(day)
            values.append(Int(measurement.csi))
        }
        return Array(values.suffix(7))
    }

    private var actionButton: some View {
        Group {
            if progress.completed {
                Button {
                    appState.autoPresentMeasure = true
                } label: {
                    Text("Measure Now")
                }
                .buttonStyle(PrimaryButtonStyle())
            } else if progress.hasMeasurementToday {
                Text("Continue Tomorrow")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Capsule().fill(AppColor.surfaceAlt))
            } else {
                Button {
                    appState.autoPresentMeasure = true
                } label: {
                    Text("Measure Now")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private var exportText: String {
        L("Heartica Chronic Stress Index") + "\n" +
        (progress.result.map { LF("Current SI: %d", $0) } ?? L("Protocol in progress")) +
        "\n" + LF("Day %d of 7", progress.day) + "\n" + L("Generated") + " " + Fmt.date(Date())
    }

    private func bandColor(_ name: String) -> Color {
        switch name {
        case "green": return AppColor.success
        case "yellow": return AppColor.warning
        case "orange": return AppColor.orange
        case "red": return AppColor.danger
        default: return AppColor.blue
        }
    }
}

struct HeartAgeView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var showInfo = false
    @State private var showStartOver = false
    @State private var showProfile = false

    private var service: HeartAgeService { HeartAgeService.shared }
    private var progress: HeartAgeService.Progress { service.progress }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                if !service.hasRequiredProfile {
                    noParamsCard
                } else {
                    hero
                    if service.result != nil {
                        infoCard
                    }
                    actionButton
                }
            }
            .padding(18)
        }
        .screenBackground()
        .navigationTitle("Heart Age")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showInfo = true
                    } label: {
                        Label("About Heart Age", systemImage: "info.circle")
                    }
                    Button(role: .destructive) {
                        showStartOver = true
                    } label: {
                        Label("Start Over", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showInfo) {
            InfoDocumentSheet(title: L("Heart Age"), markdown: localizedHeartAgeInfo)
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
                .environmentObject(appState)
        }
        .alert("Delete current results and start from Day 1?", isPresented: $showStartOver) {
            Button("Cancel", role: .cancel) {}
            Button("Delete and Start Over", role: .destructive) {
                service.startOver()
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            Text("Your Heart Age")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColor.textSecondary)
            if let result = service.result, let status = service.status {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(result)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(AppColor.textPrimary)
                    Text("years")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColor.textSecondary)
                }
                StatusBadge(text: status.title, color: statusColor(status.color))
                Text(status.interpretation)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColor.textPrimary)
                if let age = appState.profile.age {
                    Text(LF("Chronological age: %d", age))
                        .font(.system(size: 11))
                        .foregroundColor(AppColor.textSecondary)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(progress.count)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundColor(AppColor.textPrimary)
                    Text("of 3 measurements")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColor.textSecondary)
                }
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index < progress.count ? AppColor.orange : AppColor.separator)
                            .frame(height: 6)
                    }
                }
                Text("Measure your heart rate for 3 days")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How it works")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColor.textPrimary)
            Text(L("Heart Age is estimated from the RMSSD of your last three measurements. It is a wellness indicator, not a medical diagnosis."))
                .font(.system(size: 12))
                .foregroundColor(AppColor.textSecondary)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: 16)
    }

    private var noParamsCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 44))
                .foregroundColor(AppColor.brand)
            Text("Add Your Age & Gender")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(AppColor.textPrimary)
            Text("This will help calculate your Heart Age")
                .font(.system(size: 13))
                .foregroundColor(AppColor.textSecondary)
            Button("Add Now") { showProfile = true }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 24).fill(AppColor.surface))
    }

    private var actionButton: some View {
        Group {
            if service.result != nil {
                Button {
                    appState.autoPresentMeasure = true
                } label: {
                    Text("Measure Now")
                }
                .buttonStyle(PrimaryButtonStyle())
            } else if progress.hasMeasurementToday {
                Text("Next measurement: tomorrow")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Capsule().fill(AppColor.surfaceAlt))
            } else {
                Button {
                    appState.autoPresentMeasure = true
                } label: {
                    Text("Measure Now")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private func statusColor(_ name: String) -> Color {
        switch name {
        case "green": return AppColor.success
        case "yellow": return AppColor.warning
        case "red": return AppColor.danger
        default: return AppColor.textSecondary
        }
    }
}

// MARK: - Info & share helpers

struct InfoDocumentSheet: View {
    let title: String
    let markdown: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                Text(.init(markdown))
                    .font(.system(size: 14))
                    .foregroundColor(AppColor.textPrimary)
                    .lineSpacing(5)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .screenBackground()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct SharePayload: Identifiable {
    let text: String
    var id: String { text }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

let csiInfoMarkdown = """
## Chronic Stress Index
The Chronic Stress Index is calculated as the 7-day average of Stress Index (SI) measures.

### The Main Metric
We use the [Baevsky Stress Index](https://pmc.ncbi.nlm.nih.gov/articles/PMC10305391/) (SI) formula as one of the most accurate.

SI is a geometric measure of heart rate variability that reflects cardiovascular stress and is strongly linked to sympathetic nervous activity.

> ### Values and Interpretation
>
> 🔴 **Very High Stress** (>500): severe autonomic dysfunction or stress overload.
>
> 🟠 **High Stress** (300–500): significant mental or physical strain.
>
> 🟡 **Elevated Stress** (150–299): physical exertion or emotional tension.
>
> 🟢 **Normal** (50–149): healthy and well-balanced.
>
> 🔵 **Low Stress** (<50): low stress level and calm state.

Regular monitoring helps prevent overexertion, manage overall well-being, and maintain balance.
"""

let heartAgeInfoMarkdown = """
## Heart Age
Heart Age is an estimate of the biological (vascular) age of your cardiovascular system compared to your chronological age.

It is derived from the analysis of your pulse wave signal (PPG) measured by the camera.

### The Main Metric
We use the Root Mean Square of Successive Differences ([RMSSD](https://pmc.ncbi.nlm.nih.gov/articles/PMC5624990/#S6)).

[Scientific research](https://www.sciencedirect.com/science/article/pii/S0735109797005548) shows that RMSSD correlates with age with statistical significance.

> ### Values and Interpretation
>
> 🟢 **Good** (lower than your real age): arteries are more elastic than average for your age group
>
> 🟡 **Equal** (close to your real age): vascular system matches your biological age
>
> 🟠 **High** (higher than your real age): increased arterial stiffness compared to peers

> ### Disclaimer
> This feature is intended for wellness and educational purposes only. It should not be used for medical diagnosis or treatment decisions.
"""


private let csiInfoMarkdownZh = """
## 慢性压力指数
慢性压力指数由压力指数（SI）的 7 天平均值计算得出。

### 核心指标
我们使用 [Baevsky 压力指数](https://pmc.ncbi.nlm.nih.gov/articles/PMC10305391/)（SI）作为较准确的评估方法之一。

SI 是反映心血管压力和交感神经活动的心率变异性几何指标，适合快速评估和长期监测压力水平。

> ### 数值与解读
>
> 🔴 **极高压力**（>500）：严重的自主神经失调或压力过载。
>
> 🟠 **高压力**（300–500）：明显的身心紧张。
>
> 🟡 **压力升高**（150–299）：体力消耗或情绪紧张。
>
> 🟢 **正常**（50–149）：健康平衡、心血管适应良好。
>
> 🔵 **低压力**（<50）：状态平静、压力较低。

规律监测有助于避免过度消耗、管理整体健康，并保持身心平衡。
"""

private let heartAgeInfoMarkdownZh = """
## 心脏年龄
心脏年龄是根据脉搏波信号估算的心血管“生物年龄”，可与实际年龄进行比较。

### 核心指标
我们使用相邻心跳间期差值的均方根（[RMSSD](https://pmc.ncbi.nlm.nih.gov/articles/PMC5624990/#S6)）。

[科学研究](https://www.sciencedirect.com/science/article/pii/S0735109797005548)表明，RMSSD 与年龄存在统计学相关性。

> ### 数值与解读
>
> 🟢 **良好**（低于实际年龄）：血管弹性优于同龄人
>
> 🟡 **相当**（接近实际年龄）：血管状态与生理年龄相符
>
> 🟠 **偏高**（高于实际年龄）：血管僵硬度高于同龄人

> ### 免责声明
> 此功能仅用于健康参考和教育，不应用于医学诊断或治疗决策。
"""

private var localizedCSIInfo: String {
    LanguageStore.shared.effective == .chinese ? csiInfoMarkdownZh : csiInfoMarkdown
}

private var localizedHeartAgeInfo: String {
    LanguageStore.shared.effective == .chinese ? heartAgeInfoMarkdownZh : heartAgeInfoMarkdown
}
