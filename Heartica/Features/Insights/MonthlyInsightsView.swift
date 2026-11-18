import Charts
import SwiftUI

enum MonthlyMetric: String, CaseIterable, Identifiable {
    case healthIndex, energy, stress, pulse, hrv, sdnn, rmssd, pnn50, stressIndex
    case pressureSystolic, pressureDiastolic, bloodOxygen, glucoseBeforeMeal, glucoseAfterMeal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .healthIndex: return L("Health Index")
        case .energy: return L("Energy")
        case .stress: return L("Stress")
        case .pulse: return L("Pulse")
        case .hrv: return L("HRV")
        case .sdnn: return L("SDNN")
        case .rmssd: return L("RMSSD")
        case .pnn50: return L("pNN50")
        case .stressIndex: return L("Stress Index")
        case .pressureSystolic: return L("Pressure SYS")
        case .pressureDiastolic: return L("Pressure DIA")
        case .bloodOxygen: return L("Blood Oxygen")
        case .glucoseBeforeMeal: return L("Glucose Before Meal")
        case .glucoseAfterMeal: return L("Glucose After Meal")
        }
    }

    var unit: String {
        switch self {
        case .healthIndex: return ""
        case .pulse: return L("bpm")
        case .pressureSystolic, .pressureDiastolic: return "mmHg"
        case .bloodOxygen: return "%"
        case .glucoseBeforeMeal, .glucoseAfterMeal: return GlucoseUnit.current.rawValue
        case .stressIndex: return "SI"
        default: return "ms"
        }
    }
}

