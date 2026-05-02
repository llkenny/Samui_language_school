//
//  TheoryView.swift
//  SamuiLanguageSchool
//
//  Created by Codex on 30.04.2026.
//

import SwiftUI

struct TheoryView: View {
    @EnvironmentObject private var progress: ProgressEnvironment
    @StateObject private var viewModel: LessonViewModel

    private let requestedSectionID: String
    var onBack: () -> Void
    var onStartPractice: (String?) -> Void

    init(
        lessonID: String,
        sectionID: String,
        onBack: @escaping () -> Void,
        onStartPractice: @escaping (String?) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: LessonViewModel(lessonID: lessonID))
        self.requestedSectionID = sectionID
        self.onBack = onBack
        self.onStartPractice = onStartPractice
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            SLSColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                SLSTopBar(title: "Theory", backAction: onBack)

                content
            }

            if let lesson = viewModel.lesson, let section = selectedSection(in: lesson) {
                SLSBottomActionBar(
                    title: practiceTask(in: lesson, for: section)?.title ?? "Start Practice",
                    isEnabled: !section.tryItTaskIds.isEmpty,
                    action: { startPractice(lesson: lesson, section: section) }
                )
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear(perform: syncProgress)
    }

    @ViewBuilder
    private var content: some View {
        if let lesson = viewModel.lesson, let section = selectedSection(in: lesson) {
            theoryContent(lesson: lesson, section: section)
        } else {
            errorContent
        }
    }

    private func theoryContent(lesson: LessonContentModel, section: LessonContentModel.TheorySection) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                TheoryHeroCard(summary: lesson.screenSummary, section: section, lessonTitle: lesson.title)

                ForEach(Array(section.contentBlocks.enumerated()), id: \.offset) { _, block in
                    TheoryContentBlockView(block: block)
                }
            }
            .padding(.horizontal, SLSSpacing.lg)
            .padding(.top, SLSSpacing.lg)
            .padding(.bottom, 108)
        }
    }

    private var errorContent: some View {
        VStack(spacing: SLSSpacing.lg) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(SLSColors.brand)

            Text("Theory unavailable")
                .font(SLSTypography.sectionTitle)
                .foregroundStyle(SLSColors.textPrimary)

            Text(viewModel.errorMessage ?? "Could not load this theory section.")
                .font(SLSTypography.body)
                .foregroundStyle(SLSColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(SLSSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func selectedSection(in lesson: LessonContentModel) -> LessonContentModel.TheorySection? {
        lesson.theorySections.first { $0.id == requestedSectionID } ?? lesson.firstTheorySection
    }

    private func practiceTask(
        in lesson: LessonContentModel,
        for section: LessonContentModel.TheorySection
    ) -> LessonContentModel.PracticeTask? {
        guard let taskID = section.tryItTaskIds.first else {
            return nil
        }

        return lesson.practiceTasks.first { $0.id == taskID }
    }

    private func syncProgress() {
        guard let lesson = viewModel.lesson, let section = selectedSection(in: lesson) else {
            return
        }

        progress.updateTheoryProgress(lessonID: lesson.id, sectionID: section.id)
    }

    private func startPractice(lesson: LessonContentModel, section: LessonContentModel.TheorySection) {
        let taskID = section.tryItTaskIds.first
        progress.updateTheoryProgress(lessonID: lesson.id, sectionID: section.id)
        progress.updatePracticeProgress(lessonID: lesson.id, taskID: taskID)
        onStartPractice(taskID)
    }
}

private struct TheoryHeroCard: View {
    let summary: LessonContentModel.ScreenSummary
    let section: LessonContentModel.TheorySection
    let lessonTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                SLSPill(
                    title: "Section \(section.order)",
                    foreground: .white,
                    background: .white.opacity(0.22)
                )

                Spacer(minLength: SLSSpacing.sm)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(section.title)
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(lessonTitle)
                    .font(SLSTypography.heroSubtitle)
                    .foregroundStyle(.white.opacity(0.92))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
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

private struct TheoryContentBlockView: View {
    let block: LessonContentModel.ContentBlock

    var body: some View {
        switch block.type {
        case .paragraph:
            TextBlockView(block: block)
        case .ruleList, .checklist, .comparison:
            ListBlockView(block: block)
        case .formula:
            FormulaBlockView(block: block)
        case .example, .exampleList:
            ExampleBlockView(block: block)
        case .table:
            TableBlockView(block: block)
        case .callout:
            CalloutBlockView(block: block)
        case .modelText:
            ModelTextBlockView(block: block)
        }
    }
}

private struct TextBlockView: View {
    let block: LessonContentModel.ContentBlock

    var body: some View {
        SLSCard(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                if let title = block.title {
                    TheoryBlockTitle(title)
                }

                Text(block.text ?? "")
                    .font(SLSTypography.body)
                    .foregroundStyle(SLSColors.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct FormulaBlockView: View {
    let block: LessonContentModel.ContentBlock

    var body: some View {
        SLSCard(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                if let title = block.title {
                    TheoryBlockTitle(title)
                }

                Text(block.formula ?? "")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(SLSColors.brandStrong)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SLSColors.lessonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: SLSRadius.md, style: .continuous))
            }
        }
    }
}

private struct ListBlockView: View {
    let block: LessonContentModel.ContentBlock

    private var items: [String] {
        block.items ?? block.examples ?? []
    }

    var body: some View {
        SLSCard(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                if let title = block.title {
                    TheoryBlockTitle(title)
                }

                VStack(alignment: .leading, spacing: 11) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        TheoryBulletRow(text: item)
                    }
                }
            }
        }
    }
}

private struct ExampleBlockView: View {
    let block: LessonContentModel.ContentBlock

    private var examples: [String] {
        block.examples ?? block.items ?? []
    }

    var body: some View {
        SLSCard(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                if let title = block.title {
                    TheoryBlockTitle(title)
                }

                if let text = block.text {
                    Text(text)
                        .font(SLSTypography.body)
                        .foregroundStyle(SLSColors.textPrimary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !examples.isEmpty {
                    VStack(alignment: .leading, spacing: 11) {
                        ForEach(Array(examples.enumerated()), id: \.offset) { _, example in
                            TheoryBulletRow(text: example)
                        }
                    }
                }
            }
        }
    }
}

private struct TableBlockView: View {
    let block: LessonContentModel.ContentBlock

    private var columns: [String] {
        block.columns ?? []
    }

    private var rows: [[String: JSONValue]] {
        block.rows ?? []
    }

    var body: some View {
        SLSCard(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                if let title = block.title {
                    TheoryBlockTitle(title)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            ForEach(columns, id: \.self) { column in
                                TableCell(text: column, isHeader: true)
                            }
                        }

                        ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                            HStack(spacing: 0) {
                                ForEach(columns, id: \.self) { column in
                                    TableCell(
                                        text: TableValueResolver.value(for: column, in: row),
                                        isHeader: false
                                    )
                                }
                            }
                            .background(rowIndex.isMultiple(of: 2) ? SLSColors.surface : SLSColors.lessonSurface.opacity(0.55))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: SLSRadius.md, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: SLSRadius.md, style: .continuous)
                            .stroke(SLSColors.border, lineWidth: 1)
                    }
                }
            }
        }
    }
}

