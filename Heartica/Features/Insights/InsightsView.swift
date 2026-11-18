import Combine
import SwiftUI

struct ArticlePage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let body: String
}

struct Article: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let color: Color
    let section: String
    let pages: [ArticlePage]
    let link: URL?
    let isPopular: Bool
    let minutes: Int
}

struct ArticleSection: Identifiable {
    let id: String
    let title: String
    let articles: [Article]
}

enum ReadArticlesStore {
    private static let key = "readArticles"

    static var readIDs: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    static var count: Int { readIDs.count }

    static func isRead(_ id: String) -> Bool { readIDs.contains(id) }

    static func markRead(_ id: String) {
        var ids = readIDs
        ids.insert(id)
        UserDefaults.standard.set(Array(ids), forKey: key)
    }
}

enum InsightsContent {
    static let sections: [ArticleSection] = [
        ArticleSection(id: "hrv-basics", title: "Heart Rate Variability (HRV): Basics", articles: [
            Article(id: "hrv.basics.what_is_hrv",
                    title: "What Is Heart Rate Variability?",
                    subtitle: "The basics of HRV",
                    symbol: "waveform.path.ecg",
                    color: Color(red: 0.42, green: 0.82, blue: 0.80),
                    section: "HRV Basics",
                    pages: [
                        ArticlePage(title: "What Is Heart Rate Variability?",
                                    subtitle: "The basics of HRV",
                                    body: "Heart rate variability (HRV) is the tiny variation in the time between consecutive heartbeats. A heart does not beat like a metronome — even at rest, the interval between beats constantly shifts.\n\nThat variation is driven by the autonomic nervous system, which balances the sympathetic (fight-or-flight) and parasympathetic (rest-and-digest) branches. A healthy, well-recovered body usually shows more variability, not less."),
                        ArticlePage(title: "Why It Matters",
                                    subtitle: "A window into recovery",
                                    body: "Because HRV reflects autonomic balance, it is a useful daily signal for recovery, stress and readiness. Lower variability can follow poor sleep, illness, alcohol or intense training.\n\nSingle readings are noisy. The most useful pattern is your own baseline: measure at similar times, with similar conditions, and compare trends rather than isolated numbers.")
                    ],
                    link: URL(string: "https://my.clevelandclinic.org/health/symptoms/21773-heart-rate-variability-hrv"),
                    isPopular: false, minutes: 3),
            Article(id: "hrv.basics.what_affects_hrv",
                    title: "What Affects HRV?",
                    subtitle: "Sleep, stress, training and more",
                    symbol: "bed.double.fill",
                    color: Color(red: 0.51, green: 0.70, blue: 0.85),
                    section: "HRV Basics",
                    pages: [
                        ArticlePage(title: "What Affects HRV?",
                                    subtitle: "Many inputs, one signal",
                                    body: "HRV responds to almost everything: sleep duration and quality, psychological stress, caffeine and alcohol, hydration, illness, training load and even the time of day.\n\nThis is why context tags are so valuable. Tagging a measurement as After Sleep, After Exercise or During Stress lets you compare like with like."),
                        ArticlePage(title: "Build Your Baseline",
                                    subtitle: "Consistency over perfection",
                                    body: "Measure at roughly the same time each day — morning readings after waking are a popular choice. Use the same mode and posture where possible.\n\nAfter a couple of weeks you will have a personal range. Changes within that range are usually normal noise; sustained shifts are worth noticing.")
                    ],
                    link: nil, isPopular: true, minutes: 4)
        ]),
        ArticleSection(id: "hrv-explained", title: "Heart Rate Variability Explained (Deep Dive)", articles: [
            Article(id: "hrv.explained.psychological_aspects",
                    title: "The Psychology of HRV",
                    subtitle: "Mind and heart",
                    symbol: "brain.head.profile",
                    color: Color(red: 0.66, green: 0.51, blue: 0.85),
                    section: "HRV Explained",
                    pages: [
                        ArticlePage(title: "The Psychology of HRV",
                                    subtitle: "Mind and heart",
                                    body: "HRV has been studied as a marker of emotional regulation and cognitive flexibility. Higher variability at rest is often associated with better stress resilience.\n\nBreathing exercises, mindfulness and good sleep can support parasympathetic activity. The effect is gradual, so look at weekly averages."),
                        ArticlePage(title: "Interpreting Changes",
                                    subtitle: "Context is everything",
                                    body: "A single low reading can follow a late night or a hard workout. Persistently low readings across several days can indicate accumulated load.\n\nUse the app's tags and trends to understand whether a change is a one-off or a pattern.")
                    ],
                    link: URL(string: "https://en.wikipedia.org/wiki/Heart_rate_variability"),
                    isPopular: false, minutes: 4)
        ]),
        ArticleSection(id: "hrv-context", title: "HRV in Context: How to Interpret Changes Correctly", articles: [
            Article(id: "hrv.context.rest_and_recovery",
                    title: "Rest and Recovery",
                    subtitle: "Reading your body's signals",
                    symbol: "moon.stars.fill",
                    color: Color(red: 0.51, green: 0.53, blue: 0.85),
                    section: "HRV in Context",
                    pages: [
                        ArticlePage(title: "Rest and Recovery",
                                    subtitle: "Reading your body's signals",
                                    body: "Rest measurements are your baseline. Taken before sleep, after waking, or after meditation, they show how well your body has recovered.\n\nA rising trend across rest measurements usually points to improving recovery. A falling trend can be an early signal to prioritise sleep and reduce load."),
                        ArticlePage(title: "The Rest Cluster",
                                    subtitle: "Before Sleep · After Sleep · After Meditation",
                                    body: "Heartica groups rest-related measurements into the Rest & Recovery cluster. Comparing measurements inside the same cluster keeps your data meaningful.\n\nAim for a few rest readings each week to build a stable personal range.")
                    ],
                    link: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC11439429/"),
                    isPopular: true, minutes: 4),
            Article(id: "hrv.context.food_and_metabolism",
                    title: "Food and Metabolism",
                    subtitle: "How meals affect your pulse",
                    symbol: "fork.knife",
                    color: Color(red: 0.83, green: 0.81, blue: 0.40),
                    section: "HRV in Context",
                    pages: [
                        ArticlePage(title: "Food and Metabolism",
                                    subtitle: "How meals affect your pulse",
                                    body: "After a meal, blood flow shifts toward the digestive system and heart rate often rises slightly. Large or heavy meals can have a bigger effect.\n\nMeasure Before Meal and After Meal at comparable times to learn how your body responds."),
                        ArticlePage(title: "Blood Sugar and Heart Rate",
                                    subtitle: "A connected picture",
                                    body: "Blood sugar changes can influence how you feel and how your heart responds. Logging glucose alongside heart rate helps connect the dots.\n\nThis is educational information, not a diagnosis. Discuss concerns with a healthcare professional.")
                    ],
                    link: nil, isPopular: true, minutes: 3)
        ]),
        ArticleSection(id: "ppg", title: "Photoplethysmography (PPG) Explained", articles: [
            Article(id: "ppg.explained.fundamentals",
                    title: "How Your Camera Measures Pulse",
                    subtitle: "PPG in your pocket",
                    symbol: "camera.fill",
                    color: Color(red: 0.52, green: 0.83, blue: 0.50),
                    section: "PPG",
                    pages: [
                        ArticlePage(title: "How Your Camera Measures Pulse",
                                    subtitle: "PPG in your pocket",
                                    body: "Photoplethysmography (PPG) works by shining light through your fingertip. With each heartbeat, blood volume changes slightly and the amount of light absorbed changes too.\n\nThe camera tracks those tiny variations in the red channel and the app converts them into beat-to-beat intervals."),
                        ArticlePage(title: "Getting a Clean Signal",
                                    subtitle: "Light, stillness and pressure",
                                    body: "Keep your fingertip well lit and still. Pressing too hard reduces blood flow and degrades the signal.\n\nIf the reading fails, relax your hand, cover the camera fully and try again.")
                    ],
                    link: URL(string: "https://en.wikipedia.org/wiki/Photoplethysmogram"),
                    isPopular: true, minutes: 3)
        ]),
        ArticleSection(id: "ecg", title: "ECG Made Simple", articles: [
            Article(id: "ecg.about",
                    title: "ECG Made Simple",
                    subtitle: "What an ECG shows",
                    symbol: "waveform.path",
                    color: Color(red: 0.85, green: 0.51, blue: 0.53),
                    section: "ECG",
                    pages: [
                        ArticlePage(title: "ECG Made Simple",
                                    subtitle: "What an ECG shows",
                                    body: "An electrocardiogram records the electrical activity of the heart. Each wave corresponds to a step in the cardiac cycle: atrial depolarisation, ventricular depolarisation and repolarisation.\n\nUnlike PPG, an ECG measures electrical signals directly and can reveal rhythm abnormalities."),
                        ArticlePage(title: "When to Seek Advice",
                                    subtitle: "Symptoms matter",
                                    body: "Chest pain, fainting, unusual shortness of breath or a sudden irregular heartbeat deserve prompt medical attention.\n\nHeartica is a wellness tool and does not diagnose heart conditions.")
                    ],
                    link: URL(string: "https://www.mayoclinic.org/tests-procedures/ekg/about/pac-20384983"),
                    isPopular: true, minutes: 4)
        ]),
        ArticleSection(id: "arrhythmia", title: "About Arrhythmia", articles: [
            Article(id: "arrhythmia.types",
                    title: "Understanding Arrhythmia",
                    subtitle: "When the rhythm changes",
                    symbol: "heart.slash",
                    color: Color(red: 0.85, green: 0.51, blue: 0.70),
                    section: "Arrhythmia",
                    pages: [
                        ArticlePage(title: "Understanding Arrhythmia",
                                    subtitle: "When the rhythm changes",
                                    body: "Arrhythmia is an abnormal heart rhythm. Some types are harmless and common; others need assessment.\n\nSymptoms may include palpitations, dizziness, fatigue or breathlessness. If you notice persistent changes, seek medical advice."),
                        ArticlePage(title: "Track, Don't Diagnose",
                                    subtitle: "Use trends, not fear",
                                    body: "Wearables can help you notice patterns, but they cannot replace a clinical ECG. Bring any concerns and your recorded data to a clinician.")
                    ],
                    link: URL(string: "https://www.heart.org/en/health-topics/arrhythmia/about-arrhythmia"),
                    isPopular: false, minutes: 3)
        ]),
        ArticleSection(id: "heart-attack", title: "Heart Attack Basics", articles: [
            Article(id: "heartattack.signs",
                    title: "Recognising the Signs",
                    subtitle: "Act fast",
                    symbol: "cross.case.fill",
                    color: Color(red: 0.85, green: 0.66, blue: 0.51),
                    section: "Heart Attack",
                    pages: [
                        ArticlePage(title: "Recognising the Signs",
                                    subtitle: "Act fast",
                                    body: "Heart attack symptoms can include chest pressure or pain, pain spreading to the arm, jaw or back, shortness of breath, cold sweat, nausea or light-headedness.\n\nIf you suspect a heart attack, call emergency services immediately. Do not wait to see whether symptoms pass."),
                        ArticlePage(title: "Recovery and Monitoring",
                                    subtitle: "Small steps",
                                    body: "Recovery is individual and should be guided by your care team. Gentle activity, medication adherence and regular check-ins are common themes.")
                    ],
                    link: URL(string: "https://www.heart.org/en/health-topics/heart-attack/about-heart-attacks"),
                    isPopular: true, minutes: 3)
        ]),
        ArticleSection(id: "sleep", title: "Your Guide to Healthy Sleep", articles: [
            Article(id: "sleep.benefits",
                    title: "Sleep and Your Heart",
                    subtitle: "The nightly reset",
                    symbol: "bed.double.fill",
                    color: Color(red: 0.51, green: 0.70, blue: 0.85),
                    section: "Sleep",
                    pages: [
                        ArticlePage(title: "Sleep and Your Heart",
                                    subtitle: "The nightly reset",
                                    body: "Sleep is when recovery happens: heart rate and blood pressure usually dip, and the autonomic nervous system shifts toward rest.\n\nRegular sleep timing and a dark, cool room support better recovery."),
                        ArticlePage(title: "Measure Around Sleep",
                                    subtitle: "Before and after",
                                    body: "Take a measurement before bed and after waking. Comparing the pair shows how your body recovered overnight.\n\nKeep the timing consistent — it makes trends far easier to read.")
                    ],
                    link: URL(string: "https://www.nhlbi.nih.gov/resources/your-guide-healthy-sleep"),
                    isPopular: true, minutes: 3)
        ]),
        ArticleSection(id: "stress", title: "Stress and Body Function", articles: [
            Article(id: "stress.brain",
                    title: "Stress and the Body",
                    subtitle: "The allostatic load",
                    symbol: "bolt.heart.fill",
                    color: Color(red: 0.83, green: 0.53, blue: 0.85),
                    section: "Stress",
                    pages: [
                        ArticlePage(title: "Stress and the Body",
                                    subtitle: "The allostatic load",
                                    body: "Acute stress is normal and useful. Chronic stress, however, keeps the sympathetic nervous system active and can affect sleep, mood, blood pressure and heart rate variability.\n\nMeasuring before, during and after stressful moments reveals your personal response and recovery speed."),
                        ArticlePage(title: "Resetting",
                                    subtitle: "Small tools that help",
                                    body: "Slow breathing, a short walk, daylight and time with people you trust can lower arousal. What works is personal — measure and see.")
                    ],
                    link: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC5579396/"),
                    isPopular: true, minutes: 4)
        ]),
        ArticleSection(id: "activity", title: "Physical Activity Guidelines (by AHA)", articles: [
            Article(id: "activity.benefits",
                    title: "Movement Is Medicine",
                    subtitle: "Why activity matters",
                    symbol: "figure.run",
                    color: Color(red: 0.52, green: 0.83, blue: 0.50),
                    section: "Activity",
                    pages: [
                        ArticlePage(title: "Movement Is Medicine",
                                    subtitle: "Why activity matters",
                                    body: "Regular physical activity supports cardiovascular health, mood and sleep. The greatest benefit often comes from moving from inactivity to even modest activity.\n\nAim for a mix of aerobic movement and strength work, adapted to your health and abilities."),
                        ArticlePage(title: "Exercise and HRV",
                                    subtitle: "Load versus recovery",
                                    body: "Hard training can lower HRV temporarily while you recover. A Before Exercise and After Exercise pair shows how your body responds.\n\nPersistently suppressed HRV alongside fatigue is a signal to rest.")
                    ],
                    link: URL(string: "https://www.heart.org/en/healthy-living/fitness/fitness-basics/aha-recs-for-physical-activity-in-adults"),
                    isPopular: true, minutes: 4)
        ])
    ]

