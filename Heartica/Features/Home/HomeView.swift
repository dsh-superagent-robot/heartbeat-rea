import Combine
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var dataStore: HealthDataStore

    @State private var carouselIndex = 0
    @State private var showPressureLog = false
    @State private var showOxygenLog = false
    @State private var showGlucoseLog = false
    @State private var showTags = false

    private let timer = Timer.publish(every: 7, on: .main, in: .common).autoconnect()

    private var measurements: [HRMeasurement] { dataStore.measurements() }
    private var latest: HRMeasurement? { measurements.first }
    private var pressure: PressureRecord? { dataStore.pressureRecords().first }
    private var oxygen: OxygenRecord? { dataStore.oxygenRecords().first }
    private var glucose: GlucoseRecord? { dataStore.glucoseRecords().first }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                carousel
                summaryCards
                levelCard
                measurementsSection
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 24)
        }
        .screenBackground()
        .navigationBarHidden(true)
        .sheet(isPresented: $showPressureLog) {
            ManualVitalsView(kind: .pressure)
                .environmentObject(appState)
                .environmentObject(dataStore)
        }
        .sheet(isPresented: $showOxygenLog) {
            ManualVitalsView(kind: .oxygen)
                .environmentObject(appState)
                .environmentObject(dataStore)
        }
        .sheet(isPresented: $showGlucoseLog) {
            ManualVitalsView(kind: .glucose)
                .environmentObject(appState)
                .environmentObject(dataStore)
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                carouselIndex = (carouselIndex + 1) % 4
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Heart Health")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColor.textPrimary)
                Text(dateSubtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
            }
            Spacer()
            NavigationLink {
                AchievementsView()
            } label: {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppColor.brand)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(AppColor.surface))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    private var dateSubtitle: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(Date()) { return "Today" }
        if calendar.isDateInYesterday(Date()) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }

    // MARK: Carousel

    private var carousel: some View {
        VStack(spacing: 10) {
            TabView(selection: $carouselIndex) {
                heartRatePage.tag(0)
                csiPage.tag(1)
                heartAgePage.tag(2)
                promoPage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 190)

            HStack(spacing: 5) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(index == carouselIndex ? AppColor.brand : AppColor.separator)
                        .frame(width: index == carouselIndex ? 18 : 6, height: 4)
                }
            }
            .animation(.easeOut(duration: 0.2), value: carouselIndex)
        }
    }

    private var heartRatePage: some View {
        NavigationLink {
            MeasurementDetailView(measurementID: latest?.id)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(AppColor.brandGradient)
                HStack {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12))
                            Text("Heart Rate")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white.opacity(0.85))

                        if let latest {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(Int(latest.pulse))")
                                    .font(.system(size: 50, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("bpm")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            HStack(spacing: 14) {
                                smallMetric("Pulse", "\(Int(latest.pulse))")
                                smallMetric("Stress", "\(Int(latest.stress))")
                                smallMetric("Energy", "\(Int(latest.energy))")
                            }
                        } else {
                            Text("Take a measurement \nto see it here")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .lineSpacing(2)
                        }

                        HStack(spacing: 4) {
                            Text("Details")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        Sparkline(values: measurements.prefix(12).reversed().map(\.pulse))
                            .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            .frame(width: 92, height: 48)
                        Text(latest.map { Fmt.time($0.time) } ?? "No Data")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(20)
            }
        }
        .buttonStyle(PressableCardStyle())
        .padding(.vertical, 2)
    }

    private func smallMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private var csiPage: some View {
        NavigationLink {
            CSIView()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(AppColor.csiGradient)
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.heart.fill")
                            Text("Chronic Stress Index")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))

                        let progress = CSIService.shared.progress
                        Text(progress.started ? "\(progress.result ?? progress.day)" : "7-Day Protocol")
                            .font(.system(size: progress.started ? 38 : 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(progress.started ? "Day \(progress.day) of 7" : "Measure daily to reveal your stress pattern")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.65))
                        HStack(spacing: 4) {
                            ForEach(0..<7, id: \.self) { day in
                                Capsule()
                                    .fill(day < progress.day ? Color.white : Color.white.opacity(0.25))
                                    .frame(height: 4)
                            }
                        }
                        .frame(width: 150)
                    }
                    Spacer()
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(.white.opacity(0.35))
                }
                .padding(20)
            }
        }
        .buttonStyle(PressableCardStyle())
    }

    private var heartAgePage: some View {
        NavigationLink {
            HeartAgeView()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(AppColor.heartAgeGradient)
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.circle.fill")
                            Text("Heart Age")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        let progress = HeartAgeService.shared.progress
                        if let age = HeartAgeService.shared.result {
                            Text("\(age)")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("years — your heart's age")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.65))
                        } else {
                            Text(progress.started ? "\(progress.count) of 3" : "3-Measurement")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text(progress.started ? "measurements collected" : "protocol to reveal your heart age")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.65))
                        }
                        HStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { index in
                                Capsule()
                                    .fill(index < HeartAgeService.shared.progress.count ? Color.white : Color.white.opacity(0.25))
                                    .frame(height: 4)
                            }
                        }
                        .frame(width: 120)
                    }
                    Spacer()
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(.white.opacity(0.35))
                }
                .padding(20)
            }
        }
        .buttonStyle(PressableCardStyle())
    }

    private var promoPage: some View {
        Button {
            appState.presentPaywall(source: "home_banner")
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(LinearGradient(colors: [Color(red: 0.10, green: 0.10, blue: 0.14),
                                                  Color(red: 0.24, green: 0.22, blue: 0.30)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppColor.warning)
                        Text("Go Premium")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Access all features without limits")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        Text("Try for Free")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(AppColor.brand))
                            .padding(.top, 2)
                    }
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 58, weight: .light))
                        .foregroundColor(.white.opacity(0.18))
                }
                .padding(20)
            }
        }
        .buttonStyle(PressableCardStyle())
    }

    // MARK: Vitals cards

    private var summaryCards: some View {
        VStack(spacing: 12) {
            vitalsRow(title: "Pressure", icon: "waveform.path.ecg", color: AppColor.brand,
                      value: pressure.map { "\($0.sys)/\($0.dia)" } ?? "No Data",
                      unit: "mmHg",
                      subtitle: pressure.map { Fmt.date($0.createdAt, format: "MMM d, h:mm a") }
                        ?? "Log your blood pressure \nto see it here",
                      button: "Log Pressure") { showPressureLog = true }

            vitalsRow(title: "Oxygen", icon: "lungs.fill", color: AppColor.blue,
                      value: oxygen.map { "\($0.value)" } ?? "No Data",
                      unit: "%",
                      subtitle: oxygen.map { Fmt.date($0.createdAt, format: "MMM d, h:mm a") }
                        ?? "Log blood oxygen level\nto see it here",
                      button: "Log Oxygen") { showOxygenLog = true }

            vitalsRow(title: "Glucose", icon: "drop.fill", color: AppColor.teal,
                      value: glucose.map { glucoseDisplay($0.value) } ?? "No Data",
                      unit: GlucoseUnit.current.rawValue,
                      subtitle: glucose.map { Fmt.date($0.createdAt, format: "MMM d, h:mm a") }
                        ?? "Log blood sugar level\nto see it here",
                      button: "Log Glucose") { showGlucoseLog = true }
        }
    }

    private func vitalsRow(title: String, icon: String, color: Color, value: String, unit: String,
                           subtitle: String, button: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(color.opacity(0.12)))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColor.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(AppColor.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(AppColor.textPrimary)
                    if value != "No Data" {
                        Text(unit)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppColor.textSecondary)
                    }
                }
                Button(button, action: action)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
            }
        }
        .card(padding: 14, radius: 18)
    }

    private func glucoseDisplay(_ mgdl: Double) -> String {
        let unit = GlucoseUnit.current
        return unit == .mgdL ? "\(Int(mgdl.rounded()))" : String(format: "%.1f", unit.displayValue(mgdl: mgdl))
    }

    // MARK: Journey level

    private var levelCard: some View {
        NavigationLink {
            JourneyView()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(AppColor.brandSoft).frame(width: 44, height: 44)
                    Image(systemName: "flag.fill")
                        .foregroundColor(AppColor.brand)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Level \(JourneyService.shared.currentLevel.id)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColor.textPrimary)
                    Text(JourneyService.shared.currentLevel.title)
                        .font(.system(size: 13))
                        .foregroundColor(AppColor.textSecondary)
                }
                Spacer()
                ProgressView(value: JourneyService.shared.currentLevelProgress)
                    .tint(AppColor.brand)
                    .frame(width: 64)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColor.textSecondary)
            }
            .card(padding: 14, radius: 18)
        }
        .buttonStyle(PressableCardStyle())
    }

    // MARK: Measurements

    private var measurementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Measurements", actionTitle: "History") {
                // Navigation handled by the History link below.
            }
            .overlay(alignment: .trailing) {
                NavigationLink {
                    HistoryView()
                } label: {
                    Text("History")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColor.brand)
                }
            }

            if measurements.isEmpty {
                EmptyStateView(icon: "heart.text.square",
                               title: "No Data",
                               message: "Take a measurement to see it here")
                    .card()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(measurements.prefix(5).enumerated()), id: \.element.id) { index, measurement in
                        NavigationLink {
                            MeasurementDetailView(measurementID: measurement.id)
                        } label: {
                            measurementRow(measurement)
                        }
                        .buttonStyle(.plain)
                        if index < min(4, measurements.count - 1) {
                            Divider().padding(.leading, 46)
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous).fill(AppColor.surface)
                )
            }
        }
    }

    private func measurementRow(_ measurement: HRMeasurement) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(AppColor.brandSoft).frame(width: 34, height: 34)
                Image(systemName: "heart.fill")
                    .font(.system(size: 13))
                    .foregroundColor(AppColor.brand)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(measurement.pulse)) bpm")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColor.textPrimary)
                Text("\(Fmt.date(measurement.time, format: "MMM d")) · \(Fmt.time(measurement.time))")
                    .font(.system(size: 11))
                    .foregroundColor(AppColor.textSecondary)
            }
            Spacer()
            if let tag = TagResolver.title(for: measurement.tagId) {
                Text(tag)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppColor.surfaceAlt))
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppColor.textSecondary.opacity(0.6))
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// MARK: - Sparkline

struct Sparkline: Shape {
    let values: [Double]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard values.count > 1 else { return path }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        let range = max(maxValue - minValue, 1)
        for (index, value) in values.enumerated() {
            let x = rect.width * CGFloat(index) / CGFloat(values.count - 1)
            let y = rect.height - rect.height * CGFloat((value - minValue) / range)
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}
