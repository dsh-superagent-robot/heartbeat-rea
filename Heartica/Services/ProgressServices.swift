import Foundation

// MARK: - Shared progress metrics (§19, §20)

@MainActor
enum ProgressMetrics {
    static var measurements: [HRMeasurement] { HealthDataStore.shared.measurements() }

    static var measurementCount: Int { measurements.count }

    static var distinctDays: Int {
        Set(measurements.map { Calendar.current.startOfDay(for: $0.time) }).count
    }

    static func measurements(withTag tag: String) -> [HRMeasurement] {
        measurements.filter { $0.tagId == tag }
    }

    static func dayCount(forTag tag: String) -> Int {
        Set(measurements(withTag: tag).map { Calendar.current.startOfDay(for: $0.time) }).count
    }

    static var taggedCount: Int {
        measurements.filter { $0.tagId != nil }.count
    }

    static var aiCommentCount: Int {
        UserDefaults.standard.integer(forKey: "aiCommentsVol")
    }

    static func incrementAIComments() {
        UserDefaults.standard.set(aiCommentCount + 1, forKey: "aiCommentsVol")
    }

    static var articleCount: Int { ReadArticlesStore.count }

    static func articleRead(_ referenceId: String?) -> Int {
        guard let referenceId else { return 0 }
        var normalized = referenceId
        if normalized.hasPrefix("article.") { normalized.removeFirst("article.".count) }
        if normalized.hasSuffix(".title") { normalized.removeLast(".title".count) }
        return ReadArticlesStore.readIDs.contains(normalized) ? 1 : 0
    }

    static var appleHealthConnected: Bool {
        UserDefaults.standard.bool(forKey: "appleHealth.connected")
    }

    static func tagCount(_ id: String) -> Int { measurements(withTag: id).count }

    static var allTagsMinCount: Int {
        PresetTag.all.map { tagCount($0.id) }.min() ?? 0
    }

    static var allTagGroupsCount: Int {
        let clusters: Set<String> = Set(measurements.compactMap { measurement in
            guard let id = measurement.tagId,
                  let tag = PresetTag.all.first(where: { $0.id == id }) else { return nil }
            return tag.cluster == "general" ? nil : tag.cluster
        })
        return clusters.count
    }

    // MARK: Pairs

    enum PairType {
        case sleep, meditation, exercise, stress, meal

        var beforeTags: [String] {
            switch self {
            case .sleep: return ["sleep-before"]
            case .meditation: return ["relax-before"]
            case .exercise: return ["activity-before"]
            case .stress: return ["stress-before", "stress-during"]
            case .meal: return ["eating-before"]
            }
        }

        var afterTags: [String] {
            switch self {
            case .sleep: return ["sleep-after"]
            case .meditation: return ["relax-after"]
            case .exercise: return ["activity-after"]
            case .stress: return ["stress-after"]
            case .meal: return ["eating-after"]
            }
        }

        var window: TimeInterval {
            self == .sleep ? 12 * 3600 : 3 * 3600
        }
    }

    static func pairCount(_ type: PairType) -> Int {
        let before = measurements.filter { m in m.tagId.map(type.beforeTags.contains) ?? false }
        let after = measurements.filter { m in m.tagId.map(type.afterTags.contains) ?? false }
        var used: Set<String> = []
        var count = 0
        for afterItem in after.sorted(by: { $0.time < $1.time }) {
            if let candidate = before
                .filter({ $0.time <= afterItem.time && afterItem.time.timeIntervalSince($0.time) <= type.window })
                .filter({ !used.contains($0.id) })
                .max(by: { $0.time < $1.time }) {
                used.insert(candidate.id)
                count += 1
            }
        }
        return count
    }

    static var anyPairs: Int {
        [PairType.sleep, .meditation, .exercise, .stress, .meal].reduce(0) { $0 + pairCount($1) }
    }

    static var fullSpectrumSets: Int {
        [PairType.sleep, .meditation, .exercise, .stress, .meal]
            .map { pairCount($0) }
            .min() ?? 0
    }

    static var restWeeksWithThree: Int {
        let restTags: Set<String> = ["sleep-before", "sleep-after", "relax-after"]
        let rest = measurements.filter { $0.tagId.map(restTags.contains) ?? false }
        let calendar = Calendar.current
        var weeks: [Date: Int] = [:]
        for item in rest {
            guard let week = calendar.dateInterval(of: .weekOfYear, for: item.time)?.start else { continue }
            weeks[week, default: 0] += 1
        }
        return weeks.values.filter { $0 >= 3 }.count
    }

