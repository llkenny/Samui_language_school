//
//  SamuiLanguageSchoolTests.swift
//  SamuiLanguageSchoolTests
//
//  Created by max on 30.04.2026.
//

import Testing
@testable import SamuiLanguageSchool

struct SamuiLanguageSchoolTests {

    @Test func difficultyGuideTitleListUsesActivityNumbers() async throws {
        let titles = [
            "Activity 2 - Articles across a paragraph",
            "Activity 3 - Abstract nouns: a, the, or zero article",
            "Activity 4 - Generic the or zero article"
        ]

        #expect(
            DifficultyGuideTitleFormatter.listText(for: titles) ==
            """
            2 - Articles across a paragraph
            3 - Abstract nouns: a, the, or zero article
            4 - Generic the or zero article
            """
        )
    }

    @Test func difficultyGuideTitleFormatterLeavesNonActivityTitlesUnchanged() async throws {
        #expect(
            DifficultyGuideTitleFormatter.formattedTitle("Try It A - Article tracking") ==
            "Try It A - Article tracking"
        )
    }

}