private struct CalloutBlockView: View {
    let block: LessonContentModel.ContentBlock

    var body: some View {
        SLSCard(padding: 18) {
            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: SLSSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(SLSColors.brand)

                    TheoryBlockTitle(block.title ?? block.calloutType?.readableIdentifier ?? "Note")
                }

                if let incorrect = block.incorrect {
                    LabeledCalloutText(label: "Incorrect", text: incorrect, color: Color(hex: 0xB42318))
                }

                if let correct = block.correct {
                    LabeledCalloutText(label: "Correct", text: correct, color: Color(hex: 0x027A48))
                }

                if let explanation = block.explanation {
                    Text(explanation)
                        .font(SLSTypography.body)
                        .foregroundStyle(SLSColors.textPrimary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let items = block.items {
                    VStack(alignment: .leading, spacing: 11) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            TheoryBulletRow(text: item)
                        }
                    }
                }
            }
        }
    }
}

private struct ModelTextBlockView: View {
    let block: LessonContentModel.ContentBlock

    var body: some View {
        SLSCard(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                if let title = block.title {
                    TheoryBlockTitle(title)
                }

                Text(block.text ?? "")
                    .font(SLSTypography.body)
                    .foregroundStyle(SLSColors.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SLSColors.lessonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: SLSRadius.md, style: .continuous))
            }
        }
    }
}

