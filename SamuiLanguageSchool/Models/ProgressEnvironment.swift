//
//  ProgressEnvironment.swift
//  SamuiLanguageSchool
//
//  Created by Codex on 01.05.2026.
//

import Combine
import Foundation

@MainActor
final class ProgressEnvironment: ObservableObject {
    @Published var currentLessonID: String?
    @Published var currentTheorySectionID: String?
    @Published var currentPracticeTaskID: String?

    init(
        currentLessonID: String? = nil,
        currentTheorySectionID: String? = nil,
        currentPracticeTaskID: String? = nil
    ) {
        self.currentLessonID = currentLessonID
        self.currentTheorySectionID = currentTheorySectionID
        self.currentPracticeTaskID = currentPracticeTaskID
    }

    func actionTitle(for lesson: LessonContentModel) -> String {
        hasProgress(in: lesson) ? "Continue" : "Start"
    }

    func startOrContinueStep(for lesson: LessonContentModel) -> LearningStep? {
        if currentLessonID != lesson.id {
            currentLessonID = lesson.id
            currentTheorySectionID = nil
            currentPracticeTaskID = nil
        }

        if let taskID = currentPracticeTaskID {
            return .practice(lessonID: lesson.id, taskID: taskID)
        }

        if let sectionID = currentTheorySectionID {
            return .theory(lessonID: lesson.id, sectionID: sectionID)
        }

        guard let firstStep = LearningStepResolver.firstStep(in: lesson) else {
            return nil
        }

        updateProgress(to: firstStep)
        return firstStep
    }

    func updateTheoryProgress(lessonID: String, sectionID: String) {
        currentLessonID = lessonID
        currentTheorySectionID = sectionID
        currentPracticeTaskID = nil
    }

    func updatePracticeProgress(lessonID: String, taskID: String?) {
        currentLessonID = lessonID
        currentPracticeTaskID = taskID
    }

    func updateProgress(to step: LearningStep) {
        switch step {
        case .theory(let lessonID, let sectionID):
            updateTheoryProgress(lessonID: lessonID, sectionID: sectionID)
        case .practice(let lessonID, let taskID):
            updatePracticeProgress(lessonID: lessonID, taskID: taskID)
        }
    }

    private func hasProgress(in lesson: LessonContentModel) -> Bool {
        currentLessonID == lesson.id && (currentTheorySectionID != nil || currentPracticeTaskID != nil)
    }
}

extension LessonContentModel {
    var orderedTheorySections: [TheorySection] {
        theorySections.sorted { lhs, rhs in
            if lhs.order == rhs.order {
                return lhs.id < rhs.id
            }

            return lhs.order < rhs.order
        }
    }

    var firstTheorySection: TheorySection? {
        orderedTheorySections.first
    }
}
