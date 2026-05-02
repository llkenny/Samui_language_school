//
//  StartView.swift
//  SamuiLanguageSchool
//
//  Created by Codex on 30.04.2026.
//

import Combine
import SwiftUI

struct StartView: View {
    @EnvironmentObject private var progress: ProgressEnvironment
    @StateObject private var viewModel: StartViewModel

    var onStartLearning: () -> Void
    var onSelectLesson: (LessonContentModel) -> Void

    init(
        viewModel: @autoclosure @escaping () -> StartViewModel = StartViewModel(),
        onStartLearning: @escaping () -> Void,
        onSelectLesson: @escaping (LessonContentModel) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.onStartLearning = onStartLearning
        self.onSelectLesson = onSelectLesson
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            SLSColors.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                header

                VStack(alignment: .leading, spacing: SLSSpacing.lg) {
                    if viewModel.lessons.isEmpty {
                        errorContent
                    } else {
                        lessonCatalog
                    }
                }
                .padding(.horizontal, SLSSpacing.lg)
                .padding(.top, SLSSpacing.xl)
                .padding(.bottom, 124)
            }

            SLSBottomActionBar(
                title: progress.currentLessonID == nil ? "Start Learning" : "Continue Learning",
                isEnabled: !viewModel.lessons.isEmpty,
                action: onStartLearning
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SLSIconCircle(systemName: "book")
                Spacer()
                Circle()
                    .fill(SLSColors.brandMuted)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.22), lineWidth: 6)
                    }
            }
            .padding(.top, 24)

            Spacer()

            Text("Welcome back!")
                .font(SLSTypography.heroTitle)
                .foregroundStyle(.white)
                .padding(.bottom, 12)

            Text("Choose a lesson or continue your learning journey")
                .font(SLSTypography.heroSubtitle)
                .foregroundStyle(.white.opacity(0.92))
                .lineSpacing(5)
                .padding(.bottom, 20)
        }
        .padding(.horizontal, SLSSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SLSColors.brand)
        .ignoresSafeArea(edges: .top)
    }

    private var lessonCatalog: some View {
        VStack(alignment: .leading, spacing: SLSSpacing.md) {
            Text("Lessons")
                .font(SLSTypography.sectionTitle)
                .foregroundStyle(SLSColors.textPrimary)

            ForEach(viewModel.lessons) { lesson in
                LessonCatalogCard(
                    lesson: lesson,
                    isCurrent: progress.currentLessonID == lesson.id,
                    action: { onSelectLesson(lesson) }
                )
            }
        }
    }

    private var errorContent: some View {
        SLSCard {
            VStack(alignment: .leading, spacing: SLSSpacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(SLSColors.brand)

                Text("Lessons unavailable")
                    .font(SLSTypography.cardTitle)
                    .foregroundStyle(SLSColors.textPrimary)

                Text(viewModel.errorMessage ?? "Could not load lessons.")
                    .font(SLSTypography.body)
                    .foregroundStyle(SLSColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Retry") {
                    viewModel.load()
                }
                .font(SLSTypography.bodyStrong)
                .foregroundStyle(SLSColors.brand)
            }
        }
    }
}

@MainActor
final class StartViewModel: ObservableObject {
    @Published private(set) var lessons: [LessonContentModel] = []
    @Published private(set) var errorMessage: String?

    private let provider: any LessonContentProviding

    init(provider: any LessonContentProviding = LessonContentProvider()) {
        self.provider = provider
        load()
    }

    func load() {
        do {
            lessons = try provider.lessonContents()
            errorMessage = nil
        } catch {
            lessons = []
            errorMessage = error.localizedDescription
        }
    }
}

private struct LessonCatalogCard: View {
    let lesson: LessonContentModel
    let isCurrent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SLSCard {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: SLSSpacing.sm) {
                        SLSPill(
                            title: lesson.level.label,
                            foreground: isCurrent ? .white : SLSColors.brand,
                            background: isCurrent ? SLSColors.brand : SLSColors.brandSoft
                        )

                        Spacer(minLength: SLSSpacing.sm)

                        if isCurrent {
                            SLSPill(title: "Current")
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(lesson.title)
                            .font(SLSTypography.cardTitle)
                            .foregroundStyle(SLSColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(lesson.screenSummary.shortDescription)
                            .font(SLSTypography.body)
                            .foregroundStyle(SLSColors.textSecondary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: SLSSpacing.sm) {
                        CatalogMetric(iconName: "clock", text: lesson.screenSummary.estimatedReadTimeLabel)

                        if let progressLabel = lesson.screenSummary.progressLabel {
                            CatalogMetric(iconName: "checklist", text: progressLabel)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(lesson.title)
        .accessibilityIdentifier("lesson-\(lesson.id)")
    }
}

private struct CatalogMetric: View {
    let iconName: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .semibold))

            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.86)
        }
        .foregroundStyle(SLSColors.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SLSColors.lessonSurface)
        .clipShape(RoundedRectangle(cornerRadius: SLSRadius.sm, style: .continuous))
    }
}

#Preview {
    StartView(onStartLearning: {}, onSelectLesson: { _ in })
        .environmentObject(ProgressEnvironment())
}
