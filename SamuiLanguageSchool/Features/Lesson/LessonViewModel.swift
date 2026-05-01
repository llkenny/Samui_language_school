//
//  LessonViewModel.swift
//  SamuiLanguageSchool
//
//  Created by Codex on 01.05.2026.
//

import Combine
import Foundation

@MainActor
final class LessonViewModel: ObservableObject {
    @Published private(set) var lesson: LessonContentModel?
    @Published private(set) var errorMessage: String?

    private let provider: any LessonContentProviding
    private let lessonID: String?

    init(
        provider: any LessonContentProviding = LessonContentProvider(),
        lessonID: String? = "articles-discourse-part-2"
    ) {
        self.provider = provider
        self.lessonID = lessonID
        load()
    }

    var screenTitle: String {
        lesson?.screenSummary.themeTitle ?? "Lesson"
    }

    var primaryPracticeLabel: String {
        lesson?.screenSummary.primaryPracticeLabel ?? "Start Practice"
    }

    func load() {
        do {
            lesson = try provider.lessonContent(id: lessonID)
            errorMessage = nil
        } catch {
            lesson = nil
            errorMessage = error.localizedDescription
        }
    }
}
