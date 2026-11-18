import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var service = AchievementService.shared
    @State private var selected: AchievementSeed?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                summary
                ForEach(AchievementCatalog.categories, id: \.id) { category in
                    categorySection(category)
                }
            }
            .padding(18)
        }
        .screenBackground()
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selected) { seed in
            AchievementDetailSheet(seed: seed, value: service.value(for: seed))
        }
    }

    private var summary: some View {
        HStack(spacing: 12) {
            summaryTile(title: "Total Completed",
                        value: "\(service.completedCount)/\(AchievementCatalog.all.count)",
                        color: AppColor.brand)
            summaryTile(title: "Days with Heartica",
                        value: "\(ProgressMetrics.daysWithHeartica)",
                        color: AppColor.purple)
        }
    }

    private func summaryTile(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColor.textSecondary)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColor.textPrimary)
            Capsule().fill(color.opacity(0.6)).frame(width: 30, height: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: 16, radius: 18)
    }

    private func categorySection(_ category: (id: String, title: String)) -> some View {
        let items = AchievementCatalog.all.filter { $0.category == category.id }
        let progress = service.categoryProgress(category.id)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(category.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColor.textPrimary)
                Spacer()
                Text("\(progress.completed)/\(progress.total)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColor.textSecondary)
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(items) { seed in
                    Button {
                        selected = seed
                    } label: {
                        achievementCard(seed)
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
        }
    }

    private func achievementCard(_ seed: AchievementSeed) -> some View {
        let current = service.value(for: seed)
        let next = service.nextTier(seed)
        let achieved = service.isAchieved(seed)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: shapeSymbol(seed.shape))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(achieved ? AppColor.brand : AppColor.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill((achieved ? AppColor.brand : AppColor.textSecondary).opacity(0.12)))
                Spacer()
                if achieved {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(AppColor.success)
                        .font(.system(size: 14))
                }
            }
            Text(seed.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColor.textPrimary)
                .lineLimit(1)
            Text(next.map { "\(current) / \($0)" } ?? "\(current)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColor.textSecondary)
            ProgressView(value: Double(min(current, next ?? max(current, 1))),
                         total: Double(next ?? max(current, 1)))
                .tint(achieved ? AppColor.success : AppColor.brand)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: 14, radius: 18)
    }

    private func shapeSymbol(_ shape: String) -> String {
        switch shape {
        case "hexagon": return "hexagon.fill"
        case "circle": return "circle.fill"
        case "rhombus": return "diamond.fill"
        case "shield": return "shield.fill"
        case "capsule": return "capsule.fill"
        default: return "square.fill"
        }
    }
}

struct AchievementDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let seed: AchievementSeed
    let value: Int
    @State private var showShare = false

    private var achievedTiers: Int { seed.tiers.filter { value >= $0 }.count }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 14) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(AppColor.brandGradient)
                            .frame(width: 58, height: 58)
                            .background(Circle().fill(AppColor.brandSoft))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(seed.title)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                            Text(seed.subtitle)
                                .font(.system(size: 13))
                                .foregroundColor(AppColor.textSecondary)
                        }
                    }
                    Text(seed.description)
                        .font(.system(size: 14))
                        .foregroundColor(AppColor.textSecondary)
                        .lineSpacing(3)
                    HStack {
                        Text("Current progress")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColor.textSecondary)
                        Spacer()
                        Text("\(value)")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .card(padding: 14)

                    Text("Tiers")
                        .font(.system(size: 16, weight: .semibold))
                    VStack(spacing: 0) {
                        ForEach(Array(seed.tiers.enumerated()), id: \.offset) { index, tier in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(value >= tier ? AppColor.success : AppColor.separator)
                                    .frame(width: 8, height: 8)
                                Text("Tier \(index + 1)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppColor.textPrimary)
                                Spacer()
                                Text("\(tier)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(value >= tier ? AppColor.success : AppColor.textSecondary)
                                if value >= tier {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(AppColor.success)
                                }
                            }
                            .padding(.vertical, 9)
                            if index < seed.tiers.count - 1 { Divider() }
                        }
                    }
                    .padding(.horizontal, 14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(AppColor.surface))

                    Button {
                        showShare = true
                    } label: {
                        Text("Share Achievement")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(20)
            }
            .screenBackground()
            .navigationTitle("Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showShare) {
                ShareSheet(items: ["I just unlocked \(seed.title) in Heartica!"])
            }
        }
    }
}

// MARK: - Journey