    static func tagDayStreak(_ tag: String) -> Int {
        let days = Array(Set(measurements(withTag: tag).map { Calendar.current.startOfDay(for: $0.time) }))
            .sorted()
        return longestStreak(days)
    }

    static var dailyStreak: Int {
        let days = Array(Set(measurements.map { Calendar.current.startOfDay(for: $0.time) })).sorted()
        return longestStreak(days)
    }

    static func longestStreak(_ days: [Date]) -> Int {
        guard !days.isEmpty else { return 0 }
        let calendar = Calendar.current
        var best = 1
        var current = 1
        for index in 1..<days.count {
            if let expected = calendar.date(byAdding: .day, value: 1, to: days[index - 1]),
               calendar.isDate(expected, inSameDayAs: days[index]) {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        return best
    }

    static func daysMeasured(last days: Int) -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return Set(measurements.filter { $0.time >= cutoff }
            .map { Calendar.current.startOfDay(for: $0.time) }).count
    }

    static var daysWithHeartica: Int {
        guard let start = UserDefaults.standard.object(forKey: UDKey.achievementStartDate) as? Date,
              let days = Calendar.current.dateComponents([.day], from: start, to: Date()).day else {
            return 1
        }
        return max(1, days + 1)
    }

    // MARK: Heart-age / CSI values

    static var averageHealthIndex: Double? {
        average(\.healthIndex)
    }

    static func average(_ keyPath: KeyPath<HRMeasurement, Double>) -> Double? {
        guard !measurements.isEmpty else { return nil }
        let values = measurements.map { $0[keyPath: keyPath] }
        return values.reduce(0, +) / Double(values.count)
    }
}

// MARK: - Achievements

@MainActor
final class AchievementService: ObservableObject {
    static let shared = AchievementService()

    func value(for seed: AchievementSeed) -> Int {
        switch seed.id {
        case "achv_measure_volume": return ProgressMetrics.measurementCount
        case "achv_days_active": return ProgressMetrics.distinctDays
        case "achv_consistency_window": return ProgressMetrics.dailyStreak
        case "achv_morning_check": return ProgressMetrics.tagDayStreak("sleep-after")
        case "achv_sleep_control": return ProgressMetrics.tagDayStreak("sleep-before")
        case "achv_morning_bird": return ProgressMetrics.dayCount(forTag: "sleep-after")
        case "achv_sleep_keeper": return ProgressMetrics.dayCount(forTag: "sleep-before")
        case "achv_perfect_pair": return ProgressMetrics.pairCount(.sleep)
        case "achv_tagged_measures": return ProgressMetrics.taggedCount
        case "achv_meditation_lab": return ProgressMetrics.pairCount(.meditation)
        case "achv_resilience_loop": return ProgressMetrics.pairCount(.stress)
        case "achv_baseline_guardian": return ProgressMetrics.restWeeksWithThree
        case "achv_workout_reaction": return ProgressMetrics.pairCount(.exercise)
        case "achv_full_spectrum": return ProgressMetrics.fullSpectrumSets
        case "achv_3_hour_lab": return ProgressMetrics.anyPairs
        case "achv_insight_scholar": return ProgressMetrics.articleCount
        case "achv_ai_explorer": return ProgressMetrics.aiCommentCount
        case "achv_30_day_consistency": return ProgressMetrics.daysMeasured(last: 30)
        case "achv_90_day_consistency": return ProgressMetrics.daysMeasured(last: 90)
        case "achv_context_atlas": return ProgressMetrics.allTagsMinCount
        case "achv_setup_health": return ProgressMetrics.appleHealthConnected ? 1 : 0
        default: return 0
        }
    }

    func achievedTiers(_ seed: AchievementSeed) -> Int {
        let current = value(for: seed)
        return seed.tiers.filter { current >= $0 }.count
    }

    func isAchieved(_ seed: AchievementSeed) -> Bool {
        achievedTiers(seed) > 0
    }

    var completedCount: Int {
        AchievementCatalog.all.filter { isAchieved($0) }.count
    }

    var totalTiersAchieved: Int {
        AchievementCatalog.all.reduce(0) { $0 + achievedTiers($1) }
    }

    func nextTier(_ seed: AchievementSeed) -> Int? {
        let current = value(for: seed)
        return seed.tiers.first { current < $0 }
    }

    func progressValue(_ seed: AchievementSeed) -> (current: Int, target: Int) {
        let current = value(for: seed)
        let target = nextTier(seed) ?? seed.tiers.last ?? 1
        return (current, target)
    }

    func categoryProgress(_ category: String) -> (completed: Int, total: Int) {
        let items = AchievementCatalog.all.filter { $0.category == category }
        return (items.filter { isAchieved($0) }.count, items.count)
    }
}

// MARK: - Journey

@MainActor
final class JourneyService: ObservableObject {
    static let shared = JourneyService()

