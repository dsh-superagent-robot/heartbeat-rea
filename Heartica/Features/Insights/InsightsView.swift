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
    static let englishSections: [ArticleSection] = [
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

    static let chineseSections: [ArticleSection] = [
        ArticleSection(id: "hrv-basics", title: "心率变异性（HRV）：基础", articles: [
            Article(id: "hrv.basics.what_is_hrv",
                    title: "什么是心率变异性？",
                    subtitle: "HRV 入门",
                    symbol: "waveform.path.ecg",
                    color: Color(red: 0.42, green: 0.82, blue: 0.80),
                    section: "HRV 基础",
                    pages: [
                        ArticlePage(title: "什么是心率变异性？", subtitle: "HRV 入门",
                                    body: "心率变异性（HRV）指连续心跳之间时间间隔的细微变化。即使在静息状态下，心跳也不是像节拍器一样完全等距。\n\n这种变化由自主神经系统调控，它平衡着交感神经（战斗或逃跑）与副交感神经（休息与消化）。恢复良好的身体通常表现出更高的变异性。"),
                        ArticlePage(title: "为什么重要", subtitle: "了解恢复状态的窗口",
                                    body: "HRV 反映自主神经平衡，因此是观察恢复、压力和准备度的重要信号。睡眠不足、生病、饮酒或高强度训练后，变异性可能下降。\n\n单次读数会有波动。最有价值的是你自己的基线：在相近时间、相似条件下测量，并关注趋势。")
                    ],
                    link: URL(string: "https://my.clevelandclinic.org/health/symptoms/21773-heart-rate-variability-hrv"),
                    isPopular: false, minutes: 3),
            Article(id: "hrv.basics.what_affects_hrv",
                    title: "影响 HRV 的因素",
                    subtitle: "睡眠、压力、训练等",
                    symbol: "bed.double.fill",
                    color: Color(red: 0.51, green: 0.70, blue: 0.85),
                    section: "HRV 基础",
                    pages: [
                        ArticlePage(title: "影响 HRV 的因素", subtitle: "多种输入，一个信号",
                                    body: "HRV 会响应几乎所有因素：睡眠时长与质量、心理压力、咖啡因和酒精、水分、疾病、训练负荷，甚至一天中的时间。\n\n因此情境标签非常重要。把测量标记为睡醒后、运动后或压力中，可以让你在相似条件下进行比较。"),
                        ArticlePage(title: "建立基线", subtitle: "重视一致性，而非完美",
                                    body: "尽量每天在相近时间测量，例如醒来后。尽量使用相同的模式和姿势。\n\n坚持几周后，你会得到自己的参考范围。范围内的变化通常是正常波动，持续偏移才值得关注。")
                    ],
                    link: nil, isPopular: true, minutes: 4)
        ]),
        ArticleSection(id: "hrv-explained", title: "心率变异性深度解析", articles: [
            Article(id: "hrv.explained.psychological_aspects",
                    title: "HRV 与心理状态",
                    subtitle: "身心相连",
                    symbol: "brain.head.profile",
                    color: Color(red: 0.66, green: 0.51, blue: 0.85),
                    section: "HRV 深度解析",
                    pages: [
                        ArticlePage(title: "HRV 与心理状态", subtitle: "身心相连",
                                    body: "研究将 HRV 视为情绪调节和认知灵活性的指标。静息时较高的变异性通常与更好的抗压能力相关。\n\n呼吸练习、正念和良好睡眠有助于副交感神经活动。效果是渐进的，请关注周平均值。"),
                        ArticlePage(title: "理解变化", subtitle: "情境决定意义",
                                    body: "单次低读数可能只是熬夜或高强度运动后的结果。如果连续多天偏低，则可能提示累积负荷。\n\n结合标签和趋势，判断变化是一次性的还是模式性的。")
                    ],
                    link: URL(string: "https://en.wikipedia.org/wiki/Heart_rate_variability"),
                    isPopular: false, minutes: 4)
        ]),
        ArticleSection(id: "hrv-context", title: "结合情境理解 HRV", articles: [
            Article(id: "hrv.context.rest_and_recovery",
                    title: "休息与恢复",
                    subtitle: "读懂身体的信号",
                    symbol: "moon.stars.fill",
                    color: Color(red: 0.51, green: 0.53, blue: 0.85),
                    section: "结合情境",
                    pages: [
                        ArticlePage(title: "休息与恢复", subtitle: "读懂身体的信号",
                                    body: "休息测量是你的基线。睡前、醒来后或冥想后测量，可以反映身体的恢复程度。\n\n休息测量的上升趋势通常意味着恢复改善。持续下降则可能是优先睡眠、减少负荷的早期信号。"),
                        ArticlePage(title: "休息分组", subtitle: "睡前 · 睡醒后 · 冥想后",
                                    body: "Heartica 将休息相关测量归入“休息与恢复”分组。比较同一分组内的测量，数据更有意义。\n\n每周进行几次休息测量，有助于建立稳定的个人范围。")
                    ],
                    link: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC11439429/"),
                    isPopular: true, minutes: 4),
            Article(id: "hrv.context.food_and_metabolism",
                    title: "饮食与代谢",
                    subtitle: "进餐如何影响脉搏",
                    symbol: "fork.knife",
                    color: Color(red: 0.83, green: 0.81, blue: 0.40),
                    section: "结合情境",
                    pages: [
                        ArticlePage(title: "饮食与代谢", subtitle: "进餐如何影响脉搏",
                                    body: "进餐后，血液会更多地流向消化系统，心率也常会略微上升。吃得过多或过于油腻时，影响可能更明显。\n\n在相近时间进行餐前和餐后测量，了解身体的反应。"),
                        ArticlePage(title: "血糖与心率", subtitle: "相互关联的图景",
                                    body: "血糖变化会影响你的感受和心脏反应。把血糖与心率记录在一起，有助于发现关联。\n\n这些内容仅供教育参考，不构成诊断。如有疑虑，请咨询医疗专业人员。")
                    ],
                    link: nil, isPopular: true, minutes: 3)
        ]),
        ArticleSection(id: "ppg", title: "光电容积脉搏波（PPG）说明", articles: [
            Article(id: "ppg.explained.fundamentals",
                    title: "相机如何测量脉搏",
                    subtitle: "口袋里的 PPG",
                    symbol: "camera.fill",
                    color: Color(red: 0.52, green: 0.83, blue: 0.50),
                    section: "PPG",
                    pages: [
                        ArticlePage(title: "相机如何测量脉搏", subtitle: "口袋里的 PPG",
                                    body: "光电容积脉搏波（PPG）通过让光线穿过指尖来工作。每次心跳时，血容量会轻微变化，吸收的光也随之变化。\n\n相机会追踪红光通道中的细微变化，应用将其转换为逐拍间隔。"),
                        ArticlePage(title: "获得清晰信号", subtitle: "光线、稳定与压力",
                                    body: "让指尖保持充足光线并稳定不动。按压过重会减少血流，降低信号质量。\n\n如果读数失败，放松手掌，完整遮住摄像头后重试。")
                    ],
                    link: URL(string: "https://en.wikipedia.org/wiki/Photoplethysmogram"),
                    isPopular: true, minutes: 3)
        ]),
        ArticleSection(id: "ecg", title: "心电图轻松入门", articles: [
            Article(id: "ecg.about",
                    title: "心电图入门",
                    subtitle: "心电图能看到什么",
                    symbol: "waveform.path",
                    color: Color(red: 0.85, green: 0.51, blue: 0.53),
                    section: "心电图",
                    pages: [
                        ArticlePage(title: "心电图入门", subtitle: "心电图能看到什么",
                                    body: "心电图记录心脏的电活动。每个波形对应心脏周期中的不同阶段：心房除极、心室除极和复极。\n\n与 PPG 不同，心电图直接测量电信号，可发现节律异常。"),
                        ArticlePage(title: "何时就医", subtitle: "重视症状",
                                    body: "胸痛、晕厥、异常气短或突然的心律不齐都应及时就医。\n\nHeartica 是健康工具，不能诊断心脏疾病。")
                    ],
                    link: URL(string: "https://www.mayoclinic.org/tests-procedures/ekg/about/pac-20384983"),
                    isPopular: true, minutes: 4)
        ]),
        ArticleSection(id: "arrhythmia", title: "了解心律失常", articles: [
            Article(id: "arrhythmia.types",
                    title: "认识心律失常",
                    subtitle: "当节律发生变化",
                    symbol: "heart.slash",
                    color: Color(red: 0.85, green: 0.51, blue: 0.70),
                    section: "心律失常",
                    pages: [
                        ArticlePage(title: "认识心律失常", subtitle: "当节律发生变化",
                                    body: "心律失常指心脏节律异常。有些类型无害且常见，有些则需要评估。\n\n症状可能包括心悸、头晕、疲劳或气短。如持续出现变化，请就医。"),
                        ArticlePage(title: "追踪，而非诊断", subtitle: "关注趋势，不必恐慌",
                                    body: "可穿戴设备能帮助发现模式，但不能替代临床心电图。如有疑虑，请把记录的数据带给医生。")
                    ],
                    link: URL(string: "https://www.heart.org/en/health-topics/arrhythmia/about-arrhythmia"),
                    isPopular: false, minutes: 3)
        ]),
        ArticleSection(id: "heart-attack", title: "心脏病发作基础", articles: [
            Article(id: "heartattack.signs",
                    title: "识别心脏病发作信号",
                    subtitle: "及时行动",
                    symbol: "cross.case.fill",
                    color: Color(red: 0.85, green: 0.66, blue: 0.51),
                    section: "心脏病发作",
                    pages: [
                        ArticlePage(title: "识别心脏病发作信号", subtitle: "及时行动",
                                    body: "心脏病发作的症状可能包括胸部压迫感或疼痛、疼痛放射至手臂、下颌或背部、气短、冷汗、恶心或头晕。\n\n如果怀疑心脏病发作，请立即呼叫急救，不要等待症状自行缓解。"),
                        ArticlePage(title: "康复与监测", subtitle: "循序渐进",
                                    body: "康复方案因人而异，应听从医疗团队指导。适度活动、按时用药和定期复查是常见重点。")
                    ],
                    link: URL(string: "https://www.heart.org/en/health-topics/heart-attack/about-heart-attacks"),
                    isPopular: true, minutes: 3)
        ]),
        ArticleSection(id: "sleep", title: "健康睡眠指南", articles: [
            Article(id: "sleep.benefits",
                    title: "睡眠与心脏",
                    subtitle: "每晚的修复",
                    symbol: "bed.double.fill",
                    color: Color(red: 0.51, green: 0.70, blue: 0.85),
                    section: "睡眠",
                    pages: [
                        ArticlePage(title: "睡眠与心脏", subtitle: "每晚的修复",
                                    body: "睡眠是身体修复的时间：心率与血压通常会下降，自主神经系统转向休息状态。\n\n规律的作息、黑暗凉爽的卧室有助于更好的恢复。"),
                        ArticlePage(title: "围绕睡眠测量", subtitle: "睡前与醒来",
                                    body: "睡前和醒来后各测一次。对比这组数据，可以了解身体夜间的恢复情况。\n\n尽量保持时间一致，趋势会更容易解读。")
                    ],
                    link: URL(string: "https://www.nhlbi.nih.gov/resources/your-guide-healthy-sleep"),
                    isPopular: true, minutes: 3)
        ]),
        ArticleSection(id: "stress", title: "压力与身体机能", articles: [
            Article(id: "stress.brain",
                    title: "压力与身体",
                    subtitle: "累积的负荷",
                    symbol: "bolt.heart.fill",
                    color: Color(red: 0.83, green: 0.53, blue: 0.85),
                    section: "压力",
                    pages: [
                        ArticlePage(title: "压力与身体", subtitle: "累积的负荷",
                                    body: "急性压力是正常且有用的。但长期压力会让交感神经持续活跃，影响睡眠、情绪、血压和心率变异性。\n\n在压力前、中、后测量，可以了解你的反应和恢复速度。"),
                        ArticlePage(title: "重新平衡", subtitle: "有用的小工具",
                                    body: "缓慢呼吸、短暂散步、接触日光以及与信任的人相处，都能降低紧张水平。什么有效因人而异——测量后再判断。")
                    ],
                    link: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC5579396/"),
                    isPopular: true, minutes: 4)
        ]),
        ArticleSection(id: "activity", title: "身体活动指南（AHA）", articles: [
            Article(id: "activity.benefits",
                    title: "运动就是良药",
                    subtitle: "为什么活动很重要",
                    symbol: "figure.run",
                    color: Color(red: 0.52, green: 0.83, blue: 0.50),
                    section: "活动",
                    pages: [
                        ArticlePage(title: "运动就是良药", subtitle: "为什么活动很重要",
                                    body: "规律的身体活动有益心血管健康、情绪和睡眠。从久坐转为适度活动，往往能获得最大的健康收益。\n\n在有氧运动和力量训练之间取得平衡，并根据自身状况调整。"),
                        ArticlePage(title: "运动与 HRV", subtitle: "负荷与恢复",
                                    body: "高强度训练后 HRV 可能暂时下降，这是恢复过程的一部分。运动前后各测一次，了解身体的反应。\n\n如果 HRV 持续偏低并伴随疲劳，应考虑休息。")
                    ],
                    link: URL(string: "https://www.heart.org/en/healthy-living/fitness/fitness-basics/aha-recs-for-physical-activity-in-adults"),
                    isPopular: true, minutes: 4)
        ])
    ]

    static var sections: [ArticleSection] {
        LanguageStore.shared.effective == .chinese ? chineseSections : englishSections
    }

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
                Text(L("Insights"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColor.textPrimary)
                Text(L("Learn what your heart is telling you"))
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
                    Text(L(appState.isPremium ? "Your month at a glance" : "Unlock Premium to see full trends"))
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
            SectionTitle(title: L("Popular"))
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
                    Text(LF("%d min read", article.minutes))
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
