//
//  PracticeView.swift
//  SamuiLanguageSchool
//
//  Created by Codex on 30.04.2026.
//

import SwiftUI

struct PracticeView: View {
    @EnvironmentObject private var progress: ProgressEnvironment
    @StateObject private var viewModel: LessonViewModel

    private let requestedTaskID: String?
    private let providedLessonID: String?
    var onBack: () -> Void

    @State private var activeTaskID: String?
    @State private var currentItemIndex = 0
    @State private var responses: [String: String] = [:]
    @State private var evaluations: [String: PracticeEvaluation] = [:]
    @State private var isComplete = false

    init(lessonID: String? = nil, taskID: String? = nil, onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: LessonViewModel(lessonID: lessonID))
        self.providedLessonID = lessonID
        self.requestedTaskID = taskID
        self.onBack = onBack
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            SLSColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if let lesson = viewModel.lesson, let task = selectedTask(in: lesson) {
                    practiceHeader(task: task)

                    if isComplete {
                        completionContent(task: task)
                    } else {
                        practiceContent(lesson: lesson, task: task)
                    }
                } else {
                    SLSTopBar(title: "Practice", backAction: onBack)
                    errorContent
                }
            }

            if let lesson = viewModel.lesson,
               let task = selectedTask(in: lesson),
               let item = currentItem(in: task),
               !isComplete {
                bottomActionBar(lesson: lesson, task: task, item: item)
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear(perform: syncProgress)
    }

    private func practiceHeader(task: LessonContentModel.PracticeTask) -> some View {
        VStack(spacing: 0) {
            SLSTopBar(title: "Practice", backAction: onBack, showsSeparator: false)

            HStack(spacing: SLSSpacing.md) {
                SLSProgressBar(value: progressValue(for: task))
                Text(progressText(for: task))
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(SLSColors.textSecondary)
            }
            .padding(.horizontal, SLSSpacing.lg)
            .padding(.top, 4)
            .padding(.bottom, 26)
        }
        .background(SLSColors.surface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(SLSColors.separator)
                .frame(height: 1)
        }
    }

    private func practiceContent(
        lesson: LessonContentModel,
        task: LessonContentModel.PracticeTask
    ) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                taskIntroCard(task: task)

                if let item = currentItem(in: task) {
                    itemCard(item: item, task: task, answerKey: answerKey(in: lesson, for: task))
                }
            }
            .padding(.horizontal, SLSSpacing.lg)
            .padding(.top, 24)
            .padding(.bottom, 130)
        }
    }

    private func taskIntroCard(task: LessonContentModel.PracticeTask) -> some View {
        SLSCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: SLSSpacing.sm) {
                    SLSPill(title: task.sourceLabel ?? task.kind.title)

                    Spacer(minLength: SLSSpacing.sm)

                    if let metaText = taskMetaText(task) {
                        Text(metaText)
                            .font(SLSTypography.caption)
                            .foregroundStyle(SLSColors.textSecondary)
                    }
                }

                Text(task.title)
                    .font(SLSTypography.cardTitle)
                    .foregroundStyle(SLSColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(task.instructions)
                    .font(SLSTypography.body)
                    .foregroundStyle(SLSColors.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                if let stimulus = task.stimulus {
                    Text(stimulus)
                        .font(SLSTypography.body)
                        .foregroundStyle(SLSColors.textPrimary)
                        .lineSpacing(5)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SLSColors.lessonSurface)
                        .clipShape(RoundedRectangle(cornerRadius: SLSRadius.md, style: .continuous))
                }

                if let supportingPrompts = task.supportingPrompts {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(supportingPrompts, id: \.self) { prompt in
                            PracticeBulletRow(text: prompt)
                        }
                    }
                }
            }
        }
    }

    private func itemCard(
        item: LessonContentModel.TaskItem,
        task: LessonContentModel.PracticeTask,
        answerKey: LessonContentModel.AnswerKeyTask?
    ) -> some View {
        SLSCard {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top) {
                    SLSPill(title: itemLabel(for: item, index: currentItemIndex))
                    Spacer(minLength: SLSSpacing.sm)
                    Text(item.type.title)
                        .font(SLSTypography.caption)
                        .foregroundStyle(SLSColors.textSecondary)
                }

                if let context = item.context {
                    Text(context)
                        .font(SLSTypography.body)
                        .foregroundStyle(SLSColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(item.prompt)
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(SLSColors.textPrimary)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)

                if let original = item.original {
                    PracticeDetailBlock(title: "Original", text: original)
                }

                if let text = item.text {
                    PracticeDetailBlock(title: "Text", text: text)
                }

                itemHints(item)
                responseInput(for: item)

                if let evaluation = evaluations[item.id] {
                    feedbackCard(evaluation: evaluation)
                } else if !PracticeAnswerEvaluator.isAutoGradable(item: item, answerKey: answerKey),
                          let teacherNotes = answerKey?.teacherNotes {
                    PracticeDetailBlock(title: "Teacher Notes", text: teacherNotes)
                }
            }
        }
    }

    @ViewBuilder
    private func itemHints(_ item: LessonContentModel.TaskItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let answerType = item.answerType {
                PracticeBulletRow(text: "Answer type: \(answerType)")
            }

            if let targetForm = item.targetForm {
                PracticeBulletRow(text: "Target: \(targetForm)")
            }

            if let targetForms = item.targetForms {
                ForEach(targetForms, id: \.self) { targetForm in
                    PracticeBulletRow(text: "Target: \(targetForm)")
                }
            }

            if let newSubject = item.newSubject {
                PracticeBulletRow(text: "New subject: \(newSubject)")
            }

            if let checklist = item.checklist {
                ForEach(checklist, id: \.self) { checklistItem in
                    PracticeBulletRow(text: checklistItem)
                }
            }
        }
    }

    @ViewBuilder
    private func responseInput(for item: LessonContentModel.TaskItem) -> some View {
        switch item.type {
        case .multipleChoice, .labeling:
            optionList(options: item.options ?? [], item: item)
        case .sorting:
            optionList(options: item.categories ?? [], item: item)
        case .speakingPrompt:
            SpeakingCompletionCard(isComplete: evaluations[item.id] != nil)
        case .paragraphWriting, .freeResponse:
            textEditor(for: item, minHeight: 150)
        case .gapFill, .rewrite, .errorCorrection, .tableCompletion:
            textEditor(for: item, minHeight: 92)
        }
    }

    private func optionList(options: [String], item: LessonContentModel.TaskItem) -> some View {
        VStack(spacing: SLSSpacing.md) {
            ForEach(options, id: \.self) { option in
                AnswerOptionButton(
                    title: option,
                    isSelected: responses[item.id] == option,
                    isDisabled: evaluations[item.id] != nil
                ) {
                    responses[item.id] = option
                }
            }
        }
    }

    private func textEditor(for item: LessonContentModel.TaskItem, minHeight: CGFloat) -> some View {
        TextEditor(text: responseBinding(for: item))
            .font(SLSTypography.body)
            .foregroundStyle(SLSColors.textPrimary)
            .frame(minHeight: minHeight)
            .padding(12)
            .scrollContentBackground(.hidden)
            .background(SLSColors.background)
            .overlay {
                RoundedRectangle(cornerRadius: SLSRadius.md, style: .continuous)
                    .stroke(SLSColors.border, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: SLSRadius.md, style: .continuous))
            .disabled(evaluations[item.id] != nil)
    }

    private func feedbackCard(evaluation: PracticeEvaluation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: feedbackIcon(for: evaluation))
                    .font(.system(size: 20, weight: .semibold))

                Text(feedbackTitle(for: evaluation))
                    .font(SLSTypography.bodyStrong)
            }
            .foregroundStyle(feedbackColor(for: evaluation))

            if let expectedAnswer = evaluation.expectedAnswer {
                PracticeDetailBlock(title: "Answer", text: expectedAnswer)
            }

            if let explanation = evaluation.explanation {
                PracticeDetailBlock(title: "Explanation", text: explanation)
            }

            if let errorType = evaluation.errorType {
                PracticeDetailBlock(title: "Focus", text: errorType)
            }

            if !evaluation.sampleAnswers.isEmpty {
                PracticeDetailBlock(title: "Samples", text: evaluation.sampleAnswers.joined(separator: "\n"))
            }

            if let notes = evaluation.notes {
                PracticeDetailBlock(title: "Notes", text: notes)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(feedbackColor(for: evaluation).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: SLSRadius.md, style: .continuous))
    }

    private func completionContent(task: LessonContentModel.PracticeTask) -> some View {
        VStack(spacing: 22) {
            Spacer(minLength: 40)

            SLSCard {
                VStack(alignment: .leading, spacing: 20) {
                    SLSPill(title: "Complete")

                    Text(task.title)
                        .font(SLSTypography.cardTitle)
                        .foregroundStyle(SLSColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(summaryText(for: task))
                        .font(SLSTypography.body)
                        .foregroundStyle(SLSColors.textSecondary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)

                    SLSPrimaryButton(title: "Done", action: onBack)
                }
            }
            .padding(.horizontal, SLSSpacing.lg)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorContent: some View {
        VStack(spacing: SLSSpacing.lg) {
            Image(systemName: "questionmark.app.dashed")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(SLSColors.brand)

            Text("Practice unavailable")
                .font(SLSTypography.sectionTitle)
                .foregroundStyle(SLSColors.textPrimary)

            Text(viewModel.errorMessage ?? "Could not load this practice task.")
                .font(SLSTypography.body)
                .foregroundStyle(SLSColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(SLSSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func bottomActionBar(
        lesson: LessonContentModel,
        task: LessonContentModel.PracticeTask,
        item: LessonContentModel.TaskItem
    ) -> some View {
        let actionState = bottomActionState(lesson: lesson, task: task, item: item)

        return SLSBottomActionBar(
            title: actionState.title,
            isEnabled: actionState.isEnabled,
            action: { performBottomAction(actionState.action, lesson: lesson, task: task, item: item) }
        )
    }

    private func bottomActionState(
        lesson: LessonContentModel,
        task: LessonContentModel.PracticeTask,
        item: LessonContentModel.TaskItem
    ) -> PracticeBottomActionState {
        if evaluations[item.id] != nil {
            return PracticeBottomActionState(
                title: isLastItem(in: task) ? "Finish" : "Next",
                isEnabled: true,
                action: .advance
            )
        }

        let answerKey = answerKey(in: lesson, for: task)
        let isAutoGradable = PracticeAnswerEvaluator.isAutoGradable(item: item, answerKey: answerKey)
        let hasResponse = PracticeAnswerEvaluator.responseIsPresent(responses[item.id], for: item)

        return PracticeBottomActionState(
            title: isAutoGradable ? "Check Answer" : openEndedActionTitle(for: item),
            isEnabled: hasResponse,
            action: .evaluate
        )
    }

    private func performBottomAction(
        _ action: PracticeBottomAction,
        lesson: LessonContentModel,
        task: LessonContentModel.PracticeTask,
        item: LessonContentModel.TaskItem
    ) {
        switch action {
        case .evaluate:
            let response = responses[item.id] ?? ""
            evaluations[item.id] = PracticeAnswerEvaluator.evaluate(
                response: response,
                for: item,
                answerKey: answerKey(in: lesson, for: task)
            )
        case .advance:
            if isLastItem(in: task) {
                isComplete = true
            } else {
                currentItemIndex = min(currentItemIndex + 1, task.items.count - 1)
            }
        }
    }

    private func selectedTask(in lesson: LessonContentModel) -> LessonContentModel.PracticeTask? {
        PracticeTaskResolver.selectedTask(in: lesson, requestedTaskID: requestedTaskID)
    }

    private func answerKey(
        in lesson: LessonContentModel,
        for task: LessonContentModel.PracticeTask
    ) -> LessonContentModel.AnswerKeyTask? {
        lesson.answerKey.first { $0.taskId == task.id }
    }

    private func currentItem(in task: LessonContentModel.PracticeTask) -> LessonContentModel.TaskItem? {
        guard !task.items.isEmpty else {
            return nil
        }

        return task.items[min(currentItemIndex, task.items.count - 1)]
    }

    private func syncProgress() {
        guard let lesson = viewModel.lesson, let task = selectedTask(in: lesson) else {
            return
        }

        if activeTaskID != task.id {
            resetSession(for: task)
        }

        progress.updatePracticeProgress(lessonID: providedLessonID ?? lesson.id, taskID: task.id)
    }

    private func resetSession(for task: LessonContentModel.PracticeTask) {
        activeTaskID = task.id
        currentItemIndex = 0
        responses = [:]
        evaluations = [:]
        isComplete = task.items.isEmpty
    }

    private func responseBinding(for item: LessonContentModel.TaskItem) -> Binding<String> {
        Binding {
            responses[item.id] ?? ""
        } set: { newValue in
            responses[item.id] = newValue
        }
    }

    private func progressValue(for task: LessonContentModel.PracticeTask) -> Double {
        guard !task.items.isEmpty else {
            return 1
        }

        if isComplete {
            return 1
        }

        return Double(currentItemIndex + 1) / Double(task.items.count)
    }

    private func progressText(for task: LessonContentModel.PracticeTask) -> String {
        guard !task.items.isEmpty else {
            return "0/0"
        }

        if isComplete {
            return "\(task.items.count)/\(task.items.count)"
        }

        return "\(currentItemIndex + 1)/\(task.items.count)"
    }

    private func itemLabel(for item: LessonContentModel.TaskItem, index: Int) -> String {
        if let numberText = item.number?.displayText {
            return "Question \(numberText)"
        }

        return "Question \(index + 1)"
    }

    private func taskMetaText(_ task: LessonContentModel.PracticeTask) -> String? {
        var parts: [String] = []

        if let difficulty = task.difficulty, !difficulty.isEmpty {
            parts.append(difficulty)
        }

        if let estimatedMinutes = task.estimatedMinutes {
            parts.append("\(estimatedMinutes.min)-\(estimatedMinutes.max) min")
        }

        return parts.isEmpty ? nil : parts.joined(separator: " | ")
    }

    private func isLastItem(in task: LessonContentModel.PracticeTask) -> Bool {
        currentItemIndex >= task.items.count - 1
    }

    private func openEndedActionTitle(for item: LessonContentModel.TaskItem) -> String {
        switch item.type {
        case .speakingPrompt:
            return "Mark Complete"
        case .freeResponse, .paragraphWriting:
            return "Show Answer"
        case .gapFill, .multipleChoice, .rewrite, .sorting, .labeling, .errorCorrection, .tableCompletion:
            return "Show Answer"
        }
    }

    private func feedbackTitle(for evaluation: PracticeEvaluation) -> String {
        switch evaluation.state {
        case .correct:
            return "Correct"
        case .incorrect:
            return "Try again next time"
        case .reviewed:
            return "Review"
        }
    }

    private func feedbackIcon(for evaluation: PracticeEvaluation) -> String {
        switch evaluation.state {
        case .correct:
            return "checkmark.circle.fill"
        case .incorrect:
            return "xmark.circle.fill"
        case .reviewed:
            return "text.bubble.fill"
        }
    }

    private func feedbackColor(for evaluation: PracticeEvaluation) -> Color {
        switch evaluation.state {
        case .correct:
            return Color(hex: 0x18864B)
        case .incorrect:
            return Color(hex: 0xC2410C)
        case .reviewed:
            return SLSColors.brand
        }
    }

    private func summaryText(for task: LessonContentModel.PracticeTask) -> String {
        let completedCount = evaluations.count
        let gradableEvaluations = evaluations.values.filter(\.isGradable)
        let correctCount = gradableEvaluations.filter(\.isCorrect).count

        if gradableEvaluations.isEmpty {
            return "Completed \(completedCount) of \(task.items.count) items. This task is teacher-assessed, so it is not included in the score."
        }

        return "Completed \(completedCount) of \(task.items.count) items.\nScore: \(correctCount) of \(gradableEvaluations.count) auto-graded items."
    }
}

private struct PracticeBottomActionState {
    let title: String
    let isEnabled: Bool
    let action: PracticeBottomAction
}

private enum PracticeBottomAction {
    case evaluate
    case advance
}

private struct AnswerOptionButton: View {
    let title: String
    let isSelected: Bool
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: SLSSpacing.md) {
                Text(title)
                    .font(SLSTypography.bodyStrong)
                    .foregroundStyle(SLSColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(SLSColors.brand)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
            .background(SLSColors.surface)
            .overlay {
                RoundedRectangle(cornerRadius: SLSRadius.md, style: .continuous)
                    .stroke(isSelected ? SLSColors.brand : SLSColors.border, lineWidth: isSelected ? 3 : 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: SLSRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

private struct PracticeDetailBlock: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(SLSTypography.caption)
                .foregroundStyle(SLSColors.textSecondary)
            Text(text)
                .font(SLSTypography.body)
                .foregroundStyle(SLSColors.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PracticeBulletRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Circle()
                .fill(SLSColors.brand)
                .frame(width: 6, height: 6)

            Text(text)
                .font(SLSTypography.body)
                .foregroundStyle(SLSColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct SpeakingCompletionCard: View {
    let isComplete: Bool

    var body: some View {
        HStack(spacing: SLSSpacing.md) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "mic.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(SLSColors.brand)

            Text(isComplete ? "Completed" : "Ready for speaking practice")
                .font(SLSTypography.bodyStrong)
                .foregroundStyle(SLSColors.textPrimary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SLSColors.lessonSurface)
        .clipShape(RoundedRectangle(cornerRadius: SLSRadius.md, style: .continuous))
    }
}

private extension LessonContentNumber {
    var displayText: String {
        switch self {
        case .integer(let value):
            return "\(value)"
        case .string(let value):
            return value
        }
    }
}

private extension LessonContentModel.TaskItemType {
    var title: String {
        switch self {
        case .gapFill:
            return "Gap fill"
        case .multipleChoice:
            return "Multiple choice"
        case .rewrite:
            return "Rewrite"
        case .sorting:
            return "Sorting"
        case .labeling:
            return "Labeling"
        case .errorCorrection:
            return "Error correction"
        case .tableCompletion:
            return "Table"
        case .paragraphWriting:
            return "Writing"
        case .speakingPrompt:
            return "Speaking"
        case .freeResponse:
            return "Free response"
        }
    }
}

private extension LessonContentModel.PracticeTaskKind {
    var title: String {
        switch self {
        case .tryIt:
            return "Try It"
        case .activity:
            return "Activity"
        case .warmUp:
            return "Warm Up"
        }
    }
}

#Preview {
    PracticeView(
        lessonID: "articles-discourse-part-2",
        taskID: "articles-try-it-a",
        onBack: {}
    )
    .environmentObject(ProgressEnvironment())
}
