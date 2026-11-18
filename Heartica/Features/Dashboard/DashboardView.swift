import Charts
import SwiftUI

enum DashboardPeriod: String, CaseIterable, Identifiable {
    case lastMeasure, day, week, month, quarter, year
    var id: String { rawValue }
    var title: String {
        switch self {
        case .lastMeasure: return "Last measurement"
        case .day: return "Day average"
        case .week: return "Week average"
        case .month: return "Month average"
        case .quarter: return "Quarter average"
        case .year: return "Year average"
        }
    }
    var shortTitle: String {
        switch self {
        case .lastMeasure: return "Latest"
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "3M"
        case .year: return "Year"
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var dataStore: HealthDataStore
    @EnvironmentObject private var chartSettingsStore: ChartSettingsStore

    @State private var period: DashboardPeriod = .week
    @State private var selectedMetric: ResultMetric?
    @State private var showChartSettings = false

    private var measurements: [HRMeasurement] { dataStore.measurements() }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header
                periodPicker
                if measurements.isEmpty {
                    EmptyStateView(icon: "chart.xyaxis.line", title: "No Data",
                                   message: "Take a measurement to see your dashboard")
                        .card()
                        .padding(.top, 30)
                } else {
                    metricGrid
                    csiCard
                    heartAgeCard
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .screenBackground()
        .navigationBarHidden(true)
        .sheet(item: $selectedMetric) { metric in
            DashboardMetricDetail(metric: metric, period: period)
                .environmentObject(appState)
                .environmentObject(dataStore)
                .environmentObject(chartSettingsStore)
        }
        .sheet(isPresented: $showChartSettings) {
            ChartSettingsView()
                .environmentObject(chartSettingsStore)
                .environmentObject(dataStore)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Dashboard")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColor.textPrimary)
                Text(period.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
            }
            Spacer()
            Button {
                showChartSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColor.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(AppColor.surface))
            }
        }
        .padding(.top, 8)
    }

    private var periodPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DashboardPeriod.allCases) { item in
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) { period = item }
                    } label: {
                        Chip(text: item.shortTitle, selected: period == item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach([ResultMetric.hrv, .pnn50, .rmssd, .stress, .energy, .healthIndex]) { metric in
                Button {
                    selectedMetric = metric
                } label: {
                    metricCard(metric)
                }
                .buttonStyle(PressableCardStyle())
            }
        }
    }

    private func metricCard(_ metric: ResultMetric) -> some View {
        let value = average(metric)
        let status = value.map { metric.status(for: $0) }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(metric.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
                Spacer()
                if let status {
                    Circle().fill(color(status.color)).frame(width: 6, height: 6)
                }
            }
            if let value {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(formatValue(value, metric: metric))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColor.textPrimary)
                    if !metric.unit.isEmpty {
                        Text(metric.unit)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppColor.textSecondary)
                    }
                }
                Text(status?.indicator ?? "")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(status.map { color($0.color) } ?? AppColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                TrendChart(measurements: measurements, metric: metric,
                           chartType: chartSettingsStore.settings.chartType,
                           showThresholds: false, showTrendLine: false,
                           compact: true)
                    .frame(height: 46)
                    .allowsHitTesting(false)
            } else {
                Text("No Data")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColor.textSecondary)
                    .frame(height: 78, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: 14, radius: 20)
    }

    private var csiCard: some View {
        NavigationLink {
            CSIView()
        } label: {
            let progress = CSIService.shared.progress
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(AppColor.purple.opacity(0.12)).frame(width: 48, height: 48)
                    Image(systemName: "bolt.heart.fill")
                        .foregroundColor(AppColor.purple)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Chronic Stress Index")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColor.textPrimary)
                    Text(progress.completed
                         ? (progress.result.map { MetricCatalog.csiStatus(Double($0)).title } ?? "Completed")
                         : (progress.started ? "Day \(progress.day) of 7" : "7-day protocol"))
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.textSecondary)
                }
                Spacer()
                if let result = progress.result {
                    Text("\(result)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColor.textPrimary)
                } else {
                    ProgressView(value: Double(progress.day), total: 7)
                        .tint(AppColor.purple)
                        .frame(width: 56)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColor.textSecondary)
            }
            .card(padding: 16, radius: 20)
        }
        .buttonStyle(PressableCardStyle())
    }

    private var heartAgeCard: some View {
        NavigationLink {
            HeartAgeView()
        } label: {
            let service = HeartAgeService.shared
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(AppColor.orange.opacity(0.12)).frame(width: 48, height: 48)
                    Image(systemName: "heart.circle.fill")
                        .foregroundColor(AppColor.orange)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Heart Age")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColor.textPrimary)
                    Text(heartAgeSubtitle)
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
                if let result = service.result {
                    Text("\(result)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColor.textPrimary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColor.textSecondary)
                }
            }
            .card(padding: 16, radius: 20)
        }
        .buttonStyle(PressableCardStyle())
    }

    private var heartAgeSubtitle: String {
        let service = HeartAgeService.shared
        if !service.hasRequiredProfile { return "Add Your Age & Gender" }
        if service.result != nil, let status = service.status { return status.title }
        return "Measure your heart rate for 3 days"
    }

    // MARK: Aggregation

    private func average(_ metric: ResultMetric) -> Double? {
        guard !measurements.isEmpty else { return nil }
        if period == .lastMeasure {
            return measurements.first.map { metric.value(from: $0) }
        }
        let start = startDate(for: period)
        let window = measurements.filter { $0.time >= start }
        guard !window.isEmpty else { return nil }
        let values = window.map { metric.value(from: $0) }
        return values.reduce(0, +) / Double(values.count)
    }

    private func startDate(for period: DashboardPeriod) -> Date {
        let calendar = Calendar.current
        switch period {
        case .lastMeasure:
            return .distantPast
        case .day:
            return calendar.startOfDay(for: Date())
        case .week:
            return DateRange.startOfWeek()
        case .month:
            return DateRange.startOfMonth()
        case .quarter:
            let month = calendar.component(.month, from: Date())
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            var components = calendar.dateComponents([.year], from: Date())
            components.month = quarterStartMonth
            components.day = 1
            return calendar.date(from: components) ?? DateRange.monthsAgo(3)
        case .year:
            let components = calendar.dateComponents([.year], from: Date())
            return calendar.date(from: components) ?? DateRange.monthsAgo(12)
        }
    }

    private func formatValue(_ value: Double, metric: ResultMetric) -> String {
        switch metric {
        case .healthIndex: return String(format: "%.1f", value)
        default: return String(format: "%.0f", value)
        }
    }

    private func color(_ name: String) -> Color {
        switch name {
        case "green": return AppColor.success
        case "yellow": return AppColor.warning
        case "orange": return AppColor.orange
        case "red": return AppColor.danger
        case "blue": return AppColor.blue
        default: return AppColor.success
        }
    }
}