    var currentLevel: JourneyLevelSeed {
        for level in JourneyCatalog.levels {
            if !isLevelComplete(level) { return level }
        }
        return JourneyCatalog.levels.last ?? JourneyCatalog.levels[0]
    }

    var currentChapter: JourneyChapterSeed {
        JourneyCatalog.chapters.first { $0.id == currentLevel.chapter } ?? JourneyCatalog.chapters[0]
    }

    func isLevelComplete(_ level: JourneyLevelSeed) -> Bool {
        level.tasks.filter { $0.type == "core" }.allSatisfy { isComplete($0) }
    }

    func isComplete(_ task: JourneyTaskSeed) -> Bool {
        currentValue(for: task) >= task.target
    }

    func currentValue(for task: JourneyTaskSeed) -> Int {
        let base = value(for: task.category)
        if task.category == "read_article" {
            return task.referenceId == nil ? ProgressMetrics.articleCount : ProgressMetrics.articleRead(task.referenceId)
        }
        return base
    }

    func value(for category: String) -> Int {
        switch category {
        case "any_measures_vol": return ProgressMetrics.measurementCount
        case "any_measures_days": return ProgressMetrics.distinctDays
        case "all_tags_vol": return ProgressMetrics.taggedCount
        case "all_tags_sets": return ProgressMetrics.allTagsMinCount
        case "all_tag_groups": return ProgressMetrics.allTagGroupsCount
        case "apple_health": return ProgressMetrics.appleHealthConnected ? 1 : 0
        case "ai_comments_vol": return ProgressMetrics.aiCommentCount
        case "read_article": return ProgressMetrics.articleCount
        case "any_rest_vol":
            return ProgressMetrics.tagCount("sleep-before") + ProgressMetrics.tagCount("sleep-after")
                + ProgressMetrics.tagCount("relax-after")
        case "any_rest_pairs":
            return ProgressMetrics.pairCount(.sleep) + ProgressMetrics.pairCount(.meditation)
        case "any_rest_weeks_with_3": return ProgressMetrics.restWeeksWithThree
        case "load_measures_vol":
            return ["activity-before", "activity-after", "stress-before", "stress-during", "stress-after"]
                .reduce(0) { $0 + ProgressMetrics.tagCount($1) }
        case "any_activity_vol":
            return ProgressMetrics.tagCount("activity-before") + ProgressMetrics.tagCount("activity-after")
        case "exercise_before", "exersice_before": return ProgressMetrics.tagCount("activity-before")
        case "exercise_after", "exersice_after": return ProgressMetrics.tagCount("activity-after")
        case "exercise_pairs", "exersice_pairs": return ProgressMetrics.pairCount(.exercise)
        case "meditate_before_vol": return ProgressMetrics.tagCount("relax-before")
        case "meditate_after_vol": return ProgressMetrics.tagCount("relax-after")
        case "meditate_pairs": return ProgressMetrics.pairCount(.meditation)
        case "stress_before": return ProgressMetrics.tagCount("stress-before")
        case "stress_during": return ProgressMetrics.tagCount("stress-during")
        case "stress_after": return ProgressMetrics.tagCount("stress-after")
        case "stress_pairs": return ProgressMetrics.pairCount(.stress)
        case "sleep_before": return ProgressMetrics.tagCount("sleep-before")
        case "sleep_after": return ProgressMetrics.tagCount("sleep-after")
        case "sleep_before_days": return ProgressMetrics.dayCount(forTag: "sleep-before")
        case "sleep_after_days": return ProgressMetrics.dayCount(forTag: "sleep-after")
        case "sleep_before_streak_days": return ProgressMetrics.tagDayStreak("sleep-before")
        case "sleep_after_streak_days": return ProgressMetrics.tagDayStreak("sleep-after")
        case "sleep_pairs": return ProgressMetrics.pairCount(.sleep)
        case "any_pairs": return ProgressMetrics.anyPairs
        case "any_activity_pairs": return ProgressMetrics.pairCount(.exercise)
        case "consistency_7": return ProgressMetrics.daysMeasured(last: 7)
        case "consistency_30": return ProgressMetrics.daysMeasured(last: 30)
        case "consistency_90": return ProgressMetrics.daysMeasured(last: 90)
        case "full_spectrum_sets": return ProgressMetrics.fullSpectrumSets
        default: return 0
        }
    }

    var currentLevelProgress: Double {
        let cores = currentLevel.tasks.filter { $0.type == "core" }
        guard !cores.isEmpty else { return 0 }
        return Double(cores.filter { isComplete($0) }.count) / Double(cores.count)
    }

