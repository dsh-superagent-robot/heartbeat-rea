import Combine
import SwiftUI

enum ResultMetric: String, CaseIterable, Identifiable {
    case pulse, healthIndex, energy, stress, hrv, sdnn, rmssd, pnn50

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pulse: return L("Pulse")
        case .healthIndex: return L("Health Index")
        case .energy: return L("Energy")
        case .stress: return L("Stress")
        case .hrv: return "HRV"
        case .sdnn: return "SDNN"
        case .rmssd: return "RMSSD"
        case .pnn50: return "pNN50"
        }
    }

    var unit: String {
        switch self {
        case .pulse: return L("bpm")
        case .rmssd, .sdnn, .hrv: return "ms"
        case .pnn50, .stress, .energy: return "%"
        case .healthIndex: return ""
        }
    }

    func value(from measurement: HRMeasurement) -> Double {
        switch self {
        case .pulse: return measurement.pulse
        case .healthIndex: return measurement.healthIndex
        case .energy: return measurement.energy
        case .stress: return measurement.stress
        case .hrv: return measurement.hrv
        case .sdnn: return measurement.sdnn
        case .rmssd: return measurement.rmssd
        case .pnn50: return measurement.pnn50
        }
    }

    func status(for value: Double) -> MetricStatus {
        switch self {
        case .pulse: return MetricCatalog.pulseStatus(value)
        case .healthIndex: return MetricCatalog.healthIndexStatus(value)
        case .energy: return MetricCatalog.energyStatus(value)
        case .stress: return MetricCatalog.stressStatus(value)
        case .hrv, .sdnn: return MetricCatalog.hrvStatus(value)
        case .rmssd: return MetricCatalog.rmssdStatus(value)
        case .pnn50: return MetricCatalog.pnn50Status(value)
        }
    }

    var formattedValue: (HRMeasurement) -> String {
        { measurement in
            let value = self.value(from: measurement)
            switch self {
            case .healthIndex: return String(format: "%.1f", value)
            case .pnn50: return String(format: "%.0f", value)
            default: return String(format: "%.0f", value)
            }
        }
    }

    var description: String {
        switch self {
        case .pulse:
            return "Pulse is the number of times your heart beats per minute (bpm). A normal resting heart rate for adults is typically between 60 and 100 bpm."
        case .healthIndex:
            return "Health Index combines your heart rate variability and pulse into a single 0–10 recovery score. Higher values suggest your body is well recovered."
        case .energy:
            return "Energy estimates how much recovery capacity you have, scaled from 0 to 120. It rises with higher heart rate variability."
        case .stress:
            return "Stress estimates your current allostatic load from 0 to 100. Lower values mean a more relaxed state; higher values suggest tension."
        case .hrv:
            return "Heart Rate Variability (HRV) is the variation between consecutive heartbeats. It is a useful marker of recovery and stress."
        case .sdnn:
            return "SDNN is the standard deviation of your NN intervals. It reflects overall variability across the measurement."
        case .rmssd:
            return "RMSSD is the root mean square of successive differences between NN intervals. It is the primary short-term HRV metric."
        case .pnn50:
            return "pNN50 is the percentage of consecutive NN interval pairs that differ by more than 50 ms. It reflects parasympathetic activity."
        }
    }
}

struct MeasureResultView: View {
    let measurement: HRMeasurement
    let onContinue: () -> Void
    let onRetake: () -> Void
    let onDelete: () -> Void
    let onTag: () -> Void
    let onMetricInfo: (ResultMetric) -> Void