struct JourneyView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var service = JourneyService.shared
    @State private var selectedChapter: JourneyChapterSeed?
    @State private var showChapterSheet = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                currentLevelCard
                tasksCard
                chaptersSection
            }
            .padding(18)
        }
        .screenBackground()
        .navigationTitle("My Journey")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showChapterSheet) {
            if let chapter = selectedChapter {
                JourneyChapterSheet(chapter: chapter)
            }
        }
    }

    private var currentLevelCard: some View {
        let level = service.currentLevel
        let chapter = service.currentChapter
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Chapter \(chapter.id) · \(chapter.title)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColor.textSecondary)
                    Text("Level \(level.id): \(level.title)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(AppColor.textPrimary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(AppColor.separator, lineWidth: 5)
                        .frame(width: 54, height: 54)
                    Circle()
                        .trim(from: 0, to: service.currentLevelProgress)
                        .stroke(AppColor.brand, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 54, height: 54)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(service.currentLevelProgress * 100))%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppColor.textPrimary)
                }
            }
            Text(chapter.description)
                .font(.system(size: 12))
                .foregroundColor(AppColor.textSecondary)
                .lineSpacing(2)
        }
        .card()
    }

    private var tasksCard: some View {
        let level = service.currentLevel
        return VStack(alignment: .leading, spacing: 14) {
            ForEach(["core", "optional", "pro"], id: \.self) { group in
                let tasks = level.tasks.filter { $0.type == group }
                if !tasks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(groupTitle(group))
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.6)
                            .foregroundColor(AppColor.textSecondary)
                        ForEach(Array(tasks.enumerated()), id: \.offset) { _, task in
                            taskRow(task)
                        }
                    }
                }
            }
        }
        .card()
    }

    private func taskRow(_ task: JourneyTaskSeed) -> some View {
        let value = service.currentValue(for: task)
        let done = value >= task.target
        return HStack(spacing: 10) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundColor(done ? AppColor.success : AppColor.textSecondary.opacity(0.5))
            VStack(alignment: .leading, spacing: 2) {
                Text(service.taskTitle(for: task.category, target: task.target, referenceId: task.referenceId))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColor.textPrimary)
                Text("\(min(value, task.target)) / \(task.target)")
                    .font(.system(size: 10))
                    .foregroundColor(AppColor.textSecondary)
            }
            Spacer()
            if task.category == "read_article" {
                Button("Read") { appState.previewArticle = referenceArticle(for: task) }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColor.brand)
            }
        }
    }

    private func groupTitle(_ group: String) -> String {
        switch group {
        case "core": return "MAIN"
        case "optional": return "OPTIONAL"
        default: return "PRO"
        }
    }

    private var chaptersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chapters")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColor.textPrimary)
            ForEach(JourneyCatalog.chapters) { chapter in
                Button {
                    selectedChapter = chapter
                    showChapterSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Text("\(chapter.id)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(service.chapterIsUnlocked(chapter) ? AppColor.brand : AppColor.textSecondary)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill((service.chapterIsUnlocked(chapter) ? AppColor.brand : AppColor.textSecondary).opacity(0.12)))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(chapter.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColor.textPrimary)
                            Text("\(service.levels(in: chapter).count) levels")
                                .font(.system(size: 10))
                                .foregroundColor(AppColor.textSecondary)
                        }
                        Spacer()
                        if !service.chapterIsUnlocked(chapter) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(AppColor.textSecondary)
                        } else {
                            Text("\(Int(service.chapterProgress(chapter) * 100))%")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppColor.textSecondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppColor.textSecondary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(AppColor.surface))
                }
                .buttonStyle(.plain)
                .disabled(!service.chapterIsUnlocked(chapter))
            }
        }
    }

    private func referenceArticle(for task: JourneyTaskSeed) -> Article? {
        guard let reference = task.referenceId else { return nil }
        var normalized = reference
        if normalized.hasPrefix("article.") { normalized.removeFirst("article.".count) }
        if normalized.hasSuffix(".title") { normalized.removeLast(".title".count) }
        return InsightsContent.allArticles.first { $0.id == normalized }
    }
}

struct JourneyChapterSheet: View {
    @Environment(\.dismiss) private var dismiss
    let chapter: JourneyChapterSeed
    @ObservedObject private var service = JourneyService.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(chapter.description)
                        .font(.system(size: 13))
                        .foregroundColor(AppColor.textSecondary)
                        .lineSpacing(2)
                    ForEach(service.levels(in: chapter)) { level in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Level \(level.id) · \(level.title)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColor.textPrimary)
                                Spacer()
                                if service.isLevelComplete(level) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppColor.success)
                                } else if level.id == service.currentLevel.id {
                                    Text("Current")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(AppColor.brand)
                                }
                            }
                            ForEach(Array(level.tasks.enumerated()), id: \.offset) { _, task in
                                HStack(spacing: 6) {
                                    Image(systemName: service.isComplete(task) ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 10))
                                        .foregroundColor(service.isComplete(task) ? AppColor.success : AppColor.textSecondary.opacity(0.5))
                                    Text(service.taskTitle(for: task.category, target: task.target, referenceId: task.referenceId))
                                        .font(.system(size: 11))
                                        .foregroundColor(AppColor.textSecondary)
                                }
                            }
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(AppColor.surface))
                    }
                }
                .padding(18)
            }
            .screenBackground()
            .navigationTitle("Chapter \(chapter.id)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