// MARK: - Metric detail

struct DashboardMetricDetail: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var dataStore: HealthDataStore
    @EnvironmentObject private var chartSettingsStore: ChartSettingsStore

    let metric: ResultMetric
    let period: DashboardPeriod
    @State private var showSettings = false

    private var measurements: [HRMeasurement] { dataStore.measurements() }

    private var window: [HRMeasurement] {
        let calendar = Calendar.current
        let start: Date
        switch period {
        case .lastMeasure: start = .distantPast
        case .day: start = calendar.startOfDay(for: Date())
        case .week: start = DateRange.startOfWeek()
        case .month: start = DateRange.startOfMonth()
        case .quarter: start = DateRange.monthsAgo(3)
        case .year: start = DateRange.monthsAgo(12)
        }
        return measurements.filter { $0.time >= start }
    }

    private var average: Double? {
        if period == .lastMeasure { return measurements.first.map { metric.value(from: $0) } }
        guard !window.isEmpty else { return nil }
        return window.map { metric.value(from: $0) }.reduce(0, +) / Double(window.count)
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(metric.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppColor.textSecondary)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(average.map { formatValue($0) } ?? "No Data")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(AppColor.textPrimary)
                            if average != nil, !metric.unit.isEmpty {
                                Text(metric.unit)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(AppColor.textSecondary)
                            }
                        }
                        if let average {
                            let status = metric.status(for: average)
                            HStack(spacing: 6) {
                                Circle().fill(statusColor(status.color)).frame(width: 6, height: 6)
                                Text(status.indicator)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(statusColor(status.color))
                            }
                            Text("Compare your latest result with your average values")
                                .font(.system(size: 12))
                                .foregroundColor(AppColor.textSecondary)
                        }
                    }
                    .padding(.top, 8)

                    if measurements.isEmpty {
                        EmptyStateView(icon: "chart.xyaxis.line", title: "No Data",
                                       message: "Take a measurement to see this metric")
                            .card()
                    } else {
                        TrendChart(measurements: measurements, metric: metric,
                                   chartType: chartSettingsStore.settings.chartType,
                                   showThresholds: chartSettingsStore.settings.showThresholds,
                                   showTrendLine: chartSettingsStore.settings.showTrendLine,
                                   compact: false)
                            .frame(height: 230)
                            .card(padding: 12)
                    }

                    Button {
                        appState.autoPresentMeasure = true
                        dismiss()
                    } label: {
                        Text("Measure Now")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        showSettings = true
                    } label: {
                        Text("Settings")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(20)
            }
            .screenBackground()
            .navigationTitle(metric.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showSettings) {
                ChartSettingsView()
                    .environmentObject(chartSettingsStore)
                    .environmentObject(dataStore)
            }
        }
    }

    private func formatValue(_ value: Double) -> String {
        switch metric {
        case .healthIndex: return String(format: "%.1f", value)
        default: return String(format: "%.0f", value)
        }
    }

    private func statusColor(_ name: String) -> Color {
        switch name {
        case "green": return AppColor.success
        case "yellow": return AppColor.warning
        case "orange": return AppColor.orange
        case "red": return AppColor.danger
        case "blue": return AppColor.blue
        default: return AppColor.success
        }
    }
}

