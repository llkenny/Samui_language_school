//
//  SamuiLanguageSchoolTests.swift
//  SamuiLanguageSchoolTests
//
//  Created by max on 30.04.2026.
//

import Testing
@testable import SamuiLanguageSchool

struct SamuiLanguageSchoolTests {

    @MainActor
    @Test func lessonContentProviderLoadsAllBundledLessons() async throws {
        let lessons = try LessonContentProvider().lessonContents()

        #expect(lessons.map(\.id) == [
            "articles-discourse-part-2",
            "unless-as-long-as",
            "reflexive-pronouns"
        ])
    }

    @MainActor
    @Test func learningStepResolverIncludesEveryTheoryAndPracticeOnce() async throws {
        let lessons = try LessonContentProvider().lessonContents()

        for lesson in lessons {
            let steps = LearningStepResolver.steps(for: lesson)
            let theorySectionIDs = steps.compactMap { step -> String? in
                guard case .theory(_, let sectionID) = step else {
                    return nil
                }
                return sectionID
            }
            let practiceTaskIDs = steps.compactMap { step -> String? in
                guard case .practice(_, let taskID) = step else {
                    return nil
                }
                return taskID
            }

            #expect(theorySectionIDs == lesson.orderedTheorySections.map(\.id))
            #expect(Set(practiceTaskIDs) == Set(lesson.practiceTasks.map(\.id)))
            #expect(practiceTaskIDs.count == lesson.practiceTasks.count)
            #expect(steps.count == lesson.theorySections.count + lesson.practiceTasks.count)
        }
    }

    @MainActor
    @Test func learningStepResolverAdvancesThroughTryItTheoryAndNextLesson() async throws {
        let lessons = try LessonContentProvider().lessonContents()
        let articles = try #require(lessons.first { $0.id == "articles-discourse-part-2" })

        #expect(
            LearningStepResolver.nextStep(
                after: .theory(lessonID: articles.id, sectionID: "article-tracking-system"),
                in: lessons
            ) == .practice(lessonID: articles.id, taskID: "articles-try-it-a")
        )

        #expect(
            LearningStepResolver.nextStep(
                after: .practice(lessonID: articles.id, taskID: "articles-try-it-a"),
                in: lessons
            ) == .theory(lessonID: articles.id, sectionID: "abstract-nouns-and-articles")
        )

        #expect(
            LearningStepResolver.nextStep(
                after: .practice(lessonID: articles.id, taskID: "articles-activity-7"),
                in: lessons
            ) == .theory(lessonID: "unless-as-long-as", sectionID: "unless")
        )
    }

    @MainActor
    @Test func learningStepResolverFindsRelevantTheoryForPracticeTask() async throws {
        let lesson = Self.lesson(
            tasks: [
                Self.practiceTask(id: "try-it-task"),
                Self.practiceTask(id: "activity-task")
            ],
            theorySections: [
                Self.theorySection(id: "first-section", order: 1),
                Self.theorySection(id: "linked-section", order: 2, tryItTaskIds: ["try-it-task"])
            ]
        )

        #expect(
            LearningStepResolver.relevantTheorySection(
                forPracticeTaskID: "try-it-task",
                in: lesson
            )?.id == "linked-section"
        )

        #expect(
            LearningStepResolver.relevantTheorySection(
                forPracticeTaskID: "activity-task",
                in: lesson
            )?.id == "linked-section"
        )
    }

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

    @MainActor
    @Test func practiceEvaluatorMatchesExactAnswerWithNormalization() async throws {
        let evaluation = PracticeAnswerEvaluator.evaluate(
            response: "  the. ",
            for: Self.taskItem(id: "item-1"),
            answerKey: Self.answerKey(entries: [
                Self.answerEntry(itemId: "item-1", answer: .string("The"))
            ])
        )

        #expect(evaluation.state == .correct)
    }

    @MainActor
    @Test func practiceEvaluatorAcceptsZeroArticleSynonyms() async throws {
        let evaluation = PracticeAnswerEvaluator.evaluate(
            response: "no article",
            for: Self.taskItem(id: "item-1"),
            answerKey: Self.answerKey(entries: [
                Self.answerEntry(itemId: "item-1", answer: .string("zero article"))
            ])
        )

        #expect(evaluation.state == .correct)
    }

    @MainActor
    @Test func practiceEvaluatorUsesAcceptedAnswers() async throws {
        let evaluation = PracticeAnswerEvaluator.evaluate(
            response: "an answer",
            for: Self.taskItem(id: "item-1"),
            answerKey: Self.answerKey(entries: [
                Self.answerEntry(
                    itemId: "item-1",
                    answer: nil,
                    acceptedAnswers: ["a response", "an answer"]
                )
            ])
        )

        #expect(evaluation.state == .correct)
    }

    @MainActor
    @Test func practiceEvaluatorExtractsObjectCorrection() async throws {
        let evaluation = PracticeAnswerEvaluator.evaluate(
            response: "the Netherlands",
            for: Self.taskItem(id: "item-1", type: .errorCorrection),
            answerKey: Self.answerKey(entries: [
                Self.answerEntry(
                    itemId: "item-1",
                    answer: .object([
                        "error": .string("Netherlands"),
                        "correction": .string("the Netherlands")
                    ])
                )
            ])
        )

        #expect(evaluation.state == .correct)
        #expect(evaluation.expectedAnswer == "Error: Netherlands\nCorrection: the Netherlands")
    }

    @MainActor
    @Test func practiceEvaluatorMatchesSortingCategoryByAnswerArray() async throws {
        let evaluation = PracticeAnswerEvaluator.evaluate(
            response: "As long as",
            for: Self.taskItem(
                id: "item-2",
                type: .sorting,
                number: .integer(2),
                categories: ["Unless", "As long as"]
            ),
            answerKey: Self.answerKey(entries: [
                Self.answerEntry(itemId: "category-unless", answer: .array([.number(1), .number(3)])),
                Self.answerEntry(itemId: "category-as-long-as", answer: .array([.number(2), .number(4)]))
            ])
        )

        #expect(evaluation.state == .correct)
        #expect(evaluation.expectedAnswer == "As long as")
    }

    @MainActor
    @Test func practiceEvaluatorFindsCorrectOptionForChoiceList() async throws {
        let option = PracticeAnswerEvaluator.correctOption(
            from: ["a", "an", "the"],
            for: Self.taskItem(id: "item-1"),
            answerKey: Self.answerKey(entries: [
                Self.answerEntry(itemId: "item-1", answer: .string("The"))
            ])
        )

        #expect(option == "the")
    }

    @MainActor
    @Test func practiceEvaluatorFindsCorrectOptionForSortingCategories() async throws {
        let option = PracticeAnswerEvaluator.correctOption(
            from: ["Unless", "As long as"],
            for: Self.taskItem(
                id: "item-2",
                type: .sorting,
                number: .integer(2),
                categories: ["Unless", "As long as"]
            ),
            answerKey: Self.answerKey(entries: [
                Self.answerEntry(itemId: "category-unless", answer: .array([.number(1), .number(3)])),
                Self.answerEntry(itemId: "category-as-long-as", answer: .array([.number(2), .number(4)]))
            ])
        )

        #expect(option == "As long as")
    }

    @MainActor
    @Test func practiceEvaluatorMarksTeacherAssessedItemReviewed() async throws {
        let evaluation = PracticeAnswerEvaluator.evaluate(
            response: "My open response",
            for: Self.taskItem(id: "item-1", type: .freeResponse),
            answerKey: Self.answerKey(entries: [], teacherNotes: "Teacher-assessed.")
        )

        #expect(evaluation.state == .reviewed)
        #expect(!evaluation.isGradable)
        #expect(evaluation.notes == "Teacher-assessed.")
    }

    @MainActor
    @Test func practiceAnswerOptionBankDedupesNormalizedAnswers() async throws {
        let options = PracticeAnswerOptionBank.options(from: Self.answerKey(entries: [
            Self.answerEntry(itemId: "item-1", answer: .string("The")),
            Self.answerEntry(itemId: "item-2", answer: .string("the"))
        ]))

        #expect(options == ["The"])
    }

    @MainActor
    @Test func practiceAnswerOptionBankIncludesAcceptedAnswers() async throws {
        let options = PracticeAnswerOptionBank.options(from: Self.answerKey(entries: [
            Self.answerEntry(
                itemId: "item-1",
                answer: nil,
                acceptedAnswers: ["a response", "an answer"]
            )
        ]))

        #expect(options == ["a response", "an answer"])
    }

    @MainActor
    @Test func practiceAnswerOptionBankFlattensArrayAnswers() async throws {
        let options = PracticeAnswerOptionBank.options(from: Self.answerKey(entries: [
            Self.answerEntry(itemId: "item-1", answer: .array([.string("an"), .string("a")])),
            Self.answerEntry(itemId: "item-2", answer: .string("zero article"))
        ]))

        #expect(options == ["an", "a", "zero article"])
    }

    @MainActor
    @Test func practiceAnswerOptionBankUsesLessonWideShortAnswerEntries() async throws {
        let lesson = Self.lesson(
            tasks: [
                Self.practiceTask(
                    id: "first-short-task",
                    items: [
                        Self.taskItem(id: "item-1", type: .gapFill),
                        Self.taskItem(id: "item-2", type: .gapFill)
                    ]
                ),
                Self.practiceTask(
                    id: "second-short-task",
                    items: [
                        Self.taskItem(id: "item-3", type: .tableCompletion)
                    ]
                ),
                Self.practiceTask(
                    id: "rewrite-task",
                    items: [
                        Self.taskItem(id: "item-4", type: .rewrite)
                    ]
                )
            ],
            answerKey: [
                Self.answerKey(
                    taskId: "first-short-task",
                    entries: [
                        Self.answerEntry(itemId: "item-1", answer: .string("the")),
                        Self.answerEntry(itemId: "item-2", answer: .string("a"))
                    ]
                ),
                Self.answerKey(
                    taskId: "second-short-task",
                    entries: [
                        Self.answerEntry(itemId: "item-3", answer: .array([.string("an"), .string("zero article")]))
                    ]
                ),
                Self.answerKey(
                    taskId: "rewrite-task",
                    entries: [
                        Self.answerEntry(itemId: "item-4", answer: .string("Rewrite this full sentence."))
                    ]
                )
            ]
        )

        let options = PracticeAnswerOptionBank.options(
            from: lesson,
            itemTypes: [.gapFill, .tableCompletion]
        )

        #expect(options == ["the", "a", "an", "zero article"])
    }

    @MainActor
    @Test func shortRepeatPracticeSelectorUsesOnlyAutoGradableItems() async throws {
        let lesson = Self.lesson(
            tasks: [
                Self.practiceTask(
                    id: "gradable-task",
                    items: [
                        Self.taskItem(id: "item-1", type: .gapFill),
                        Self.taskItem(id: "item-2", type: .freeResponse)
                    ]
                ),
                Self.practiceTask(
                    id: "unkeyed-task",
                    items: [
                        Self.taskItem(id: "item-3", type: .gapFill)
                    ]
                )
            ],
            answerKey: [
                Self.answerKey(
                    taskId: "gradable-task",
                    entries: [
                        Self.answerEntry(itemId: "item-1", answer: .string("the"))
                    ]
                )
            ]
        )

        #expect(
            ShortRepeatPracticeSelector.selections(in: [lesson]) == [
                ShortRepeatPracticeSelection(
                    lessonID: "lesson",
                    taskID: "gradable-task",
                    itemID: "item-1"
                )
            ]
        )
    }

    @MainActor
    @Test func practiceTaskResolverUsesRequestedTaskWhenValid() async throws {
        let lesson = Self.lesson(tasks: [
            Self.practiceTask(id: "first-task"),
            Self.practiceTask(id: "second-task")
        ])

        #expect(
            PracticeTaskResolver.selectedTask(in: lesson, requestedTaskID: "second-task")?.id ==
            "second-task"
        )
    }

    @MainActor
    @Test func practiceTaskResolverFallsBackToFirstTask() async throws {
        let lesson = Self.lesson(tasks: [
            Self.practiceTask(id: "first-task"),
            Self.practiceTask(id: "second-task")
        ])

        #expect(
            PracticeTaskResolver.selectedTask(in: lesson, requestedTaskID: "missing-task")?.id ==
            "first-task"
        )
    }

    private static func taskItem(
        id: String,
        type: LessonContentModel.TaskItemType = .gapFill,
        number: LessonContentNumber? = nil,
        categories: [String]? = nil
    ) -> LessonContentModel.TaskItem {
        LessonContentModel.TaskItem(
            id: id,
            type: type,
            number: number,
            prompt: "Prompt",
            context: nil,
            answerType: nil,
            options: nil,
            targetForm: nil,
            targetForms: nil,
            categories: categories,
            text: nil,
            original: nil,
            newSubject: nil,
            checklist: nil
        )
    }

    private static func answerKey(
        taskId: String = "task",
        entries: [LessonContentModel.AnswerEntry],
        teacherNotes: String? = nil
    ) -> LessonContentModel.AnswerKeyTask {
        LessonContentModel.AnswerKeyTask(
            taskId: taskId,
            entries: entries,
            teacherNotes: teacherNotes
        )
    }

    private static func answerEntry(
        itemId: String,
        answer: JSONValue?,
        acceptedAnswers: [String]? = nil
    ) -> LessonContentModel.AnswerEntry {
        LessonContentModel.AnswerEntry(
            itemId: itemId,
            answer: answer,
            acceptedAnswers: acceptedAnswers,
            sampleAnswers: nil,
            explanation: nil,
            errorType: nil,
            notes: nil
        )
    }

    private static func lesson(
        tasks: [LessonContentModel.PracticeTask],
        answerKey: [LessonContentModel.AnswerKeyTask] = [],
        theorySections: [LessonContentModel.TheorySection]? = nil
    ) -> LessonContentModel {
        let theorySections = theorySections ?? [
            Self.theorySection(id: "section", order: 1)
        ]

        return LessonContentModel(
            id: "lesson",
            title: "Lesson",
            level: LessonContentModel.Level(code: "A1", label: "A1", descriptor: nil),
            subtitle: "Subtitle",
            estimatedMinutes: LessonContentModel.EstimatedMinutes(min: 1, max: 2),
            tags: [],
            source: LessonContentModel.Source(fileName: "file.pdf", pageCount: 1, extractionMethod: nil),
            screenSummary: LessonContentModel.ScreenSummary(
                themeTitle: "Theme",
                levelLabel: "A1",
                lessonBadge: "Lesson",
                shortDescription: "Description",
                estimatedReadTimeLabel: "1 min",
                primaryPracticeLabel: nil,
                progressLabel: nil
            ),
            learningPath: [],
            objectives: [],
            difficultyGuide: [],
            review: nil,
            theorySections: theorySections,
            practiceTasks: tasks,
            answerKey: answerKey,
            selfAssessment: nil
        )
    }

    private static func theorySection(
        id: String,
        order: Int,
        tryItTaskIds: [String] = []
    ) -> LessonContentModel.TheorySection {
        LessonContentModel.TheorySection(
            id: id,
            title: "Section",
            order: order,
            contentBlocks: [],
            tryItTaskIds: tryItTaskIds
        )
    }

    private static func practiceTask(
        id: String,
        items: [LessonContentModel.TaskItem] = []
    ) -> LessonContentModel.PracticeTask {
        LessonContentModel.PracticeTask(
            id: id,
            title: "Task",
            sourceLabel: nil,
            kind: .tryIt,
            mode: .practice,
            difficulty: nil,
            estimatedMinutes: nil,
            instructions: "Instructions",
            stimulus: nil,
            supportingPrompts: nil,
            items: items
        )
    }
}