private struct TheoryBlockTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(SLSTypography.sectionTitle)
            .foregroundStyle(SLSColors.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct TheoryBulletRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: SLSSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(SLSColors.brand)
                .padding(.top, 3)

            Text(text)
                .font(SLSTypography.body)
                .foregroundStyle(SLSColors.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct TableCell: View {
    let text: String
    let isHeader: Bool

    var body: some View {
        Text(text)
            .font(isHeader ? SLSTypography.bodyStrong : .system(size: 14, weight: .regular))
            .foregroundStyle(isHeader ? .white : SLSColors.textPrimary)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .padding(10)
            .frame(width: 170, alignment: .topLeading)
            .frame(minHeight: 48, alignment: .topLeading)
            .background(isHeader ? SLSColors.brand : Color.clear)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(isHeader ? .white.opacity(0.18) : SLSColors.border)
                    .frame(width: 1)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(SLSColors.border)
                    .frame(height: 1)
            }
    }
}

private struct LabeledCalloutText: View {
    let label: String
    let text: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(SLSTypography.caption)
                .foregroundStyle(color)

            Text(text)
                .font(SLSTypography.body)
                .foregroundStyle(SLSColors.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: SLSRadius.sm, style: .continuous))
    }
}

private enum TableValueResolver {
    static func value(for column: String, in row: [String: JSONValue]) -> String {
        let candidates = candidateKeys(for: column)

        for candidate in candidates {
            if let value = row[candidate] {
                return value.displayText
            }
        }

        let normalizedColumn = column.normalizedIdentifier
        if let match = row.first(where: { key, _ in key.normalizedIdentifier == normalizedColumn }) {
            return match.value.displayText
        }

        return ""
    }

    private static func candidateKeys(for column: String) -> [String] {
        let aliases = [
            "Article": "article",
            "Either works but the tone is different?": "linker",
            "Example": "example",
            "Example sentence": "example",
            "Form": "form",
            "If...not": "ifNot",
            "Linker": "linker",
            "Meaning": "meaning",
            "Pattern": "pattern",
            "Question": "question",
            "Reflexive pronoun": "pronoun",
            "Signal": "signal",
            "Situation": "situation",
            "Subject": "subject",
            "Unless": "unless",
            "Use": "use",
            "What it means": "meaning"
        ]

        return [
            aliases[column],
            column.camelCaseIdentifier,
            column.normalizedIdentifier
        ]
        .compactMap { $0 }
    }
}

private extension JSONValue {
    var displayText: String {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            if value.rounded() == value {
                return String(Int(value))
            }

            return String(value)
        case .bool(let value):
            return value ? "true" : "false"
        case .object(let values):
            return values
                .sorted { $0.key < $1.key }
                .map { "\($0.key): \($0.value.displayText)" }
                .joined(separator: "\n")
        case .array(let values):
            return values.map(\.displayText).joined(separator: "\n")
        case .null:
            return ""
        }
    }
}

private extension String {
    var camelCaseIdentifier: String {
        let words = split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        guard let first = words.first?.lowercased() else {
            return self
        }

        return words.dropFirst().reduce(first) { result, word in
            result + word.prefix(1).uppercased() + String(word.dropFirst())
        }
    }

    var normalizedIdentifier: String {
        lowercased().filter { $0.isLetter || $0.isNumber }
    }

    var readableIdentifier: String {
        unicodeScalars.reduce("") { result, scalar in
            if CharacterSet.uppercaseLetters.contains(scalar), !result.isEmpty {
                return result + " " + String(scalar).lowercased()
            }

            return result + String(scalar)
        }
        .capitalized
    }
}

#Preview {
    TheoryView(
        lessonID: "articles-discourse-part-2",
        sectionID: "article-tracking-system",
        onBack: {},
        onStartPractice: { _ in }
    )
    .environmentObject(ProgressEnvironment())
}