    func completedCoreTasks(in level: JourneyLevelSeed) -> Int {
        level.tasks.filter { $0.type == "core" && isComplete($0) }.count
    }

    var chapterStatus: (chapter: JourneyChapterSeed, completed: Bool, active: Bool, progress: Double) {
        let levels = JourneyCatalog.levels.filter { $0.chapter == currentChapter.id }
        let completed = levels.filter { isLevelComplete($0) }.count
        return (currentChapter, completed == levels.count, true,
                levels.isEmpty ? 0 : Double(completed) / Double(levels.count))
    }

    func levels(in chapter: JourneyChapterSeed) -> [JourneyLevelSeed] {
        JourneyCatalog.levels.filter { $0.chapter == chapter.id }
    }

    static func articleTitle(for referenceId: String?) -> String? {
        guard var id = referenceId else { return nil }
        if id.hasPrefix("article.") { id.removeFirst("article.".count) }
        if id.hasSuffix(".title") { id.removeLast(".title".count) }
        return InsightsContent.allArticles.first { $0.id == id }?.title
    }

    func chapterProgress(_ chapter: JourneyChapterSeed) -> Double {
        let levels = levels(in: chapter)
        guard !levels.isEmpty else { return 0 }
        return Double(levels.filter { isLevelComplete($0) }.count) / Double(levels.count)
    }

    func chapterIsUnlocked(_ chapter: JourneyChapterSeed) -> Bool {
        chapter.id <= currentChapter.id
    }

    func taskTitle(for category: String, target: Int, referenceId: String?) -> String {
        if category == "read_article" {
            return "Read the Article: \(Self.articleTitle(for: referenceId) ?? "Insights")"
        }
        let copy: [String: String] = [
            "any_measures_vol": "Make \(target) Heart Rate Measures",
            "any_measures_days": "Measure Your Heart Rate for \(target) Days",
            "all_tags_vol": "Make \(target) Any Tagged Measurements",
            "all_tags_sets": "Context Atlas: Use All 11 Tags at least \(target) Each",
            "all_tag_groups": "Make Measures for All 4 Tag Clusters",
            "apple_health": "Connect Apple Health",
            "ai_comments_vol": "Read \(target) AI Comments",
            "any_rest_vol": "Make \(target) REST Measurements",
            "any_rest_pairs": "Make \(target) REST Pairs",
            "any_rest_weeks_with_3": "Baseline Guardian: Complete \(target) Weeks with 3+ REST Measurements",
            "load_measures_vol": "Make \(target) LOAD Measurements",
            "any_activity_vol": "Make \(target) Activity Measures",
            "exercise_before": "Make \(target) Before Exercise Measurements",
            "exercise_after": "Make \(target) After Exercise Measurements",
            "exercise_pairs": "Workout Reaction: Complete \(target) Exercise Pairs",
            "exersice_before": "Make \(target) Before Exercise Measurements",
            "exersice_after": "Make \(target) After Exercise Measurements",
            "exersice_pairs": "Workout Reaction: Complete \(target) Exercise Pairs",
            "meditate_before_vol": "Make \(target) Before Meditation Measurements",
            "meditate_after_vol": "Make \(target) After Meditation Measurements",
            "meditate_pairs": "Meditation Lab: Finish \(target) Meditation Pairs",
            "stress_before": "Make \(target) Before Stress Measurements",
            "stress_during": "Make \(target) During Stress Measurements",
            "stress_after": "Make \(target) After Stress Measurements",
            "stress_pairs": "Resilience Loop: Complete \(target) Stress Pairs",
            "sleep_before": "Make \(target) Before Sleep Measurements",
            "sleep_after": "Make \(target) After Sleep Measurements",
            "sleep_before_days": "Sleep Control: Reach \(target) Before Sleep Days",
            "sleep_after_days": "Morning Bird: Reach \(target) After Sleep Days",
            "sleep_before_streak_days": "Consistency Window: Log Before Sleep Daily for \(target) Days",
            "sleep_after_streak_days": "Consistency Window: Log After Sleep Daily for \(target) Days",
            "sleep_pairs": "Night Cycle: Record \(target) Before & After Sleep Pairs",
            "any_pairs": "Do \(target) Before & After Pairs",
            "consistency_7": "7-Day Consistency: Log Measurements on \(target) of Last 7 Days",
            "consistency_30": "30-Day Consistency: Log Measurements on \(target) of Last 30 Days",
            "consistency_90": "90-Day Consistency: Log Measurements on \(target) of Last 90 Days",
            "full_spectrum_sets": "Full Spectrum: Collect \(target) Sets of Pairs in Each Cluster"
        ]
        return copy[category] ?? category.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
