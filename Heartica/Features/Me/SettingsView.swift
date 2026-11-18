import PhotosUI
import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @StateObject private var model = ProfileEditorModel(profile: ProfileStore.load())

    @State private var name: String = ""
    @State private var surname: String = ""
    @State private var photoData: Data?
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    avatarSection
                    VStack(spacing: 12) {
                        field("Name", text: $name, placeholder: "Name")
                        field("Surname", text: $surname, placeholder: "Surname")
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 18).fill(AppColor.surface))

                    ProfileMetricsForm(model: model)

                    Text("You can add or update this information anytime in your profile settings.")
                        .font(.system(size: 11))
                        .foregroundColor(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
            .screenBackground()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                name = appState.profile.name
                surname = appState.profile.surname
                photoData = appState.profile.photoData
            }
            .onChange(of: photoItem) { item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
    }

    private var avatarSection: some View {
        VStack(spacing: 10) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let data = photoData, let image = UIImage(data: data) {
                            Image(uiImage: image).resizable().scaledToFill()
                        } else {
                            ZStack {
                                AppColor.brandGradient
                                Image(systemName: "person.fill")
                                    .font(.system(size: 38))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    .frame(width: 96, height: 96)
                    .clipShape(Circle())
                    Circle()
                        .fill(AppColor.brand)
                        .frame(width: 30, height: 30)
                        .overlay(Image(systemName: "camera.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white))
                }
            }
            Text("Tap to change photo")
                .font(.system(size: 11))
                .foregroundColor(AppColor.textSecondary)
        }
        .padding(.top, 8)
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColor.textSecondary)
                .frame(width: 80, alignment: .leading)
            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: 40)
    }

    private func save() {
        var profile = model.buildProfile(base: appState.profile)
        profile.name = String(name.prefix(30))
        profile.surname = String(surname.prefix(30))
        profile.photoData = photoData
        appState.updateProfile(profile)
        dismiss()
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var dataStore: HealthDataStore

    @State private var showProfile = false
    @State private var showAppearance = false
    @State private var showWhatsNew = false
    @State private var showLegal: LegalWebView.Document?
    @State private var showResetConfirm = false
    @State private var showSeedConfirm = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    profileHeader
                    section("Preferences") {
                        row(icon: "heart.text.square.fill", color: AppColor.success, title: "Apple Health Sync") {
                            AppleHealthView().environmentObject(appState)
                        }
                        divider
                        row(icon: "bell.fill", color: AppColor.orange, title: "Reminders") {
                            RemindersView()
                                .environmentObject(appState)
                                .environmentObject(dataStore)
                        }
                        divider
                        Button {
                            showAppearance = true
                        } label: {
                            rowLabel(icon: "circle.lefthalf.filled", color: AppColor.purple,
                                     title: "Appearance", value: appState.appearance.title)
                        }
                    }
                    section("Support") {
                        Button {
                            rate()
                        } label: {
                            rowLabel(icon: "star.fill", color: AppColor.warning, title: "Rate Us")
                        }
                        divider
                        ShareLink(item: "Please, share my app! https://apps.apple.com/us/app/6742904990") {
                            rowLabel(icon: "square.and.arrow.up", color: AppColor.blue, title: "Share App")
                        }
                        divider
                        Button {
                            contact()
                        } label: {
                            rowLabel(icon: "envelope.fill", color: AppColor.teal, title: "Contact Us")
                        }
                        divider
                        Button {
                            showWhatsNew = true
                        } label: {
                            rowLabel(icon: "sparkles", color: AppColor.brand, title: "What's New")
                        }
                    }
                    section("Legal") {
                        Button { showLegal = .privacy } label: {
                            rowLabel(icon: "hand.raised.fill", color: AppColor.blue, title: "Privacy Policy")
                        }
                        divider
                        Button { showLegal = .terms } label: {
                            rowLabel(icon: "doc.text.fill", color: AppColor.textSecondary, title: "Terms of Use")
                        }
                    }
                    section("About") {
                        rowLabel(icon: "info.circle.fill", color: AppColor.textSecondary, title: "Version",
                                 value: versionString)
                        #if DEBUG
                        divider
                        Button { showSeedConfirm = true } label: {
                            rowLabel(icon: "wand.and.stars", color: AppColor.purple,
                                     title: "Developer: Seed Sample Data")
                        }
                        divider
                        Button { showResetConfirm = true } label: {
                            rowLabel(icon: "arrow.counterclockwise", color: AppColor.danger,
                                     title: "Developer: Reset Onboarding")
                        }
                        #endif
                    }
                }
                .padding(18)
            }
            .screenBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView().environmentObject(appState)
            }
            .sheet(isPresented: $showAppearance) {
                AppearancePicker()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showWhatsNew) {
                WhatsNewView()
            }
            .sheet(item: $showLegal) { LegalWebView(document: $0) }
            .alert("Reset Onboarding?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    dismiss()
                    appState.resetForOnboarding()
                }
            } message: {
                Text("You will return to the onboarding flow. Your health data is kept.")
            }
            .alert("Seed Sample Data?", isPresented: $showSeedConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Seed") {
                    dataStore.seedDemoData()
                    dismiss()
                }
            } message: {
                Text("Adds 14 days of demo measurements, vitals and tags for review purposes.")
            }
        }
    }

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.10"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "582"
        return "\(version) (\(build))"
    }

    private var profileHeader: some View {
        Button {
            showProfile = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    AppColor.brandGradient
                    Text(appState.profile.displayName.prefix(1).uppercased())
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(width: 54, height: 54)
                .clipShape(Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(appState.profile.displayName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppColor.textPrimary)
                    Text("Profile & personal information")
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColor.textSecondary)
            }
            .card(padding: 14)
        }
        .buttonStyle(PressableCardStyle())
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColor.textSecondary)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 14)
            .background(RoundedRectangle(cornerRadius: 18).fill(AppColor.surface))
        }
    }

    private func row<Destination: View>(icon: String, color: Color, title: String,
                                        @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            rowLabel(icon: icon, color: color, title: title)
        }
        .buttonStyle(.plain)
    }

    private func rowLabel(icon: String, color: Color, title: String, value: String? = nil) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 30, height: 30)
                .background(Circle().fill(color.opacity(0.12)))
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColor.textPrimary)
            Spacer()
            if let value {
                Text(value)
                    .font(.system(size: 13))
                    .foregroundColor(AppColor.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppColor.textSecondary.opacity(0.5))
        }
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }

    private var divider: some View {
        Divider().padding(.leading, 42)
    }

    private func rate() {
        if let url = URL(string: "https://apps.apple.com/us/app/6742904990?action=write-review") {
            UIApplication.shared.open(url)
        }
    }

    private func contact() {
        let subject = "Heartica Support"
        let body = "\n\nApp version: \(versionString)\nDevice: \(UIDevice.current.model) \(UIDevice.current.systemVersion)"
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "support@heartica.pro"
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        if let url = components.url {
            UIApplication.shared.open(url)
        }
    }
}

struct AppearancePicker: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ForEach(AppearanceMode.allCases) { mode in
                    Button {
                        appState.setAppearance(mode)
                        dismiss()
                    } label: {
                        HStack {
                            Text(mode.title)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColor.textPrimary)
                            Spacer()
                            if appState.appearance == mode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColor.brand)
                            }
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 54)
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, 20)
                }
                Spacer()
            }
            .screenBackground()
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