    @State private var commentExpanded = false
    @State private var showTrends = false

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    healthStateCard
                    aiCommentCard
                    tagCard
                    metricsGrid
                    actions
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
        .sheet(isPresented: $showTrends) {
            TrendsSheet(highlighted: measurement)
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            VStack(spacing: 2) {
                Text("Measurement")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Text("Measurement Details")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
        }
        .overlay(alignment: .trailing) {
            Button {
                showTrends = true
            } label: {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
    }

    private var healthStateCard: some View {
        let status = MetricCatalog.healthIndexStatus(measurement.healthIndex)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Overall Health State")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                StatusBadge(text: status.displayStatus, color: statusColor(status.color))
            }
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 8)
                        .frame(width: 78, height: 78)
                    Circle()
                        .trim(from: 0, to: clamp(measurement.healthIndex / 10, 0.02, 1))
                        .stroke(statusColor(status.color), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 78, height: 78)
                        .rotationEffect(.degrees(-90))
                    Text(String(format: "%.1f", measurement.healthIndex))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(status.indicator)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(LF("Current State · %@", status.range))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.55))
                }
                Spacer()
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [Color.white.opacity(0.14), Color.white.opacity(0.07)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.10), lineWidth: 1))
        )
    }

    private var aiCommentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(AppColor.warning)
                Text("AI Comment")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("AI")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.1)))
            }
            Text(insightText)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.75))
                .lineSpacing(3)
                .lineLimit(commentExpanded ? nil : 3)
            Button(L(commentExpanded ? "Show Less" : "Read More")) {
                withAnimation { commentExpanded.toggle() }
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(AppColor.brand)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white.opacity(0.07)))
    }

    private var insightText: String {
        let pulseStatus = MetricCatalog.pulseStatus(measurement.pulse)
        let stressStatus = MetricCatalog.stressStatus(measurement.stress)
        let hrvStatus = MetricCatalog.rmssdStatus(measurement.rmssd)
        let pulsePhrase: String
        switch pulseStatus.status {
        case "normal": pulsePhrase = L("within the normal resting range")
        case "low": pulsePhrase = L("below the typical resting range")
        case "high", "veryHigh": pulsePhrase = L("above the typical resting range")
        default: pulsePhrase = L("within the typical range")
        }
        let stressPhrase: String
        switch stressStatus.status {
        case "relaxed", "low": stressPhrase = L("is quite relaxed")
        case "average": stressPhrase = L("is mildly calm")
        case "high", "veryHigh": stressPhrase = L("is elevated")
        default: stressPhrase = L("is balanced")
        }
        return LF("Your heart rate of %d bpm is %@. Your stress level %@, while your HRV suggests %@. Keep measuring at similar times each day to make trends easier to compare.",
                  Int(measurement.pulse), pulsePhrase, stressPhrase, hrvStatus.indicator.lowercased())
    }

    private var tagCard: some View {
        Button(action: onTag) {
            HStack(spacing: 12) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColor.brand)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(AppColor.brand.opacity(0.14)))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tag")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text(TagResolver.title(for: measurement.tagId) ?? L("Add a Tag"))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.55))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white.opacity(0.07)))
        }
        .buttonStyle(.plain)
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(ResultMetric.allCases) { metric in
                metricCard(metric)
            }
        }
    }

    private func metricCard(_ metric: ResultMetric) -> some View {
        let value = metric.value(from: measurement)
        let status = metric.status(for: value)
        let color = statusColor(status.color)
        return Button {
            onMetricInfo(metric)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text(metric.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.3))
                    Spacer()
                }
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(metric.formattedValue(measurement))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    if !metric.unit.isEmpty {
                        Text(metric.unit)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.45))
                    }
                }
                HStack(spacing: 4) {
                    Circle().fill(color).frame(width: 5, height: 5)
                    Text(status.indicator)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 3)
                    .overlay(alignment: .leading) {
                        Capsule().fill(color).frame(width: 34, height: 3)
                    }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white.opacity(0.07)))
        }
        .buttonStyle(PressableCardStyle())
    }

    private var actions: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: onRetake) {
                    Label("Retake", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Capsule().fill(Color.white.opacity(0.10)))
                }
                .buttonStyle(.plain)
                Button(action: onDelete) {
                    Label("Delete", systemImage: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColor.danger)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Capsule().fill(AppColor.danger.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
            Button(action: onContinue) {
                Text("Continue")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.top, 6)
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

struct MetricInfoSheet: View {
    let metric: ResultMetric
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(AppColor.brand)
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(AppColor.brandSoft))
                    Text(metric.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                }
                Text(L(metric.description))
                    .font(.system(size: 15))
                    .foregroundColor(AppColor.textPrimary)
                    .lineSpacing(4)
                Text("This information is educational and is not medical advice.")
                    .font(.system(size: 12))
                    .foregroundColor(AppColor.textSecondary)
                Spacer()
            }
            .padding(22)
            .screenBackground()
            .navigationTitle("Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Trends

struct TrendsSheet: View {
    let highlighted: HRMeasurement
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataStore: HealthDataStore
    @State private var metric: ResultMetric = .pulse

    private var history: [HRMeasurement] {
        dataStore.measurements(from: DateRange.monthsAgo(1), to: Date()).reversed()
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 18) {
                Picker("Metric", selection: $metric) {
                    ForEach([ResultMetric.pulse, .hrv, .stress, .energy, .healthIndex]) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                if history.count > 1 {
                    TrendChart(measurements: history, metric: metric)
                        .frame(height: 240)
                } else {
                    EmptyStateView(icon: "chart.xyaxis.line", title: "No Data",
                                   message: "Take more measurements to see your trends")
                        .card()
                }

                Text("Trends use all your measurements from the last 30 days.")
                    .font(.system(size: 12))
                    .foregroundColor(AppColor.textSecondary)
                Spacer()
            }
            .padding(20)
            .screenBackground()
            .navigationTitle("Trends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
