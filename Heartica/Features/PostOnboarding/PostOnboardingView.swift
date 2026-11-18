import SwiftUI

enum PostObStep: Int, CaseIterable {
    case appleHealthPre
    case appleHealthTutorial
    case appleHealthProgress
    case checkData
    case quizDoctorAdvised
    case quizAnxiety
    case quizEverDiagnosed
    case calculationInProgress
    case results
}

struct PostOnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var step: PostObStep = .appleHealthPre
    @State private var profileModel = ProfileEditorModel(profile: ProfileStore.load())
    @State private var answers: [String: String] = [:]
    @State private var showSkipConfirmation = false
    @State private var showDisclaimer = false
    @State private var healthConnected = false
    @State private var calculationDone = false

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                Group {
                    switch step {
                    case .appleHealthPre:
                        appleHealthPre
                    case .appleHealthTutorial:
                        appleHealthTutorial
                    case .appleHealthProgress:
                        appleHealthProgress
                    case .checkData:
                        checkData
                    case .quizDoctorAdvised:
                        quiz(title: "Has your doctor recommended tracking your **heart rate** or blood pressure?",
                             options: ["Yes", "No"], key: "doctor_advised")
                    case .quizAnxiety:
                        quiz(title: "How often do you feel anxious?",
                             options: ["Often", "Sometimes", "Rarely"], key: "anxiety")
                    case .quizEverDiagnosed:
                        quiz(title: "Have you ever been diagnosed with high blood pressure or another heart condition?",
                             options: ["Yes", "No"], key: "ever_diagnosed")
                    case .calculationInProgress:
                        calculation
                    case .results:
                        results
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .alert(L("Proceed Without Apple Health?"), isPresented: $showSkipConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm") {
                withAnimation { step = .checkData }
            }
        } message: {
            Text(L("You can connect Apple Health later in Settings."))
        }
        .sheet(isPresented: $showDisclaimer) {
            disclaimerSheet
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            if step != .results {
                HStack(spacing: 5) {
                    ForEach(PostObStep.allCases.indices, id: \.self) { index in
                        Capsule()
                            .fill(index <= step.rawValue ? AppColor.brand : AppColor.separator)
                            .frame(height: 4)
                    }
                }
            } else {
                Spacer()
            }
            if step == .appleHealthPre {
                Button("Skip") { showSkipConfirmation = true }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColor.textSecondary)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(height: 44)
    }

    // MARK: Apple Health

    private var appleHealthPre: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [AppColor.brand.opacity(0.25), AppColor.brand.opacity(0.04)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 210, height: 210)
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 76))
                    .foregroundStyle(AppColor.brandGradient)
            }
            VStack(spacing: 10) {
                Text("Get 2× More Health Data with Apple Health")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppColor.textPrimary)
                Text("Takes less than 10 seconds")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
            }
            Spacer()
            Button("Connect Apple Health") {
                healthConnected = true
                withAnimation { step = .appleHealthTutorial }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
        }
    }

    private var appleHealthTutorial: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.system(size: 64))
                .foregroundColor(AppColor.brand)
                .padding(28)
                .background(Circle().fill(AppColor.brandSoft))
            Text("Turn on all categories in Settings to sync your data")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(AppColor.textPrimary)
            Text("We only access the data needed to provide your health insights")
                .font(.system(size: 15))
                .foregroundColor(AppColor.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button("Turn On All Now") {
                withAnimation { step = .appleHealthProgress }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
        }
        .padding(.horizontal, 28)
    }

    private var appleHealthProgress: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .stroke(AppColor.separator, lineWidth: 10)
                    .frame(width: 130, height: 130)
                Circle()
                    .trim(from: 0, to: healthConnected ? 1 : 0.35)
                    .stroke(AppColor.brand, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.3), value: healthConnected)
                Image(systemName: healthConnected ? "checkmark" : "arrow.triangle.2.circlepath")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(AppColor.brand)
            }
            Text(.init(L(healthConnected ? "Successfully **Synced**" : "Syncing with Apple Health…")))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColor.textPrimary)
                .multilineTextAlignment(.center)
            Text("Heart rate, HRV, steps and sleep")
                .font(.system(size: 14))
                .foregroundColor(AppColor.textSecondary)
            Spacer()
        }
        .task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation { step = .checkData }
            }
        }
    }

    // MARK: Check data

    private var checkData: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                Image(systemName: "person.text.rectangle")
                    .font(.system(size: 40))
                    .foregroundColor(AppColor.brand)
                    .padding(.top, 18)
                Text("Review your personal information")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppColor.textPrimary)
                Text("This information comes from Apple Health. Please edit anything that's incorrect.")
                    .font(.system(size: 14))
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                ProfileMetricsForm(model: profileModel)
                Button("Continue") {
                    let profile = profileModel.buildProfile(base: appState.profile)
                    appState.updateProfile(profile)
                    showDisclaimer = true
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 6)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 24)
        }
    }

    private var disclaimerSheet: some View {
        VStack(spacing: 20) {
            Image(systemName: "stethoscope")
                .font(.system(size: 44))
                .foregroundColor(AppColor.brand)
                .padding(.top, 28)
            Text("Important")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            Text("Heartica is not a medical device and does not provide medical advice. It does not diagnose or treat high blood pressure, heart disease, or any medical condition. Always consult a healthcare professional for medical advice.")
                .font(.system(size: 15))
                .foregroundColor(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            Button("Got It") {
                showDisclaimer = false
                withAnimation { step = .quizDoctorAdvised }
            }
            .buttonStyle(PrimaryButtonStyle())
            Spacer()
        }
        .padding(.horizontal, 26)
        .padding(.bottom, 24)
        .presentationDetents([.medium, .large])
        .screenBackground()
    }

    // MARK: Quizzes

    private func quiz(title: String, options: [String], key: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Text(.init(L(title)))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(AppColor.textPrimary)
                .lineSpacing(3)
                .padding(.horizontal, 24)
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    Button {
                        answers[key] = option
                        advanceQuiz()
                    } label: {
                        HStack {
                            Text(L(option))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(AppColor.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppColor.textSecondary)
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 60)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppColor.surface))
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private func advanceQuiz() {
        withAnimation {
            switch step {
            case .quizDoctorAdvised: step = .quizAnxiety
            case .quizAnxiety: step = .quizEverDiagnosed
            case .quizEverDiagnosed: step = .calculationInProgress
            default: break
            }
        }
    }

    // MARK: Calculation

    private var calculation: some View {
        Group {
            if calculationDone {
                VStack(spacing: 18) {
                    Spacer()
                    ZStack {
                        Circle().fill(AppColor.success.opacity(0.14)).frame(width: 130, height: 130)
                        Image(systemName: "checkmark")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(AppColor.success)
                    }
                    Text("All Set")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("Thank you for your patience. You're incredible!")
                        .font(.system(size: 15))
                        .foregroundColor(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                    Button("See Results") {
                        withAnimation { step = .results }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            } else {
                CalculationProgressView {
                    withAnimation { calculationDone = true }
                }
            }
        }
    }

    // MARK: Results

    private var results: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    VStack(spacing: 4) {
                        Text(L("Your Heart Health"))
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(AppColor.textSecondary)
                        Text(.init("**" + L("Risk Score") + "**"))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(AppColor.textPrimary)
                    }
                    .padding(.top, 8)

                    let profile = profileModel.buildProfile(base: appState.profile)
                    VStack(spacing: 0) {
                        resultRow(icon: "scalemass", color: AppColor.orange,
                                  title: "Body Mass Index",
                                  value: L(profile.bmiBand ?? "Not calculated"),
                                  subtitle: profile.bmi.map { String(format: "%.1f", $0) } ?? L("No Data"))
                        Divider().padding(.leading, 56)
                        resultRow(icon: "waveform.path.ecg", color: AppColor.brand,
                                  title: "Blood Pressure",
                                  value: L("No Data"),
                                  subtitle: L("Not recorded"))
                        Divider().padding(.leading, 56)
                        resultRow(icon: "heart", color: AppColor.purple,
                                  title: "Age-Related Risk",
                                  value: L(ageRisk.value),
                                  subtitle: L(ageRisk.subtitle))
                        if answers["anxiety"] == "Often" {
                            Divider().padding(.leading, 56)
                            resultRow(icon: "bolt.heart", color: AppColor.danger,
                                      title: "Stress & Anxiety Risk",
                                      value: L("High"),
                                      subtitle: L("Frequent anxiety"))
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(AppColor.surface))
                    .padding(.top, 4)

                    Text("These results are based on the information you provided and are not a medical diagnosis.")
                        .font(.system(size: 11))
                        .foregroundColor(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)

                    Button("Measure Heart Rate") {
                        appState.autoPresentMeasure = true
                        appState.completePostOnboarding()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 6)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 20)
            }
        }
    }

    private var ageRisk: (value: String, subtitle: String) {
        guard let age = profileModel.buildProfile(base: appState.profile).age else {
            return ("No Data", "Age not provided")
        }
        return age <= 39 ? ("Low", "Under 40 years") : ("High", "40 years or older")
    }

    private func resultRow(icon: String, color: Color, title: String, value: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(Circle().fill(color.opacity(0.12)))
            VStack(alignment: .leading, spacing: 3) {
                Text(L(title))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColor.textPrimary)
                Text(L(subtitle))
                    .font(.system(size: 12))
                    .foregroundColor(AppColor.textSecondary)
            }
            Spacer()
            Text(L(value))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColor.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

// MARK: - Calculation progress (§3.11)

struct CalculationProgressView: View {
    let onFinish: () -> Void
    @State private var progress: Double = 0
    @State private var index = 0
    @State private var started = false

    private let messages = [
        "Building your personal health profile…",
        "Reviewing your activity patterns…",
        "Analyzing your heart health data…",
        "Preparing your first health insights…"
    ]

    private let facts = [
        "In about **4–5 days**, your heart pumps a container's worth of blood.",
        "Your heart pumps about **2,000** gallons of blood every day. In one year, that's enough to fill an Olympic-sized swimming pool.",
        "Your body produces over **2 million** red blood cells every second.",
        "In one year, your red blood cells would stretch farther than the average distance to the Moon."
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .stroke(AppColor.separator, lineWidth: 12)
                    .frame(width: 150, height: 150)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AppColor.brandGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(AppColor.textPrimary)
            }
            Text(L(messages[min(index, messages.count - 1)]))
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(AppColor.textPrimary)
                .multilineTextAlignment(.center)
                .frame(height: 48)
                .padding(.horizontal, 24)
            VStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(AppColor.warning)
                Text(.init(L(facts[min(index, facts.count - 1)])))
                    .font(.system(size: 13))
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 36)
            }
            .frame(height: 110)
            Spacer()
        }
        .onAppear {
            guard !started else { return }
            started = true
            progress = 0
            withAnimation(.linear(duration: 8)) { progress = 1 }
            for step in 0..<4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * 2) {
                    withAnimation { index = step }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.2) {
                onFinish()
            }
        }
    }
}
