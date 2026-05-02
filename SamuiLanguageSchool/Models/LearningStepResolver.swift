//
//  LearningStepResolver.swift
//  SamuiLanguageSchool
//
//  Created by Codex on 02.05.2026.
//

import Foundation

enum LearningStep: Hashable {
    case theory(lessonID: String, sectionID: String)
    case practice(lessonID: String, taskID: String)

    var lessonID: String {
        switch self {
        case .theory(let lessonID, _), .practice(let lessonID, _):
            return lessonID
        }
    }
}

enum LearningStepResolver {
    static func steps(for lesson: LessonContentModel) -> [LearningStep] {
        let practiceTaskIDs = Set(lesson.practiceTasks.map(\.id))
        var steps: [LearningStep] = []
        var includedTaskIDs = Set<String>()

        for section in lesson.orderedTheorySections {
            steps.append(.theory(lessonID: lesson.id, sectionID: section.id))

            for taskID in section.tryItTaskIds where practiceTaskIDs.contains(taskID) {
                guard !includedTaskIDs.contains(taskID) else {
                    continue
                }

                steps.append(.practice(lessonID: lesson.id, taskID: taskID))
                includedTaskIDs.insert(taskID)
            }
        }

        for task in lesson.practiceTasks where !includedTaskIDs.contains(task.id) {
            steps.append(.practice(lessonID: lesson.id, taskID: task.id))
        }

        return steps
    }

    static func steps(for lessons: [LessonContentModel]) -> [LearningStep] {
        lessons.flatMap(steps(for:))
    }

    static func firstStep(in lesson: LessonContentModel) -> LearningStep? {
        steps(for: lesson).first
    }

    static func nextStep(after currentStep: LearningStep, in lessons: [LessonContentModel]) -> LearningStep? {
        let allSteps = steps(for: lessons)
        guard let currentIndex = allSteps.firstIndex(of: currentStep) else {
            return nil
        }

        let nextIndex = allSteps.index(after: currentIndex)
        guard allSteps.indices.contains(nextIndex) else {
            return nil
        }

        return allSteps[nextIndex]
    }
}
