//
//  ContentView.swift
//  SamuiLanguageSchool
//
//  Created by max on 30.04.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var path: [Route] = []
    @StateObject private var progress = ProgressEnvironment()
    private let contentProvider = LessonContentProvider()

    var body: some View {
        NavigationStack(path: $path) {
            StartView(
                onStartLearning: {
                    path.append(.lesson(progress.currentLessonID))
                },
                onStartShortRepeat: startShortRepeat,
                onSelectLesson: { lesson in
                    path.append(.lesson(lesson.id))
                }
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .lesson(let lessonID):
                    LessonView(
                        viewModel: LessonViewModel(lessonID: lessonID),
                        onBack: pop,
                        onStartOrContinue: navigateToStep,
                        onSelectStep: navigateToSelectedStep
                    )
                case .theory(let lessonID, let sectionID):
                    TheoryView(
                        lessonID: lessonID,
                        sectionID: sectionID,
                        onBack: pop,
                        onStartPractice: { taskID in
                            path.append(.practice(lessonID: lessonID, taskID: taskID))
                        }
                    )
                case .practice(let lessonID, let taskID):
                    PracticeView(
                        lessonID: lessonID,
                        taskID: taskID,
                        onBack: pop,
                        onComplete: navigateAfterPracticeCompletion
                    )
                    .id(Route.practice(lessonID: lessonID, taskID: taskID))
                case .shortRepeat(let selection):
                    PracticeView(
                        lessonID: selection.lessonID,
                        taskID: selection.taskID,
                        mode: .shortRepeat(itemID: selection.itemID),
                        onBack: pop,
                        onComplete: navigateAfterShortRepeatCompletion
                    )
                    .id(Route.shortRepeat(selection))
                }
            }
        }
        .environmentObject(progress)
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    private func navigateToSelectedStep(_ step: LearningStep) {
        progress.updateProgress(to: step)
        navigateToStep(step)
    }

    private func navigateToStep(_ step: LearningStep) {
        switch step {
        case .theory(let lessonID, let sectionID):
            path.append(.theory(lessonID: lessonID, sectionID: sectionID))
        case .practice(let lessonID, let taskID):
            path.append(.practice(lessonID: lessonID, taskID: taskID))
        }
    }

    private func startShortRepeat() {
        do {
            let lessons = try contentProvider.lessonContents()
            guard let selection = ShortRepeatPracticeSelector.randomSelection(in: lessons) else {
                return
            }

            path.append(.shortRepeat(selection))
        } catch {
            path.removeAll()
        }
    }

    private func navigateAfterPracticeCompletion(
        lesson: LessonContentModel,
        task: LessonContentModel.PracticeTask,
        result: PracticeSessionResult
    ) {
        do {
            let lessons = try contentProvider.lessonContents()
            let completedStep = LearningStep.practice(lessonID: lesson.id, taskID: task.id)

            guard let nextStep = LearningStepResolver.nextStep(after: completedStep, in: lessons) else {
                path.removeAll()
                return
            }

            progress.updateProgress(to: nextStep)
            if !path.isEmpty {
                path.removeLast()
            }
            navigateToStep(nextStep)
        } catch {
            path.removeAll()
        }
    }

    private func navigateAfterShortRepeatCompletion(
        lesson: LessonContentModel,
        task: LessonContentModel.PracticeTask,
        result: PracticeSessionResult
    ) {
        if !path.isEmpty {
            path.removeLast()
        }

        guard result.hasErrors,
              let section = LearningStepResolver.relevantTheorySection(forPracticeTaskID: task.id, in: lesson) else {
            path.removeAll()
            return
        }

        path.append(.theory(lessonID: lesson.id, sectionID: section.id))
    }
}

private enum Route: Hashable {
    case lesson(String?)
    case theory(lessonID: String, sectionID: String)
    case practice(lessonID: String, taskID: String?)
    case shortRepeat(ShortRepeatPracticeSelection)
}

#Preview {
    ContentView()
}
