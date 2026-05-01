//
//  LessonView.swift
//  SamuiLanguageSchool
//
//  Created by Codex on 01.05.2026.
//

import SwiftUI

struct LessonView: View {
    @StateObject private var viewModel: LessonViewModel

    var onBack: () -> Void
    var onStartPractice: () -> Void

    init(
        viewModel: @autoclosure @escaping () -> LessonViewModel = LessonViewModel(),
        onBack: @escaping () -> Void,
        onStartPractice: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.onBack = onBack
        self.onStartPractice = onStartPractice
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            SLSColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                SLSTopBar(title: "Lesson", backAction: onBack)

                content
            }

            SLSBottomActionBar(
                title: viewModel.primaryPracticeLabel,
                isEnabled: viewModel.lesson != nil,
                action: onStartPractice
            )
        }
        .navigationBarBackButtonHidden()
    }

    @ViewBuilder
    private var content: some View {
        if let lesson = viewModel.lesson {
            lessonContent(lesson)
        } else {
            errorContent
        }
    }

    private func lessonContent(_ lesson: LessonContentModel) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                LessonSummaryHero(summary: lesson.screenSummary)
                LearningPathSection(steps: lesson.learningPath)
                ObjectivesSection(objectives: lesson.objectives)
                DifficultyGuideSection(
                    entries: lesson.difficultyGuide,
                    practiceTasks: lesson.practiceTasks
                )
            }
            .padding(.horizontal, SLSSpacing.lg)
            .padding(.top, 24)
            .padding(.bottom, 124)
        }
    }

    private var errorContent: some View {
        VStack(spacing: SLSSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(SLSColors.brand)

            Text("Lesson unavailable")
                .font(SLSTypography.sectionTitle)
                .foregroundStyle(SLSColors.textPrimary)

            Text(viewModel.errorMessage ?? "Could not load lesson content.")
                .font(SLSTypography.body)
                .foregroundStyle(SLSColors.textSecondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                viewModel.load()
            }
            .font(SLSTypography.bodyStrong)
            .foregroundStyle(SLSColors.brand)
        }
        .padding(SLSSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct LessonSummaryHero: View {
    let summary: LessonContentModel.ScreenSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(alignment: .top) {
                SLSPill(
                    title: summary.lessonBadge,
                    foreground: .white,
                    background: .white.opacity(0.22)
                )
                Spacer(minLength: SLSSpacing.sm)
                Text(summary.levelLabel)
                    .font(SLSTypography.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.18))
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 14) {
                Text(summary.themeTitle)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(summary.shortDescription)
                    .font(SLSTypography.heroSubtitle)
                    .foregroundStyle(.white.opacity(0.92))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: SLSSpacing.md) {
                SummaryMetric(iconName: "clock", label: summary.estimatedReadTimeLabel)
                if let progressLabel = summary.progressLabel {
                    SummaryMetric(iconName: "checklist", label: progressLabel)
                }
            }
        }
        .padding(26)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [SLSColors.orange, SLSColors.brandStrong],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: SLSRadius.xl, style: .continuous))
    }
}

private struct SummaryMetric: View {
    let iconName: String
    let label: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .semibold))
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.86)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: SLSRadius.sm, style: .continuous))
    }
}

private struct LearningPathSection: View {
    let steps: [LessonContentModel.LearningPathStep]

    var body: some View {
        SLSCard(padding: 24) {
            VStack(alignment: .leading, spacing: 22) {
                SectionHeader(title: "Learning Path", iconName: "map.fill")

                VStack(spacing: 18) {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        LearningPathRow(stepNumber: index + 1, step: step)
                    }
                }
            }
        }
    }
}

private struct LearningPathRow: View {
    let stepNumber: Int
    let step: LessonContentModel.LearningPathStep

    var body: some View {
        HStack(alignment: .top, spacing: SLSSpacing.md) {
            Text("\(stepNumber)")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(SLSColors.brand)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(step.title)
                    .font(SLSTypography.bodyStrong)
                    .foregroundStyle(SLSColors.textPrimary)

                Text(step.instructions)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(SLSColors.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ObjectivesSection: View {
    let objectives: [String]

    var body: some View {
        SLSCard(padding: 24) {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Objectives", iconName: "target")

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(objectives.enumerated()), id: \.offset) { _, objective in
                        ObjectiveRow(text: objective)
                    }
                }
            }
        }
    }
}

private struct ObjectiveRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: SLSSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(SLSColors.brand)
                .padding(.top, 2)

            Text(text)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(SLSColors.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct DifficultyGuideSection: View {
    let entries: [LessonContentModel.DifficultyGuideEntry]
    let practiceTasks: [LessonContentModel.PracticeTask]

    private var taskTitlesByID: [String: String] {
        Dictionary(uniqueKeysWithValues: practiceTasks.map { ($0.id, $0.title) })
    }

    var body: some View {
        SLSCard(padding: 24) {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Difficulty Guide", iconName: "chart.bar.fill")

                VStack(spacing: 14) {
                    ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                        DifficultyGuideRow(
                            entry: entry,
                            taskTitles: entry.taskIds.map { taskTitlesByID[$0] ?? $0 }
                        )
                    }
                }
            }
        }
    }
}

private struct DifficultyGuideRow: View {
    let entry: LessonContentModel.DifficultyGuideEntry
    let taskTitles: [String]

    var body: some View {
        HStack(alignment: .top, spacing: SLSSpacing.md) {
            Text(entry.rating)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(SLSColors.brand)
                .frame(width: 42, height: 42)
                .background(SLSColors.brandSoft)
                .clipShape(RoundedRectangle(cornerRadius: SLSRadius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(entry.label)
                    .font(SLSTypography.bodyStrong)
                    .foregroundStyle(SLSColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(DifficultyGuideTitleFormatter.listText(for: taskTitles))
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(SLSColors.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SLSColors.lessonSurface)
        .clipShape(RoundedRectangle(cornerRadius: SLSRadius.md, style: .continuous))
    }
}

enum DifficultyGuideTitleFormatter {
    nonisolated static func listText(for titles: [String]) -> String {
        titles
            .map(formattedTitle)
            .joined(separator: "\n")
    }

    nonisolated static func formattedTitle(_ title: String) -> String {
        let prefix = "Activity "

        guard title.hasPrefix(prefix) else {
            return title
        }

        let titleWithoutPrefix = title.dropFirst(prefix.count)

        guard let separatorRange = titleWithoutPrefix.range(of: " - ") else {
            return title
        }

        let activityNumber = titleWithoutPrefix[..<separatorRange.lowerBound]

        guard !activityNumber.isEmpty, activityNumber.allSatisfy(\.isNumber) else {
            return title
        }

        let activityTitle = titleWithoutPrefix[separatorRange.upperBound...]
        return "\(activityNumber) - \(activityTitle)"
    }
}

private struct SectionHeader: View {
    let title: String
    let iconName: String

    var body: some View {
        HStack(spacing: SLSSpacing.sm) {
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(SLSColors.brand)
                .frame(width: 34, height: 34)
                .background(SLSColors.brandSoft)
                .clipShape(Circle())

            Text(title)
                .font(SLSTypography.sectionTitle)
                .foregroundStyle(SLSColors.textPrimary)
        }
    }
}

#Preview {
    LessonView(onBack: {}, onStartPractice: {})
}
