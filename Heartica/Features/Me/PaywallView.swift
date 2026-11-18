import SwiftUI
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var authorized = false

    private var defaults: UserDefaults { .standard }

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorized = settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
        defaults.set(authorized, forKey: UDKey.notificationsEnable)
        defaults.set(settings.authorizationStatus.rawValue, forKey: UDKey.notificationAuthStatus)
    }

    func requestAuthorization() async -> Bool {
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        await refreshStatus()
        return granted
    }

    func schedule(reminders: [Reminder]) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: reminders.map { "reminder-\($0.id)" })
        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = reminderTitle(reminder.type)
            content.body = reminderBody(reminder.type)
            content.sound = .default
            let components = Calendar.current.dateComponents([.hour, .minute], from: reminder.time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "reminder-\(reminder.id)",
                                                content: content,
                                                trigger: trigger)
            center.add(request)
        }
    }

    func scheduleCSIReminder() {
        let content = UNMutableNotificationContent()
        content.title = L("Pulse CSI reminder")
        content.body = L("Take a measurement to keep your Chronic Stress Index up to date.")
        content.sound = .default
        var components = DateComponents()
        components.hour = 20
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "csi-reminder", content: content, trigger: trigger)
        )
    }

    private func reminderTitle(_ type: String) -> String {
        switch type {
        case "Pressure": return L("Blood Pressure reminder")
        case "Oxygen": return L("Blood Oxygen reminder")
        case "Glucose": return L("Blood Sugar reminder")
        case "Heart Age": return L("Heart Age reminder")
        case "Pulse CSI": return L("Pulse CSI reminder")
        default: return L("Measurement reminder")
        }
    }

    private func reminderBody(_ type: String) -> String {
        LF("It's time to log your %@ in Heartica.", L(type))
    }
}

enum ReminderType: String, CaseIterable, Identifiable {
    case pulse = "Pulse"
    case pressure = "Pressure"
    case oxygen = "Oxygen"
    case glucose = "Glucose"
    case heartAge = "Heart Age"
    case csi = "Pulse CSI"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pulse: return "heart.fill"
        case .pressure: return "waveform.path.ecg"
        case .oxygen: return "lungs.fill"
        case .glucose: return "drop.fill"
        case .heartAge: return "heart.circle"
        case .csi: return "bolt.heart"
        }
    }
}

struct RemindersView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var dataStore: HealthDataStore
    @StateObject private var notifications = NotificationService.shared

    @State private var showAdd = false
    @State private var newTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var newType: ReminderType = .pulse
    @State private var showDenied = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                headerCard
                if dataStore.reminders().isEmpty {
                    EmptyStateView(icon: "bell.slash", title: "No Reminders",
                                   message: "Set a daily reminder to stay consistent")
                        .card()
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(dataStore.reminders().enumerated()), id: \.element.id) { index, reminder in
                            reminderRow(reminder)
                            if index < dataStore.reminders().count - 1 { Divider().padding(.leading, 54) }
                        }
                    }
                    .padding(.horizontal, 16)
                    .background(RoundedRectangle(cornerRadius: 20).fill(AppColor.surface))
                }
                Button {
                    prepareAdd()
                } label: {
                    Label("Add Reminder", systemImage: "plus")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(18)
        }
        .screenBackground()
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await notifications.refreshStatus()
            notifications.schedule(reminders: dataStore.reminders())
        }
        .sheet(isPresented: $showAdd) {
            addSheet
        }
        .alert("Notifications Disabled", isPresented: $showDenied) {
            Button("Cancel", role: .cancel) {}
            Button("Go to Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Allow push notifications in Settings to set and receive reminders.")
        }
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "bell.fill")
                .font(.system(size: 22))
                .foregroundColor(AppColor.brand)
                .frame(width: 48, height: 48)
                .background(Circle().fill(AppColor.brandSoft))
            VStack(alignment: .leading, spacing: 3) {
                Text(L("Daily Reminders"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColor.textPrimary)
                Text(L(notifications.authorized ? "Notifications are enabled" : "Notifications are off"))
                    .font(.system(size: 12))
                    .foregroundColor(AppColor.textSecondary)
            }
            Spacer()
            Button(L("Allow")) {
                Task {
                    let granted = await notifications.requestAuthorization()
                    if granted { notifications.schedule(reminders: dataStore.reminders()) }
                    else { showDenied = true }
                }
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(AppColor.brand)
        }
        .card(padding: 14)
    }

    private func reminderRow(_ reminder: Reminder) -> some View {
        HStack(spacing: 12) {
            Image(systemName: ReminderType(rawValue: reminder.type)?.icon ?? "bell.fill")
                .font(.system(size: 15))
                .foregroundColor(AppColor.brand)
                .frame(width: 34, height: 34)
                .background(Circle().fill(AppColor.brandSoft))
            VStack(alignment: .leading, spacing: 2) {
                Text(L(reminder.type))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColor.textPrimary)
                Text("Daily")
                    .font(.system(size: 11))
                    .foregroundColor(AppColor.textSecondary)
            }
            Spacer()
            Text(Fmt.time(reminder.time))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColor.textPrimary)
            Button {
                dataStore.deleteReminder(id: reminder.id)
                notifications.schedule(reminders: dataStore.reminders())
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundColor(AppColor.danger)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
    }

    private var addSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                DatePicker("Time", selection: $newTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                Picker("Type", selection: $newType) {
                    ForEach(ReminderType.allCases) { type in
                        Text(L(type.rawValue)).tag(type)
                    }
                }
                .pickerStyle(.wheel)
                Button("Save Reminder") {
                    dataStore.addReminder(time: newTime, type: newType.rawValue)
                    notifications.schedule(reminders: dataStore.reminders())
                    showAdd = false
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 20)
                Spacer()
            }
            .padding(.top, 20)
            .screenBackground()
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showAdd = false }
                }
            }
        }
    }

    private func prepareAdd() {
        Task {
            if !notifications.authorized {
                let granted = await notifications.requestAuthorization()
                if !granted {
                    showDenied = true
                    return
                }
            }
            showAdd = true
        }
    }
}

