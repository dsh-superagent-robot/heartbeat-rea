import SwiftUI

enum OnboardingPage: Int, CaseIterable, Identifiable {
    case welcome, pulse, log, stress, monitor, paywall, aboutYourself

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome: return "Check your **Heart Rate**\nwhenever you need"
        case .pulse: return "Reveal your **Heart Health**\nin seconds"
        case .log: return "Log **Blood Pressure**\nand **Glucose Level**"
        case .stress: return "Reduce **Stress Level**\nwith weekly insights"
        case .monitor: return "Monitor **Health Metrics**\ndaily with ease"
        case .paywall: return "Your personal\n**health companion**"
        case .aboutYourself: return "Let's Personalize\nYour Journey"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome: return "Track your heart health — fast, simple, and reliable"
        case .pulse: return "Get instant insights into your heart rate, stress, and overall health"
        case .log: return "Keep all your vital stats together in one convenient app"
        case .stress: return "Analyze your patterns and learn how to lower stress"
        case .monitor: return "Use advanced technologies for your healthy, active life"
        case .paywall: return "Unlock the full picture of your heart health with a free trial"
        case .aboutYourself: return "Help us understand you better before you begin using the app."
        }
    }

    var symbol: String {
        switch self {
        case .welcome, .pulse: return "heart.fill"
        case .log: return "waveform.path.ecg.rectangle"
        case .stress: return "brain.head.profile"
        case .monitor: return "chart.xyaxis.line"
        case .paywall: return "sparkles"
        case .aboutYourself: return "person.crop.circle"
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var index = 0
    @State private var profileModel = ProfileEditorModel(profile: ProfileStore.load())
    @State private var showLegal: LegalWebView.Document?
    @State private var plan: OnboardingPlan = .yearly
    @State private var didStartTrial = false
    @State private var isPurchasing = false

    private var page: OnboardingPage { OnboardingPage(rawValue: index) ?? .welcome }

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        if page == .paywall {
                            paywallContent
                        } else if page == .aboutYourself {
                            aboutContent
                        } else {
                            storyContent
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity)
                }
                footer
            }
        }
        .sheet(item: $showLegal) { document in
            LegalWebView(document: document)
        }
    }

    // MARK: Background

    private var background: some View {
        ZStack {
            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            Circle()
                .fill(AppColor.brand.opacity(0.20))
                .frame(width: 380, height: 380)
                .blur(radius: 110)
                .offset(x: 120, y: -180)
            Circle()
                .fill(Color(red: 0.35, green: 0.20, blue: 0.85).opacity(0.20))
                .frame(width: 320, height: 320)
                .blur(radius: 120)
                .offset(x: -140, y: 240)
        }
    }

    private var gradientColors: [Color] {
        switch page {
        case .welcome, .pulse:
            return [Color(red: 0.07, green: 0.04, blue: 0.10), Color(red: 0.24, green: 0.03, blue: 0.12)]
        case .log:
            return [Color(red: 0.04, green: 0.06, blue: 0.11), Color(red: 0.05, green: 0.17, blue: 0.22)]
        case .stress:
            return [Color(red: 0.06, green: 0.05, blue: 0.12), Color(red: 0.14, green: 0.08, blue: 0.28)]
        case .monitor:
            return [Color(red: 0.03, green: 0.07, blue: 0.10), Color(red: 0.05, green: 0.19, blue: 0.18)]
        case .paywall:
            return [Color(red: 0.08, green: 0.05, blue: 0.07), Color(red: 0.30, green: 0.05, blue: 0.14)]
        case .aboutYourself:
            return [Color(red: 0.06, green: 0.05, blue: 0.10), Color(red: 0.14, green: 0.06, blue: 0.16)]
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                if index > 0 {
                    withAnimation(.easeInOut(duration: 0.25)) { index -= 1 }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white.opacity(index > 0 ? 0.12 : 0)))
            }
            .opacity(index > 0 ? 1 : 0)
            .disabled(index == 0)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                Text("Heartica")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)

            Spacer()

            Text("\(index + 1)/\(OnboardingPage.allCases.count)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.55))
                .frame(width: 38)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
    }

    // MARK: Story

    private var storyContent: some View {
        VStack(spacing: 26) {
            OnboardingArtwork(page: page)
                .frame(height: 300)
                .padding(.top, 4)

            VStack(spacing: 12) {
                Text(.init(page.title))
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                Text(page.subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.66))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if page == .welcome {
                HStack(spacing: 12) {
                    HStack(spacing: 2) {
                        ForEach(0..<5) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundColor(AppColor.warning)
                        }
                    }
                    Text("Trusted by **1M+** users worldwide")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Capsule().fill(Color.white.opacity(0.08)))
            }
            Spacer(minLength: 6)
        }
    }

    // MARK: Paywall screen inside onboarding

    private var paywallContent: some View {
        VStack(spacing: 18) {
            OnboardingArtwork(page: .paywall)
                .frame(height: 150)

            Text(page.title)
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Text(page.subtitle)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.66))
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                ForEach(OnboardingPlan.allCases) { item in
                    planRow(item)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                benefit("infinity", "Unlimited heart rate measurements")
                benefit("waveform.path.ecg", "HRV, stress and recovery insights")
                benefit("calendar", "Weekly and monthly health reports")
                benefit("heart.text.square", "Apple Health sync")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                startTrial()
            } label: {
                if isPurchasing {
                    ProgressView().tint(.white)
                } else {
                    Text(didStartTrial ? "Trial Started" : "Start 3-Day Free Trial")
                }
            }
            .buttonStyle(PrimaryButtonStyle(color: AppColor.brand))
            .disabled(isPurchasing)

            Text("Auto-renews after 3 days. Cancel anytime in Settings.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.45))
                .multilineTextAlignment(.center)
        }
    }

    private func planRow(_ item: OnboardingPlan) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) { plan = item }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().stroke(plan == item ? AppColor.brand : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if plan == item {
                        Circle().fill(AppColor.brand).frame(width: 12, height: 12)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(item.caption)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.55))
                }
                Spacer()
                Text(item.price)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                if item == .yearly {
                    Text("SAVE 45%")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(AppColor.brand))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(plan == item ? 0.12 : 0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(plan == item ? AppColor.brand.opacity(0.8) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func benefit(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColor.brand)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.85))
        }
    }

    private func startTrial() {
        guard !isPurchasing else { return }
        isPurchasing = true
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            appState.setPremium(true)
            didStartTrial = true
            isPurchasing = false
            advance()
        }
    }

    // MARK: About yourself

    private var aboutContent: some View {
        VStack(spacing: 18) {
            OnboardingArtwork(page: .aboutYourself)
                .frame(height: 160)

            Text(page.title)
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Text(page.subtitle)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.66))
                .multilineTextAlignment(.center)

            ProfileMetricsForm(model: profileModel)

            Text("You can add or update this information anytime in your profile settings.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.45))
                .multilineTextAlignment(.center)

            Button("Skip") {
                completeOnboarding()
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white.opacity(0.75))
        }
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: 12) {
            if page != .paywall && page != .aboutYourself {
                HStack(spacing: 7) {
                    ForEach(OnboardingPage.allCases.indices, id: \.self) { itemIndex in
                        Capsule()
                            .fill(itemIndex == index ? AppColor.brand : Color.white.opacity(0.22))
                            .frame(width: itemIndex == index ? 22 : 6, height: 6)
                    }
                }
                .animation(.easeOut(duration: 0.2), value: index)
            }

            Button(page == .aboutYourself ? "Continue" : "Continue") {
                if page == .aboutYourself {
                    completeOnboarding()
                } else {
                    advance()
                }
            }
            .buttonStyle(PrimaryButtonStyle(color: AppColor.brand, height: 54))

            legalFooter
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 14)
    }

    private var legalFooter: some View {
        VStack(spacing: 3) {
            Text("By proceeding, you accept our")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.45))
            HStack(spacing: 4) {
                Button("Terms of Use") { showLegal = .terms }
                Text("and").foregroundColor(.white.opacity(0.45))
                Button("Privacy Policy") { showLegal = .privacy }
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white.opacity(0.75))
        }
    }

    // MARK: Actions

    private func advance() {
        guard index < OnboardingPage.allCases.count - 1 else {
            completeOnboarding()
            return
        }
        withAnimation(.easeInOut(duration: 0.28)) { index += 1 }
    }

    private func completeOnboarding() {
        let profile = profileModel.buildProfile(base: appState.profile)
        appState.completeOnboarding(profile: profile, purchased: didStartTrial)
    }
}

