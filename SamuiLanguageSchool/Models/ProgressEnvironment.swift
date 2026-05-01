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
    enum Destination: Equatable {
        case theory(sectionID: String)
        case practice(taskID: String)
    }

    @Published var currentLessonID: String?
    @Published var currentTheorySectionID: String?
    @Published var currentPracticeTaskID: String?

    init(
        currentLessonID: String? = "articles-discourse-part-2",
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

    func startOrContinueDestination(for lesson: LessonContentModel) -> Destination? {
        if currentLessonID != lesson.id {
            currentLessonID = lesson.id
            currentTheorySectionID = nil
            currentPracticeTaskID = nil
        }

        if let taskID = currentPracticeTaskID {
            return .practice(taskID: taskID)
        }

        guard let sectionID = currentTheorySectionID ?? lesson.firstTheorySection?.id else {
            return nil
        }

        currentTheorySectionID = sectionID
        return .theory(sectionID: sectionID)
    }

    func updateTheoryProgress(lessonID: String, sectionID: String) {
        currentLessonID = lessonID
        currentTheorySectionID = sectionID
    }

    func updatePracticeProgress(lessonID: String, taskID: String?) {
        currentLessonID = lessonID
        currentPracticeTaskID = taskID
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
