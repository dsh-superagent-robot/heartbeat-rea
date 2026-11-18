import SwiftUI

enum GlucoseUnit: String, CaseIterable, Identifiable {
    case mmolL = "mmol/L"
    case mgdL = "mg/dL"

    var id: String { rawValue }

    static var current: GlucoseUnit {
        if let raw = UserDefaults.standard.string(forKey: UDKey.glucoseUnit),
           let unit = GlucoseUnit(rawValue: raw) {
            return unit
        }
        return Locale.current.measurementSystem == .us ? .mgdL : .mmolL
    }

    static func setCurrent(_ unit: GlucoseUnit) {
        UserDefaults.standard.set(unit.rawValue, forKey: UDKey.glucoseUnit)
    }

    func displayValue(mgdl: Double) -> Double {
        switch self {
        case .mgdL: return mgdl
        case .mmolL: return (mgdl / 18.0 * 10).rounded() / 10
        }
    }

    func mgdlValue(display: Double) -> Double {
        switch self {
        case .mgdL: return display
        case .mmolL: return display * 18.0
        }
    }

    func formatted(mgdl: Double) -> String {
        switch self {
        case .mgdL: return "\(Int(displayValue(mgdl: mgdl).rounded())) mg/dl"
        case .mmolL: return String(format: "%.1f mmol/L", displayValue(mgdl: mgdl))
        }
    }
}

enum VitalsStatus {
    struct Band {
        let title: String
        let color: String
        let interpretation: String
    }

    static func pressure(sys: Int) -> Band {
        switch sys {
        case ..<90: return Band(title: "Low", color: "blue", interpretation: "Hypotension")
        case 90..<120: return Band(title: "Normal", color: "green", interpretation: "Healthy level")
        case 120..<130: return Band(title: "Elevated", color: "yellow", interpretation: "Elevated blood pressure")
        case 130..<140: return Band(title: "High", color: "orange", interpretation: "Stage 1 Hypertension")
        default: return Band(title: "Very High", color: "red", interpretation: "Stage 2 Hypertension")
        }
    }

    static func oxygen(_ value: Int) -> Band {
        switch value {
        case ..<90: return Band(title: "Very Low", color: "red", interpretation: "Requires medical care")
        case 90..<96: return Band(title: "Low", color: "orange", interpretation: "Risk of hypoxemia")
        default: return Band(title: "Normal", color: "green", interpretation: "Normal oxygen level")
        }
    }

    static func glucose(mgdl: Double, afterMeal: Bool) -> Band {
        if afterMeal {
            switch mgdl {
            case 200...: return Band(title: "High", color: "red", interpretation: "Possible diabetes range")
            case 140..<200: return Band(title: "Elevated", color: "yellow", interpretation: "Prediabetes range")
            default: return Band(title: "Normal", color: "green", interpretation: "Healthy post-meal level")
            }
        } else {
            switch mgdl {
            case 126...: return Band(title: "High", color: "red", interpretation: "Possible diabetes range")
            case 100..<126: return Band(title: "Elevated", color: "yellow", interpretation: "Prediabetes range")
            case 70..<100: return Band(title: "Normal", color: "green", interpretation: "Healthy fasting level")
            default: return Band(title: "Low", color: "blue", interpretation: "Low blood sugar")
            }
        }
    }
}

enum VitalsKind: String, Identifiable {
    case pressure, oxygen, glucose
    var id: String { rawValue }

    var title: String {
        switch self {
        case .pressure: return "Blood Pressure"
        case .oxygen: return "Blood Oxygen"
        case .glucose: return "Blood Sugar"
        }
    }

    var button: String {
        switch self {
        case .pressure: return "Log Blood Pressure"
        case .oxygen: return "Log Oxygen"
        case .glucose: return "Log Sugar"
        }
    }

    var icon: String {
        switch self {
        case .pressure: return "waveform.path.ecg"
        case .oxygen: return "lungs.fill"
        case .glucose: return "drop.fill"
        }
    }

    var color: Color {
        switch self {
        case .pressure: return AppColor.brand
        case .oxygen: return AppColor.blue
        case .glucose: return AppColor.teal
        }
    }
}