enum OnboardingPlan: String, CaseIterable, Identifiable {
    case yearly, weekly
    var id: String { rawValue }
    var title: String {
        switch self {
        case .yearly: return "Yearly"
        case .weekly: return "Weekly"
        }
    }
    var caption: String {
        switch self {
        case .yearly: return "3-day free trial, then $39.99/year"
        case .weekly: return "3-day free trial, then $6.99/week"
        }
    }
    var price: String {
        switch self {
        case .yearly: return "$3.33/mo"
        case .weekly: return "$6.99"
        }
    }
}

// MARK: - Programmatic on-boarding illustration

struct OnboardingArtwork: View {
    let page: OnboardingPage
    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [AppColor.brand.opacity(0.55), AppColor.brand.opacity(0.05)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 250, height: 250)
                .blur(radius: 2)
                .scaleEffect(animate ? 1.03 : 0.96)

            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                .frame(width: 290, height: 290)

            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
                .frame(width: 230, height: 230)

            switch page {
            case .welcome, .pulse:
                mainHeart
            case .log:
                vitalsCards
            case .stress:
                stressArtwork
            case .monitor:
                monitorArtwork
            case .paywall:
                paywallArtwork
            case .aboutYourself:
                profileArtwork
            }
        }
        .onAppear { animate = true }
    }

    private var mainHeart: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 148, height: 148)
                Image(systemName: "heart.fill")
                    .font(.system(size: 68))
                    .foregroundStyle(LinearGradient(colors: [.white, Color(red: 1, green: 0.65, blue: 0.68)],
                                                    startPoint: .top, endPoint: .bottom))
                    .shadow(color: AppColor.brand.opacity(0.6), radius: 24)
                WaveformMark()
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .frame(width: 86, height: 30)
                    .offset(y: 4)
            }
            HStack(spacing: 10) {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(AppColor.brand)
                Text("72 bpm")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Normal")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColor.success)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(AppColor.success.opacity(0.15)))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.black.opacity(0.22)))
        }
    }

    private var vitalsCards: some View {
        VStack(spacing: 12) {
            artworkRow(icon: "waveform.path.ecg", title: "Blood Pressure", value: "118/76", unit: "mmHg", color: AppColor.brand)
            artworkRow(icon: "drop.fill", title: "Glucose", value: "5.4", unit: "mmol/L", color: AppColor.teal)
            artworkRow(icon: "lungs.fill", title: "Oxygen", value: "98", unit: "%", color: AppColor.blue)
        }
        .padding(.horizontal, 24)
    }

    private var stressArtwork: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 14)
                    .frame(width: 156, height: 156)
                Circle()
                    .trim(from: 0, to: 0.36)
                    .stroke(LinearGradient(colors: [AppColor.purple, AppColor.brand],
                                           startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: 156, height: 156)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("36")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Low stress")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            HStack(spacing: 8) {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                    VStack(spacing: 6) {
                        Capsule()
                            .fill(day == "W" ? AppColor.brand : Color.white.opacity(0.18))
                            .frame(width: 8, height: CGFloat.random(in: 20...38))
                        Text(day)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.45))
                    }
                }
            }
            .frame(height: 58)
        }
    }

    private var monitorArtwork: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                metricTile(title: "HRV", value: "58", unit: "ms", color: AppColor.teal)
                metricTile(title: "Stress", value: "32", unit: "%", color: AppColor.purple)
            }
            HStack(spacing: 12) {
                metricTile(title: "Energy", value: "84", unit: "%", color: AppColor.orange)
                metricTile(title: "Health", value: "6.4", unit: "", color: AppColor.success)
            }
        }
        .padding(.horizontal, 30)
    }

    private var paywallArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .frame(width: 236, height: 132)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.12), lineWidth: 1))
            VStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(LinearGradient(colors: [AppColor.warning, AppColor.brand],
                                                    startPoint: .top, endPoint: .bottom))
                Text("Heartica Premium")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Everything your heart needs")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    private var profileArtwork: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 120, height: 120)
            Image(systemName: "person.fill")
                .font(.system(size: 52))
                .foregroundColor(.white.opacity(0.9))
            Circle()
                .fill(AppColor.brand)
                .frame(width: 34, height: 34)
                .overlay(Image(systemName: "checkmark").font(.system(size: 15, weight: .bold)).foregroundColor(.white))
                .offset(x: 44, y: 44)
        }
    }

    private func artworkRow(icon: String, title: String, value: String, unit: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(Circle().fill(color.opacity(0.14)))
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(unit)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.45))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: 270)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.08)))
    }

    private func metricTile(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.45))
            }
            Capsule().fill(color.opacity(0.7)).frame(width: 36, height: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white.opacity(0.08)))
    }
}