// MARK: - Chart

struct TrendChart: View {
    let measurements: [HRMeasurement]
    let metric: ResultMetric
    var chartType: ChartType = .bar
    var showThresholds: Bool = false
    var showTrendLine: Bool = true
    var compact: Bool = false

    struct Point: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    private var points: [Point] {
        let calendar = Calendar.current
        var buckets: [Date: [Double]] = [:]
        for measurement in measurements {
            let day = calendar.startOfDay(for: measurement.time)
            buckets[day, default: []].append(metric.value(from: measurement))
        }
        return buckets.keys.sorted().map { day in
            let values = buckets[day] ?? []
            return Point(date: day, value: values.reduce(0, +) / Double(max(values.count, 1)))
        }
    }

    private var trendPoints: [Point] {
        guard points.count >= 2 else { return points }
        var result: [Point] = []
        for index in points.indices {
            let lower = max(0, index - 2)
            let window = points[lower...index]
            let avg = window.map(\.value).reduce(0, +) / Double(window.count)
            result.append(Point(date: points[index].date, value: avg))
        }
        return result
    }

    private var color: Color {
        switch metric {
        case .stress: return AppColor.warning
        case .energy: return AppColor.orange
        case .healthIndex: return AppColor.success
        default: return AppColor.brand
        }
    }