struct MonthlyInsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var dataStore: HealthDataStore

    @State private var month = Date()
    @State private var metric: MonthlyMetric = .healthIndex
    @State private var selectedDay: Date?

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    monthHeader
                    metricPicker
                    if appState.isPremium {
                        calendarGrid
                        if let selectedDay {
                            dayCard(selectedDay)
                        }
                        chartCard
                    } else {
                        lockedView
                    }
                }
                .padding(18)
            }
            .screenBackground()
            .navigationTitle("Monthly Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                month = calendar.date(byAdding: .month, value: -1, to: month) ?? month
                selectedDay = nil
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(AppColor.surface))
            }
            Spacer()
            Text(Fmt.date(month, format: "MMMM yyyy"))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppColor.textPrimary)
            Spacer()
            Button {
                if canGoForward {
                    month = calendar.date(byAdding: .month, value: 1, to: month) ?? month
                    selectedDay = nil
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(AppColor.surface))
                    .opacity(canGoForward ? 1 : 0.35)
            }
            .disabled(!canGoForward)
        }
    }

    private var canGoForward: Bool {
        !calendar.isDate(month, equalTo: Date(), toGranularity: .month)
    }

    private var metricPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MonthlyMetric.allCases) { item in
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) { metric = item }
                    } label: {
                        Text(item.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(metric == item ? .white : AppColor.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(metric == item ? AppColor.purple : AppColor.surface))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var calendarGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppColor.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                    if let date = cell.date {
                        dayCell(date)
                    } else {
                        Color.clear.frame(height: 38)
                    }
                }
            }
        }
        .card()
    }

    private func dayCell(_ date: Date) -> some View {
        let value = dailyValue(date)
        let isFuture = date > Date()
        let selected = selectedDay.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        return Button {
            selectedDay = date
        } label: {
            ZStack {
                Circle()
                    .fill(fillColor(value: value, isFuture: isFuture))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Circle().stroke(selected ? AppColor.textPrimary : .clear, lineWidth: 1.5)
                    )
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(value == nil || isFuture ? AppColor.textSecondary : .white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 38)
        }
        .buttonStyle(.plain)
    }

    private func fillColor(value: Double?, isFuture: Bool) -> Color {
        if isFuture { return AppColor.surfaceAlt.opacity(0.4) }
        guard let value else { return AppColor.surfaceAlt }
        return statusColor(for: value)
    }

    private func dayCard(_ date: Date) -> some View {
        let value = dailyValue(date)
        return VStack(alignment: .leading, spacing: 8) {
            Text(Fmt.date(date, format: "EEEE, MMM d"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColor.textSecondary)
            if let value {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(format(value))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(AppColor.textPrimary)
                    if !metric.unit.isEmpty {
                        Text(metric.unit)
                            .font(.system(size: 11))
                            .foregroundColor(AppColor.textSecondary)
                    }
                    Spacer()
                    Text(metric.title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColor.textSecondary)
                }
            } else {
                Text("No Data")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColor.textSecondary)
            }
        }
        .card(padding: 16)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Day Average")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColor.textPrimary)
            if monthValues.isEmpty {
                Text(L("Take measurements to see your stats"))
                    .font(.system(size: 12))
                    .foregroundColor(AppColor.textSecondary)
                    .padding(.vertical, 30)
            } else {
                Chart(monthValues, id: \.date) { point in
                    BarMark(x: .value("Day", point.date, unit: .day),
                            y: .value(metric.title, point.value))
                    .foregroundStyle(AppColor.purple.opacity(0.8))
                    .cornerRadius(3)
                }
                .frame(height: 150)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                        AxisValueLabel(format: .dateTime.day())
                    }
                }
            }
        }
        .card()
    }

    private var lockedView: some View {
        VStack(spacing: 16) {
            ZStack {
                Image(systemName: "calendar")
                    .font(.system(size: 70, weight: .light))
                    .foregroundColor(AppColor.purple.opacity(0.35))
                    .blur(radius: 1)
                Image(systemName: "lock.fill")
                    .font(.system(size: 26))
                    .foregroundColor(AppColor.purple)
                    .padding(16)
                    .background(Circle().fill(AppColor.surface))
            }
            Text(L("Monthly Insights"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColor.textPrimary)
            Text(L("Unlock Premium to see full trends"))
                .font(.system(size: 14))
                .foregroundColor(AppColor.textSecondary)
            Button {
                appState.presentPaywall(source: "insights")
            } label: {
                Text(L("Unlock"))
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .card()
    }

    // MARK: Data

    private struct Cell {
        let date: Date?
    }

    private var cells: [Cell] {
        let monthStart = DateRange.startOfMonth(month)
        let range = calendar.range(of: .day, in: .month, for: monthStart) ?? 1..<31
        let weekday = calendar.component(.weekday, from: monthStart)
        let leading = weekday - 1
        var result: [Cell] = Array(repeating: Cell(date: nil), count: leading)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                result.append(Cell(date: date))
            }
        }
        return result
    }

    private var monthValues: [(date: Date, value: Double)] {
        let days = cells.compactMap(\.date)
        return days.compactMap { date in
            guard let value = dailyValue(date) else { return nil }
            return (date, value)
        }
    }

    private func dailyValue(_ date: Date) -> Double? {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
        guard dayStart <= Date() else { return nil }
        switch metric {
        case .healthIndex, .energy, .stress, .pulse, .hrv, .sdnn, .rmssd, .pnn50, .stressIndex:
            let items = dataStore.measurements(from: dayStart, to: dayEnd)
            let values: [Double] = items.map { measurement in
                switch metric {
                case .healthIndex: return measurement.healthIndex
                case .energy: return measurement.energy
                case .stress: return measurement.stress
                case .pulse: return measurement.pulse
                case .hrv, .sdnn: return measurement.sdnn
                case .rmssd: return measurement.rmssd
                case .pnn50: return measurement.pnn50
                case .stressIndex: return measurement.csi
                default: return 0
                }
            }
            return average(values)
        case .pressureSystolic, .pressureDiastolic:
            let records = dataStore.pressureRecords().filter { $0.createdAt >= dayStart && $0.createdAt < dayEnd }
            return average(records.map { metric == .pressureSystolic ? Double($0.sys) : Double($0.dia) })
        case .bloodOxygen:
            let records = dataStore.oxygenRecords().filter { $0.createdAt >= dayStart && $0.createdAt < dayEnd }
            return average(records.map { Double($0.value) })
        case .glucoseBeforeMeal, .glucoseAfterMeal:
            let tag = metric == .glucoseBeforeMeal ? "eating-before" : "eating-after"
            let records = dataStore.glucoseRecords().filter {
                $0.createdAt >= dayStart && $0.createdAt < dayEnd && $0.tagId == tag
            }
            let display = records.map { GlucoseUnit.current.displayValue(mgdl: $0.value) }
            return average(display)
        }
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func format(_ value: Double) -> String {
        switch metric {
        case .healthIndex: return String(format: "%.1f", value)
        case .glucoseBeforeMeal, .glucoseAfterMeal:
            return GlucoseUnit.current == .mgdL ? "\(Int(value.rounded()))" : String(format: "%.1f", value)
        default: return String(format: "%.0f", value)
        }
    }

    private func statusColor(for value: Double) -> Color {
        switch metric {
        case .pressureSystolic:
            return color(VitalsStatus.pressure(sys: Int(value)).color)
        case .pressureDiastolic:
            switch value {
            case ..<60: return AppColor.blue
            case 60..<80: return AppColor.success
            case 80..<90: return AppColor.warning
            case 90..<100: return AppColor.orange
            default: return AppColor.danger
            }
        case .bloodOxygen:
            return color(VitalsStatus.oxygen(Int(value)).color)
        case .glucoseBeforeMeal, .glucoseAfterMeal:
            let mgdl = GlucoseUnit.current == .mgdL ? value : value * 18
            return color(VitalsStatus.glucose(mgdl: mgdl, afterMeal: metric == .glucoseAfterMeal).color)
        case .pulse:
            return color(MetricCatalog.pulseStatus(value).color)
        case .stress:
            return color(MetricCatalog.stressStatus(value).color)
        case .stressIndex:
            return color(MetricCatalog.csiStatus(value).color)
        case .rmssd:
            return color(MetricCatalog.rmssdStatus(value).color)
        case .pnn50:
            return color(MetricCatalog.pnn50Status(value).color)
        case .healthIndex:
            return color(MetricCatalog.healthIndexStatus(value).color)
        case .energy:
            return color(MetricCatalog.energyStatus(value).color)
        case .hrv, .sdnn:
            return color(MetricCatalog.hrvStatus(value).color)
        }
    }

    private func color(_ name: String) -> Color {
        switch name {
        case "green": return AppColor.success
        case "yellow": return AppColor.warning
        case "orange": return AppColor.orange
        case "red": return AppColor.danger
        case "blue": return AppColor.blue
        default: return AppColor.textSecondary
        }
    }
}
