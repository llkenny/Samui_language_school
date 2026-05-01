//
//  LessonContentProvider.swift
//  SamuiLanguageSchool
//
//  Created by Codex on 01.05.2026.
//

import Foundation

protocol LessonContentProviding {
    func lessonContent(id: String?) throws -> LessonContentModel
}

struct LessonContentProvider: LessonContentProviding {
    enum ProviderError: LocalizedError {
        case missingResource(String)
        case emptyLessonList
        case lessonNotFound(String)

        var errorDescription: String? {
            switch self {
            case .missingResource(let fileName):
                "Could not find \(fileName) in the app bundle."
            case .emptyLessonList:
                "The lesson content file does not contain any lessons."
            case .lessonNotFound(let id):
                "Could not find a lesson with id \(id)."
            }
        }
    }

    private let resourceName: String
    private let resourceExtension: String
    private let bundle: Bundle
    private let decoder: JSONDecoder

    init(
        resourceName: String = "lessons",
        resourceExtension: String = "json",
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.resourceName = resourceName
        self.resourceExtension = resourceExtension
        self.bundle = bundle
        self.decoder = decoder
    }

    func lessonContent(id: String? = nil) throws -> LessonContentModel {
        let lessons = try loadLessons()

        if let id {
            guard let lesson = lessons.first(where: { $0.id == id }) else {
                throw ProviderError.lessonNotFound(id)
            }
            return lesson
        }

        guard let lesson = lessons.first else {
            throw ProviderError.emptyLessonList
        }
        return lesson
    }

    private func loadLessons() throws -> [LessonContentModel] {
        guard let url = bundle.url(forResource: resourceName, withExtension: resourceExtension) else {
            throw ProviderError.missingResource("\(resourceName).\(resourceExtension)")
        }

        let data = try Data(contentsOf: url)
        return try decoder.decode([LessonContentModel].self, from: data)
    }
}