    static var allArticles: [Article] {
        sections.flatMap(\.articles)
    }

    static var popular: [Article] {
        allArticles.filter(\.isPopular)
    }
}

struct InsightsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selected: Article?
    @State private var showMonthly = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                if !appState.isPremium {
                    proBanner
                }
                monthlyCard
                popularSection
                ForEach(InsightsContent.sections) { section in
                    sectionView(section)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .screenBackground()
        .navigationBarHidden(true)
        .fullScreenCover(item: $selected) { article in
            ArticleReaderView(article: article)
                .environmentObject(appState)
        }
        .sheet(isPresented: $showMonthly) {
            MonthlyInsightsView()
                .environmentObject(appState)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Insights")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColor.textPrimary)
                Text("Learn what your heart is telling you")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private var proBanner: some View {
        Button {
            appState.presentPaywall(source: "insights")
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundColor(AppColor.warning)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Unlock All Features")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("Try all premium features for free")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.65))
                }
                Spacer()
                Text("Try Premium for Free")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(AppColor.brand))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [Color(red: 0.12, green: 0.10, blue: 0.16),
                                                  Color(red: 0.28, green: 0.10, blue: 0.20)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            )
        }
        .buttonStyle(PressableCardStyle())
    }

    private var monthlyCard: some View {
        Button {
            showMonthly = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "calendar")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(AppColor.purple)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(AppColor.purple.opacity(0.12)))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Monthly Insights")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColor.textPrimary)
                    Text(appState.isPremium ? "Your month at a glance" : "Unlock Premium to see full trends")
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.textSecondary)
                }
                Spacer()
                if !appState.isPremium {
                    Image(systemName: "lock.fill")
                        .foregroundColor(AppColor.textSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColor.textSecondary)
            }
            .card(padding: 14, radius: 20)
        }
        .buttonStyle(PressableCardStyle())
    }

    private var popularSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Popular")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(InsightsContent.popular) { article in
                        Button {
                            selected = article
                        } label: {
                            articleCard(article, compact: true)
                        }
                        .buttonStyle(PressableCartStyle())
                    }
                }
            }
        }
    }

    private func sectionView(_ section: ArticleSection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: section.title)
            VStack(spacing: 10) {
                ForEach(section.articles) { article in
                    Button {
                        selected = article
                    } label: {
                        articleCard(article, compact: false)
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
        }
    }

    private func articleCard(_ article: Article, compact: Bool) -> some View {
        let read = ReadArticlesStore.isRead(article.id)
        return ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [article.color.opacity(0.85), article.color.opacity(0.35)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: article.symbol)
                .font(.system(size: compact ? 38 : 52, weight: .light))
                .foregroundColor(.white.opacity(0.16))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(14)
            VStack(alignment: .leading, spacing: 5) {
                Text(article.section.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.7)
                    .foregroundColor(.white.opacity(0.65))
                Text(article.title)
                    .font(.system(size: compact ? 15 : 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                    Text("\(article.minutes) min read")
                    if read {
                        Image(systemName: "checkmark.circle.fill")
                    }
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            }
            .padding(14)
        }
        .frame(width: compact ? 210 : nil, height: compact ? 150 : 132)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct PressableCartStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
    }
}

// MARK: - Reader

struct ArticleReaderView: View {
    @Environment(\.dismiss) private var dismiss
    let article: Article

    @State private var pageIndex = 0
    @State private var progress: CGFloat = 0
    @State private var paused = false
    @State private var timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    private var page: ArticlePage { article.pages[min(pageIndex, article.pages.count - 1)] }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [article.color.opacity(0.95), article.color.opacity(0.55),
                                        Color.black.opacity(0.92)],
                               startPoint: .topLeading, endPoint: .bottom)
                    .ignoresSafeArea()
                Image(systemName: article.symbol)
                    .font(.system(size: 260, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.06))
                    .offset(x: 90, y: -120)

                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    VStack(alignment: .leading, spacing: 12) {
                        Text(page.title)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(page.subtitle)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Text(page.body)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.88))
                            .lineSpacing(6)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    Spacer()
                    bottomBar
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in paused = true }
                    .onEnded { value in
                        paused = false
                        guard abs(value.translation.width) < 12, abs(value.translation.height) < 12 else { return }
                        if value.location.x < geometry.size.width * 0.3 {
                            previousPage()
                        } else {
                            nextPage()
                        }
                    }
            )
        }
        .onReceive(timer) { _ in
            guard !paused else { return }
            progress += 0.05 / 7
            if progress >= 1 { nextPage(resetProgress: true) }
        }
        .onAppear {
            pageIndex = 0
            progress = 0
        }
        .onDisappear {
            if pageIndex >= article.pages.count - 1 { ReadArticlesStore.markRead(article.id) }
        }
        .onChange(of: pageIndex) { index in
            if index >= article.pages.count - 1 { ReadArticlesStore.markRead(article.id) }
        }
    }

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(article.pages.indices, id: \.self) { index in
                    GeometryReader { geo in
                        Capsule()
                            .fill(Color.white.opacity(0.25))
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white)
                                    .frame(width: geo.size.width * barProgress(index))
                            }
                    }
                    .frame(height: 3)
                }
            }
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.black.opacity(0.3)))
                }
                Spacer()
                if let link = article.link {
                    Link(destination: link) {
                        Text("Source")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color.black.opacity(0.3)))
                    }
                }
                ShareLink(item: "\(article.title) — Heartica") {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.black.opacity(0.3)))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func barProgress(_ index: Int) -> CGFloat {
        if index < pageIndex { return 1 }
        if index == pageIndex { return progress }
        return 0
    }

    private var bottomBar: some View {
        HStack {
            Image(systemName: "heart.fill")
                .font(.system(size: 11))
            Text("Heartica")
                .font(.system(size: 11, weight: .semibold))
            Spacer()
            Text("\(pageIndex + 1)/\(article.pages.count)")
                .font(.system(size: 11, weight: .medium))
            Text("Tap to continue")
                .font(.system(size: 10))
                .opacity(0.5)
        }
        .foregroundColor(.white.opacity(0.6))
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private func nextPage(resetProgress: Bool = false) {
        if pageIndex >= article.pages.count - 1 {
            ReadArticlesStore.markRead(article.id)
            dismiss()
            return
        }
        pageIndex += 1
        progress = 0
    }

    private func previousPage() {
        guard pageIndex > 0 else { return }
        pageIndex -= 1
        progress = 0
    }
}
