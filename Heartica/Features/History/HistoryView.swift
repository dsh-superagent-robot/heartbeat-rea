import SwiftUI

enum HistoryLog: Identifiable {
    case heart(HRMeasurement)
    case pressure(PressureRecord)
    case oxygen(OxygenRecord)
    case glucose(GlucoseRecord)

    var id: String {
        switch self {
        case .heart(let item): return "h-\(item.id)"
        case .pressure(let item): return "p-\(item.id)"
        case .oxygen(let item): return "o-\(item.id)"
        case .glucose(let item): return "g-\(item.id)"
        }
    }

    var time: Date {
        switch self {
        case .heart(let item): return item.time
        case .pressure(let item): return item.createdAt
        case .oxygen(let item): return item.createdAt
        case .glucose(let item): return item.createdAt
        }
    }

    var tagId: String? {
        switch self {
        case .heart(let item): return item.tagId
        case .pressure(let item): return item.tagId
        case .oxygen(let item): return item.tagId
        case .glucose(let item): return item.tagId
        }
    }
}

struct HistoryDay: Identifiable {
    let id: Date
    let date: Date
    var logs: [HistoryLog]
}

struct HistoryView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var dataStore: HealthDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var month: Date = Date()
    @State private var showAddMenu = false
    @State private var isEditing = false
    @State private var showPressureLog = false
    @State private var showOxygenLog = false
    @State private var showGlucoseLog = false
    @State private var showManualPulse = false
    @State private var filterTagId: String?
    @State private var showFilter = false
    @State private var deleteTarget: HistoryLog?
    @State private var selectedVitals: HistoryLog?

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                monthSwitcher
                filterRow
                if days.isEmpty {
                    emptyState
                } else {
                    ForEach(days) { day in
                        dayCard(day)
                    }
                }
                addButton
            }
            .padding(.horizontal, 18)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .screenBackground()
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Done" : "Edit") { isEditing.toggle() }
                    .font(.system(size: 15, weight: .semibold))
            }
        }
        .confirmationDialog("Add a Measurement", isPresented: $showAddMenu, titleVisibility: .visible) {
            Button("Measure Heart Rate") {
                appState.autoPresentMeasure = true
                dismiss()
            }
            Button("Log Pressure") { showPressureLog = true }
            Button("Log Oxygen") { showOxygenLog = true }
            Button("Log Glucose") { showGlucoseLog = true }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showPressureLog) {
            ManualVitalsView(kind: .pressure)
                .environmentObject(appState).environmentObject(dataStore)
        }
        .sheet(isPresented: $showOxygenLog) {
            ManualVitalsView(kind: .oxygen)
                .environmentObject(appState).environmentObject(dataStore)
        }
        .sheet(isPresented: $showGlucoseLog) {
            ManualVitalsView(kind: .glucose)
                .environmentObject(appState).environmentObject(dataStore)
        }
        .sheet(isPresented: $showFilter) {
            TagFilterView(selected: $filterTagId)
                .environmentObject(dataStore)
        }
        .sheet(item: $selectedVitals) { log in
            VitalsDetailView(log: log)
                .environmentObject(dataStore)
        }
        .confirmationDialog("Are you sure you want to delete this measurement?",
                            isPresented: Binding(get: { deleteTarget != nil },
                                                 set: { if !$0 { deleteTarget = nil } }),
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let target = deleteTarget { delete(target) }
                deleteTarget = nil
            }
            Button("Cancel", role: .cancel) { deleteTarget = nil }
        }
    }

    private var monthSwitcher: some View {
        HStack {
            Button {
                shiftMonth(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColor.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(AppColor.surface))
            }
            Spacer()
            Text(Fmt.date(month, format: "MMMM yyyy"))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppColor.textPrimary)
            Spacer()
            Button {
                shiftMonth(1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(canGoForward ? AppColor.textPrimary : AppColor.textSecondary.opacity(0.4))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(AppColor.surface))
            }
            .disabled(!canGoForward)
        }
    }

    private var filterRow: some View {
        HStack(spacing: 8) {
            Button {
                showFilter = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease")
                    Text(filterTitle)
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(filterTagId == nil ? AppColor.textPrimary : AppColor.brand)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Capsule().fill(filterTagId == nil ? AppColor.surface : AppColor.brandSoft))
            }
            .buttonStyle(.plain)
            if filterTagId != nil {
                Button("Clear") { filterTagId = nil }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColor.textSecondary)
            }
            Spacer()
        }
    }

    private var filterTitle: String {
        guard let filterTagId else { return "Filter" }
        if filterTagId.isEmpty { return "No Tag" }
        return TagResolver.title(for: filterTagId) ?? "Filter"
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            EmptyStateView(icon: "calendar.badge.plus", title: "No Records Yet",
                           message: "Start by adding your \nfirst measurement.")
            Button("Add a Measurement") { showAddMenu = true }
                .buttonStyle(PrimaryButtonStyle())
        }
        .card()
        .padding(.top, 20)
    }

    private var addButton: some View {
        Button {
            showAddMenu = true
        } label: {
            Label("Add a Measurement", systemImage: "plus")
        }
        .buttonStyle(SecondaryButtonStyle())
        .padding(.top, 6)
    }

    private func dayCard(_ day: HistoryDay) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(dayTitle(day.date))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColor.textSecondary)
                Spacer()
                if isEditing {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 6)

            ForEach(Array(day.logs.enumerated()), id: \.element.id) { index, log in
                logRow(log)
                if index < day.logs.count - 1 {
                    Divider().padding(.leading, 58)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(AppColor.surface))
    }

    @ViewBuilder
    private func logRow(_ log: HistoryLog) -> some View {
        if case .heart(let measurement) = log {
            NavigationLink {
                MeasurementDetailView(measurementID: measurement.id)
            } label: {
                rowBody(log)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                guard !isEditing else { return }
                selectedVitals = log
            } label: {
                rowBody(log)
            }
            .buttonStyle(.plain)
        }
    }

    private func rowBody(_ log: HistoryLog) -> some View {
        let content = logContent(log)
        return HStack(spacing: 12) {
            ZStack {
                Circle().fill(content.color.opacity(0.12)).frame(width: 34, height: 34)
                Image(systemName: content.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(content.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(content.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColor.textPrimary)
                HStack(spacing: 6) {
                    Text(content.value)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColor.textSecondary)
                    if let tag = TagResolver.title(for: log.tagId) {
                        Text(tag)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppColor.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(AppColor.surfaceAlt))
                    }
                }
            }
            Spacer()
            if isEditing {
                Button {
                    deleteTarget = log
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColor.danger)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            } else {
                Text(content.status)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(content.statusColor)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppColor.textSecondary.opacity(0.5))
            }
        }
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Delete", role: .destructive) { deleteTarget = log }
        }
    }

    // MARK: Content

    private struct LogContent {
        let icon: String
        let color: Color
        let title: String
        let value: String
        let status: String
        let statusColor: Color
    }

    private func logContent(_ log: HistoryLog) -> LogContent {
        switch log {
        case .heart(let measurement):
            let band = MetricCatalog.healthIndexStatus(measurement.healthIndex)
            return LogContent(icon: "heart.fill", color: AppColor.brand,
                              title: "\(Fmt.time(measurement.time)) - Health Index",
                              value: "\(Int(measurement.pulse)) bpm",
                              status: band.displayStatus,
                              statusColor: color(band.color))
        case .pressure(let record):
            let band = VitalsStatus.pressure(sys: record.sys)
            return LogContent(icon: "waveform.path.ecg", color: AppColor.brand,
                              title: "\(Fmt.time(record.createdAt)) - Blood Pressure",
                              value: "\(record.sys)/\(record.dia) mmHg",
                              status: band.title,
                              statusColor: color(band.color))
        case .oxygen(let record):
            let band = VitalsStatus.oxygen(record.value)
            return LogContent(icon: "lungs.fill", color: AppColor.blue,
                              title: "\(Fmt.time(record.createdAt)) - Blood Oxygen",
                              value: "\(record.value)%",
                              status: band.title,
                              statusColor: color(band.color))
        case .glucose(let record):
            let unit = GlucoseUnit.current
            return LogContent(icon: "drop.fill", color: AppColor.teal,
                              title: "\(Fmt.time(record.createdAt)) - Blood Sugar",
                              value: unit.formatted(mgdl: record.value),
                              status: "",
                              statusColor: AppColor.textSecondary)
        }
    }

    // MARK: Data

    private var filteredLogs: [HistoryLog] {
        let calendar = Calendar.current
        var logs: [HistoryLog] = []
        func matches(_ tagId: String?) -> Bool {
            guard let filterTagId else { return true }
            if filterTagId.isEmpty { return tagId == nil }
            return tagId == filterTagId
        }
        for measurement in dataStore.measurements() where matches(measurement.tagId) {
            logs.append(.heart(measurement))
        }
        for record in dataStore.pressureRecords() where matches(record.tagId) {
            logs.append(.pressure(record))
        }
        for record in dataStore.oxygenRecords() where matches(record.tagId) {
            logs.append(.oxygen(record))
        }
        for record in dataStore.glucoseRecords() where matches(record.tagId) {
            logs.append(.glucose(record))
        }
        let monthComponents = calendar.dateComponents([.year, .month], from: month)
        return logs.filter {
            let components = calendar.dateComponents([.year, .month], from: $0.time)
            return components.year == monthComponents.year && components.month == monthComponents.month
        }
    }

    private var days: [HistoryDay] {
        let calendar = Calendar.current
        var grouped: [Date: [HistoryLog]] = [:]
        for log in filteredLogs {
            grouped[calendar.startOfDay(for: log.time), default: []].append(log)
        }
        return grouped.keys.sorted(by: >).map { day in
            HistoryDay(id: day, date: day, logs: (grouped[day] ?? []).sorted { $0.time > $1.time })
        }
    }

    private var canGoForward: Bool {
        let current = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        return month < current
    }

    private func shiftMonth(_ value: Int) {
        if let next = calendar.date(byAdding: .month, value: value, to: month) {
            withAnimation(.easeOut(duration: 0.2)) { month = next }
        }
    }

    private func dayTitle(_ date: Date) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return Fmt.date(date, format: "EEEE, MMM d")
    }

    private func delete(_ log: HistoryLog) {
        switch log {
        case .heart(let measurement): dataStore.deleteMeasurement(id: measurement.id)
        case .pressure(let record): dataStore.deletePressure(id: record.id)
        case .oxygen(let record): dataStore.deleteOxygen(id: record.id)
        case .glucose(let record): dataStore.deleteGlucose(id: record.id)
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

// MARK: - Tag filter

struct TagFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataStore: HealthDataStore
    @Binding var selected: String?

    var body: some View {
        NavigationView {
            List {
                Section {
                    row(title: "All Data", id: nil)
                    row(title: "No Tag", id: "__no_tag__")
                }
                Section("Tags") {
                    ForEach(PresetTag.all) { tag in
                        row(title: tag.title, id: tag.id)
                    }
                    ForEach(dataStore.customTags()) { tag in
                        row(title: tag.name, id: tag.id)
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func row(title: String, id: String?) -> some View {
        let isSelected = id == "__no_tag__" ? selected == "" : selected == id
        return Button {
            selected = id == "__no_tag__" ? "" : id
            dismiss()
        } label: {
            HStack {
                Text(title).foregroundColor(AppColor.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark").foregroundColor(AppColor.brand)
                }
            }
        }
    }
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
