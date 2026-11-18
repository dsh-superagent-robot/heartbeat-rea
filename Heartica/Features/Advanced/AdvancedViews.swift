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
            InfoDocumentSheet(title: "Chronic Stress Index", markdown: csiInfoMarkdown)
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
            Text("Last 7 Stress Index readings")
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
        "Heartica Chronic Stress Index\n" +
        (progress.result.map { "Current SI: \($0)" } ?? "Protocol in progress") +
        "\nDay \(progress.day) of 7\nGenerated \(Fmt.date(Date()))"
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
            InfoDocumentSheet(title: "Heart Age", markdown: heartAgeInfoMarkdown)
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
                    Text("Chronological age: \(age)")
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
            Text("Heart Age is estimated from the RMSSD of your last three measurements. It is a wellness indicator, not a medical diagnosis.")
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