// MARK: - Paywall

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    let source: String

    @State private var selectedPlan: OnboardingPlan = .yearly
    @State private var isPurchasing = false
    @State private var showLegal: LegalWebView.Document?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                }
                VStack(spacing: 10) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(LinearGradient(colors: [AppColor.warning, AppColor.brand],
                                                        startPoint: .top, endPoint: .bottom))
                    Text("Get Full Access")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Everything your heart needs, without limits")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.65))
                }
                .padding(.top, 4)

                VStack(spacing: 10) {
                    ForEach(OnboardingPlan.allCases) { plan in
                        paywallPlanRow(plan)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    feature("infinity", "Unlimited Measuring")
                    feature("waveform.path.ecg", "All Features")
                    feature("chart.xyaxis.line", "Advanced Analytics")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)

                Button {
                    purchase()
                } label: {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Try for Free")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isPurchasing)

                Text(LF("3 days free, then %@. Auto-renewable. Cancel anytime.",
                        selectedPlan == .yearly ? L("$39.99/year") : L("$6.99/week")))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)

                HStack(spacing: 16) {
                    Button("Restore") {
                        if UserDefaults.standard.bool(forKey: UDKey.didPurchasedApp) {
                            appState.setPremium(true)
                            dismiss()
                        }
                    }
                    Button("Privacy Policy") { showLegal = .privacy }
                    Button("Terms of Use") { showLegal = .terms }
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            }
            .padding(22)
        }
        .background(
            LinearGradient(colors: [Color(red: 0.08, green: 0.04, blue: 0.07),
                                    Color(red: 0.30, green: 0.04, blue: 0.13),
                                    Color(red: 0.06, green: 0.03, blue: 0.06)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
        .sheet(item: $showLegal) { LegalWebView(document: $0) }
    }

    private func paywallPlanRow(_ plan: OnboardingPlan) -> some View {
        Button {
            selectedPlan = plan
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedPlan == plan ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(selectedPlan == plan ? AppColor.brand : .white.opacity(0.4))
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(plan.caption)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.55))
                }
                Spacer()
                if plan == .yearly {
                    Text("BEST VALUE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AppColor.brand))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(selectedPlan == plan ? 0.12 : 0.06))
                    .overlay(RoundedRectangle(cornerRadius: 18)
                        .stroke(selectedPlan == plan ? AppColor.brand : .clear, lineWidth: 1.5))
            )
        }
        .buttonStyle(.plain)
    }

    private func feature(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColor.brand)
                .frame(width: 20)
            Text(L(text))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
    }

    private func purchase() {
        guard !isPurchasing else { return }
        isPurchasing = true
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            appState.setPremium(true)
            isPurchasing = false
            dismiss()
        }
    }
}

// MARK: - What's New

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.10"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(AppColor.brandGradient)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(AppColor.brandSoft))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("What's New")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                            Text(LF("Version %@", version))
                                .font(.system(size: 13))
                                .foregroundColor(AppColor.textSecondary)
                        }
                    }
                    .padding(.top, 8)

                    featureRow(icon: "bolt.heart.fill", title: "Chronic Stress Index",
                               text: "Track your 7-day stress pattern and see how your body adapts.")
                    featureRow(icon: "heart.circle.fill", title: "Heart Age",
                               text: "Learn your heart's estimated age from three measurements.")
                    featureRow(icon: "calendar", title: "Monthly Insights",
                               text: "Explore your month at a glance with a detailed daily calendar.")
                    featureRow(icon: "chart.xyaxis.line", title: "Better Charts",
                               text: "New chart settings let you choose bars, lines, thresholds and trend lines.")
                }
                .padding(20)
            }
            .screenBackground()
            .navigationTitle("What's New")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func featureRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColor.brand)
                .frame(width: 38, height: 38)
                .background(Circle().fill(AppColor.brandSoft))
            VStack(alignment: .leading, spacing: 3) {
                Text(L(title))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColor.textPrimary)
                Text(L(text))
                    .font(.system(size: 13))
                    .foregroundColor(AppColor.textSecondary)
                    .lineSpacing(2)
            }
        }
    }
}