    var body: some View {
        Chart {
            ForEach(points) { point in
                if chartType == .bar {
                    BarMark(x: .value("Day", point.date, unit: .day),
                            y: .value(metric.title, point.value))
                    .foregroundStyle(color.opacity(0.65))
                    .cornerRadius(compact ? 2 : 4)
                } else {
                    LineMark(x: .value("Day", point.date, unit: .day),
                             y: .value(metric.title, point.value))
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                    AreaMark(x: .value("Day", point.date, unit: .day),
                             y: .value(metric.title, point.value))
                    .foregroundStyle(LinearGradient(colors: [color.opacity(0.25), color.opacity(0.02)],
                                                    startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)
                }
            }

            if showTrendLine, chartType == .bar {
                ForEach(trendPoints) { point in
                    LineMark(x: .value("Day", point.date, unit: .day),
                             y: .value("Trend", point.value))
                    .foregroundStyle(AppColor.textPrimary.opacity(0.55))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    .interpolationMethod(.catmullRom)
                }
            }

            if showThresholds {
                RuleMark(y: .value("Normal low", thresholdLow))
                    .foregroundStyle(AppColor.success.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                RuleMark(y: .value("Normal high", thresholdHigh))
                    .foregroundStyle(AppColor.warning.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
        }
        .chartXAxis {
            if !compact {
                AxisMarks(values: .stride(by: .day, count: max(points.count / 4, 1))) { value in
                    AxisGridLine().foregroundStyle(AppColor.separator.opacity(0.5))
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
        }
        .chartYAxis {
            if !compact {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(AppColor.separator.opacity(0.5))
                    AxisValueLabel()
                }
            }
        }
        .chartPlotStyle { plot in
            plot.background(Color.clear)
        }
    }

    private var thresholdLow: Double {
        switch metric {
        case .hrv, .sdnn: return 50
        case .rmssd: return 30
        case .pnn50: return 20
        case .stress: return 25
        case .energy: return 60
        case .healthIndex: return 4.5
        default: return 60
        }
    }

    private var thresholdHigh: Double {
        switch metric {
        case .hrv, .sdnn: return 100
        case .rmssd: return 80
        case .pnn50: return 30
        case .stress: return 70
        case .energy: return 100
        case .healthIndex: return 6.5
        default: return 100
        }
    }
}

// MARK: - Chart settings

struct ChartSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var chartSettingsStore: ChartSettingsStore
    @EnvironmentObject private var dataStore: HealthDataStore

    @State private var draft = ChartSettings.load()

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Graph Preview")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColor.textPrimary)
                        Text("Adjust how your widget looks and responds")
                            .font(.system(size: 12))
                            .foregroundColor(AppColor.textSecondary)
                        TrendChart(measurements: sampleMeasurements, metric: .hrv,
                                   chartType: draft.chartType,
                                   showThresholds: draft.showThresholds,
                                   showTrendLine: draft.showTrendLine,
                                   compact: false)
                            .frame(height: 170)
                            .padding(.top, 4)
                    }
                    .card()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Chart Type")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColor.textSecondary)
                        Picker("Chart Type", selection: $draft.chartType) {
                            ForEach(ChartType.allCases) { type in
                                Text(type.title).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(spacing: 0) {
                        Toggle("Show Thresholds", isOn: $draft.showThresholds)
                            .tint(AppColor.brand)
                            .padding(.vertical, 12)
                        Divider()
                        Toggle("Show Trend Line", isOn: $draft.showTrendLine)
                            .tint(AppColor.brand)
                            .padding(.vertical, 12)
                    }
                    .padding(.horizontal, 16)
                    .background(RoundedRectangle(cornerRadius: 18).fill(AppColor.surface))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Default Time Range")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColor.textSecondary)
                        FlowLayout(spacing: 8) {
                            ForEach(ChartTimeRange.allCases) { range in
                                Button {
                                    draft.timeRange = range
                                } label: {
                                    Chip(text: range.title, selected: draft.timeRange == range)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button("Reset to Default") {
                        draft = ChartSettings()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColor.brand)
                    .frame(maxWidth: .infinity)
                }
                .padding(20)
            }
            .screenBackground()
            .navigationTitle("Chart Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        chartSettingsStore.settings = draft
                        chartSettingsStore.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var sampleMeasurements: [HRMeasurement] {
        let all = dataStore.measurements()
        if all.count >= 3 { return all }
        let now = Date()
        return (0..<7).map { day in
            HRMeasurement(id: UUID().uuidString,
                          time: Calendar.current.date(byAdding: .day, value: -day, to: now) ?? now,
                          kind: .camera, tagId: nil, createdAt: now,
                          pulse: 70, hrv: 58 + Double(day), rmssd: 44, sdnn: 58,
                          pnn50: 18, stress: 40, energy: 82, healthIndex: 6.1, csi: 120,
                          source: "inApp")
        }
    }
}
