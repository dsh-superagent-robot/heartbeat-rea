import SwiftUI

struct MeasurementDetailView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var dataStore: HealthDataStore
    @Environment(\.dismiss) private var dismiss

    let measurementID: String?

    @State private var measurement: HRMeasurement?
    @State private var showTagPicker = false
    @State private var showTrends = false
    @State private var showDeleteConfirm = false
    @State private var showMetricInfo: ResultMetric?

    var body: some View {
        ScrollView(showsIndicators: false) {
            if let measurement {
                VStack(spacing: 16) {
                    header(measurement)
                    metrics(measurement)
                    tagRow(measurement)
                    actions
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            } else {
                EmptyStateView(icon: "heart.slash", title: "Nothing Found",
                               message: "This measurement is no longer available")
                    .padding(24)
            }
        }
        .screenBackground()
        .navigationTitle("Measurement")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let measurementID { measurement = dataStore.measurement(id: measurementID) }
        }
        .onChange(of: dataStore.revision) { _ in
            if let measurementID { measurement = dataStore.measurement(id: measurementID) }
        }
        .sheet(isPresented: $showTagPicker) {
            if let measurement {
                TagPickerView(selectedTagId: measurement.tagId) { tagId in
                    dataStore.setTag(measurementID: measurement.id, tagId: tagId)
                    self.measurement = dataStore.measurement(id: measurement.id)
                }
                .environmentObject(dataStore)
            }
        }
        .sheet(isPresented: $showTrends) {
            if let measurement {
                TrendsSheet(highlighted: measurement)
                    .environmentObject(dataStore)
            }
        }
        .sheet(item: $showMetricInfo) { metric in
            MetricInfoSheet(metric: metric)
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog("Are you sure you want to delete this measurement?",
                            isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let measurement { dataStore.deleteMeasurement(id: measurement.id) }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func header(_ measurement: HRMeasurement) -> some View {
        let status = MetricCatalog.healthIndexStatus(measurement.healthIndex)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Health Index")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
                Spacer()
                StatusBadge(text: status.displayStatus, color: statusColor(status.color))
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(String(format: "%.1f", measurement.healthIndex))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(AppColor.textPrimary)
                Text(status.indicator)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(statusColor(status.color))
                Spacer()
            }
            Text("\(Fmt.date(measurement.time, format: "MMMM d, yyyy")) · \(Fmt.time(measurement.time))")
                .font(.system(size: 12))
                .foregroundColor(AppColor.textSecondary)
        }
        .card()
    }

    private func metrics(_ measurement: HRMeasurement) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(ResultMetric.allCases) { metric in
                Button {
                    showMetricInfo = metric
                } label: {
                    let value = metric.value(from: measurement)
                    let status = metric.status(for: value)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(metric.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColor.textSecondary)
                            Spacer()
                            Image(systemName: "info.circle")
                                .font(.system(size: 10))
                                .foregroundColor(AppColor.textSecondary.opacity(0.5))
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(metric.formattedValue(measurement))
                                .font(.system(size: 25, weight: .bold, design: .rounded))
                                .foregroundColor(AppColor.textPrimary)
                            if !metric.unit.isEmpty {
                                Text(metric.unit)
                                    .font(.system(size: 10))
                                    .foregroundColor(AppColor.textSecondary)
                            }
                        }
                        Text(status.indicator)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(statusColor(status.color))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 18).fill(AppColor.surface))
                }
                .buttonStyle(PressableCardStyle())
            }
        }
    }

    private func tagRow(_ measurement: HRMeasurement) -> some View {
        Button {
            showTagPicker = true
        } label: {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(AppColor.brand)
                Text("Tag")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColor.textPrimary)
                Spacer()
                Text(TagResolver.title(for: measurement.tagId) ?? "Add a Tag")
                    .font(.system(size: 13))
                    .foregroundColor(AppColor.brand)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColor.textSecondary)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18).fill(AppColor.surface))
        }
        .buttonStyle(.plain)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                showTrends = true
            } label: {
                Text("Trends")
            }
            .buttonStyle(SecondaryButtonStyle())

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Text("Delete the measurement")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColor.danger)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: 16).fill(AppColor.danger.opacity(0.1)))
            }
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