struct ManualVitalsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var dataStore: HealthDataStore

    let kind: VitalsKind

    @State private var sys = 120
    @State private var dia = 80
    @State private var oxygen = 98
    @State private var glucoseUnit: GlucoseUnit = GlucoseUnit.current
    @State private var glucoseMmol = 5.0
    @State private var glucoseMg = 90.0
    @State private var time = Date()
    @State private var tagId: String?
    @State private var showTagPicker = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    valuePicker
                    statusCard
                    detailRows
                    Button(kind.button) { save() }
                        .buttonStyle(PrimaryButtonStyle())
                }
                .padding(20)
            }
            .screenBackground()
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showTagPicker) {
                TagPickerView(selectedTagId: tagId) { selected in
                    tagId = selected
                }
                .environmentObject(dataStore)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: kind.icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(kind.color)
                .frame(width: 50, height: 50)
                .background(Circle().fill(kind.color.opacity(0.12)))
            VStack(alignment: .leading, spacing: 3) {
                Text(kind.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppColor.textPrimary)
                Text(status.interpretation)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(statusColor)
            }
            Spacer()
            StatusBadge(text: status.title, color: statusColor)
        }
        .card()
    }

    private var valuePicker: some View {
        VStack(spacing: 8) {
            switch kind {
            case .pressure:
                HStack(spacing: 0) {
                    wheelColumn(title: "Systolic") {
                        Picker("Systolic", selection: $sys) {
                            ForEach(40...220, id: \.self) { value in
                                Text("\(value)").tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 130)
                        .clipped()
                    }
                    Text("/")
                        .font(.system(size: 26, weight: .light))
                        .foregroundColor(AppColor.textSecondary)
                    wheelColumn(title: "Diastolic") {
                        Picker("Diastolic", selection: $dia) {
                            ForEach(30...130, id: \.self) { value in
                                Text("\(value)").tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 130)
                        .clipped()
                    }
                }
                Text("mmHg")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
            case .oxygen:
                Picker("Oxygen", selection: $oxygen) {
                    ForEach(50...100, id: \.self) { value in
                        Text("\(value)%").tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                .clipped()
            case .glucose:
                HStack(spacing: 0) {
                    Picker("Glucose", selection: glucoseSelection) {
                        ForEach(glucoseOptions, id: \.self) { value in
                            Text(glucoseUnit == .mgdL ? "\(Int(value))" : String(format: "%.1f", value))
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                    .clipped()
                    .onChange(of: glucoseUnit) { _ in
                        glucoseMg = glucoseUnit.mgdlValue(display: glucoseMmol)
                    }
                }
                Picker("Unit", selection: $glucoseUnit) {
                    ForEach(GlucoseUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(AppColor.surface))
        .onChange(of: glucoseUnit) { unit in
            GlucoseUnit.setCurrent(unit)
        }
    }

    private var glucoseSelection: Binding<Double> {
        Binding(get: {
            let value = glucoseUnit.displayValue(mgdl: glucoseMg)
            let options = glucoseOptions
            return options.min(by: { abs($0 - value) < abs($1 - value) }) ?? value
        }, set: { newValue in
            glucoseMg = glucoseUnit.mgdlValue(display: newValue)
            glucoseMmol = glucoseUnit == .mmolL ? newValue : (newValue / 18.0 * 10).rounded() / 10
        })
    }

    private var glucoseOptions: [Double] {
        if glucoseUnit == .mgdL {
            return Array(stride(from: 50.0, through: 250.0, by: 1.0))
        }
        return Array(stride(from: 2.8, through: 13.9, by: 0.1))
    }

    private func wheelColumn<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppColor.textSecondary)
            content()
        }
        .frame(maxWidth: .infinity)
    }

    private var detailRows: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Time")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColor.textPrimary)
                Spacer()
                DatePicker("", selection: $time, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
            }
            .padding(.vertical, 12)
            Divider()
            Button {
                showTagPicker = true
            } label: {
                HStack {
                    Text("Tag")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColor.textPrimary)
                    Spacer()
                    Text(TagResolver.title(for: tagId) ?? "Add a Tag")
                        .font(.system(size: 13))
                        .foregroundColor(AppColor.brand)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppColor.textSecondary)
                }
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 16)
        .background(RoundedRectangle(cornerRadius: 18).fill(AppColor.surface))
    }

    private var statusCard: some View {
        HStack(spacing: 10) {
            Circle().fill(statusColor.opacity(0.14)).frame(width: 36, height: 36)
                .overlay(Image(systemName: "checkmark.circle.fill").foregroundColor(statusColor))
            VStack(alignment: .leading, spacing: 2) {
                Text(status.interpretation)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColor.textPrimary)
                Text("Status is based on your \(kind == .pressure ? "systolic" : "current") reading")
                    .font(.system(size: 11))
                    .foregroundColor(AppColor.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(AppColor.surfaceAlt))
    }

    private var status: VitalsStatus.Band {
        switch kind {
        case .pressure: return VitalsStatus.pressure(sys: sys)
        case .oxygen: return VitalsStatus.oxygen(oxygen)
        case .glucose:
            let after = tagId == "eating-after"
            return VitalsStatus.glucose(mgdl: glucoseMg, afterMeal: after)
        }
    }

    private var statusColor: Color {
        switch status.color {
        case "green": return AppColor.success
        case "yellow": return AppColor.warning
        case "orange": return AppColor.orange
        case "red": return AppColor.danger
        case "blue": return AppColor.blue
        default: return AppColor.textSecondary
        }
    }

    private func save() {
        switch kind {
        case .pressure:
            dataStore.addPressure(sys: sys, dia: dia, tagId: tagId, time: time)
        case .oxygen:
            dataStore.addOxygen(value: oxygen, tagId: tagId, time: time)
        case .glucose:
            dataStore.addGlucose(value: glucoseMg, tagId: tagId, time: time)
        }
        dismiss()
    }
}

struct VitalsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataStore: HealthDataStore
    let log: HistoryLog

    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                content
                Button(role: .destructive) {
                    delete()
                    dismiss()
                } label: {
                    Text("Delete the measurement")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColor.danger)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(RoundedRectangle(cornerRadius: 16).fill(AppColor.danger.opacity(0.1)))
                }
                Spacer()
            }
            .padding(20)
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

    @ViewBuilder
    private var content: some View {
        switch log {
        case .pressure(let record):
            detailValue(value: "\(record.sys)/\(record.dia)", unit: "mmHg",
                        band: VitalsStatus.pressure(sys: record.sys), time: record.createdAt)
        case .oxygen(let record):
            detailValue(value: "\(record.value)", unit: "%",
                        band: VitalsStatus.oxygen(record.value), time: record.createdAt)
        case .glucose(let record):
            let unit = GlucoseUnit.current
            detailValue(value: unit == .mgdL ? "\(Int(record.value.rounded()))" : String(format: "%.1f", record.value / 18),
                        unit: unit.rawValue,
                        band: VitalsStatus.glucose(mgdl: record.value,
                                                   afterMeal: record.tagId == "eating-after"),
                        time: record.createdAt)
        case .heart:
            EmptyView()
        }
    }

    private func detailValue(value: String, unit: String, band: VitalsStatus.Band, time: Date) -> some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .foregroundColor(AppColor.textPrimary)
                Text(unit)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
            }
            StatusBadge(text: band.title, color: color(band.color))
            Text(band.interpretation)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColor.textPrimary)
            Text(Fmt.date(time, format: "MMMM d, yyyy · h:mm a"))
                .font(.system(size: 12))
                .foregroundColor(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .card(padding: 24)
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

    private var title: String {
        switch log {
        case .pressure: return "Blood Pressure"
        case .oxygen: return "Blood Oxygen"
        case .glucose: return "Blood Sugar"
        case .heart: return "Measurement"
        }
    }

    private func delete() {
        switch log {
        case .pressure(let record): dataStore.deletePressure(id: record.id)
        case .oxygen(let record): dataStore.deleteOxygen(id: record.id)
        case .glucose(let record): dataStore.deleteGlucose(id: record.id)
        case .heart(let measurement): dataStore.deleteMeasurement(id: measurement.id)
        }
    }
}
