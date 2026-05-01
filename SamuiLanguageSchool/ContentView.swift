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

    var body: some View {
        NavigationStack(path: $path) {
            StartView {
                path.append(.lesson(progress.currentLessonID))
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .lesson(let lessonID):
                    LessonView(
                        viewModel: LessonViewModel(lessonID: lessonID),
                        onBack: pop,
                        onStartOrContinue: navigateToProgressDestination
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
                    PracticeView(lessonID: lessonID, taskID: taskID, onBack: pop)
                }
            }
        }
        .environmentObject(progress)
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    private func navigateToProgressDestination(lesson: LessonContentModel, destination: ProgressEnvironment.Destination) {
        switch destination {
        case .theory(let sectionID):
            path.append(.theory(lessonID: lesson.id, sectionID: sectionID))
        case .practice(let taskID):
            path.append(.practice(lessonID: lesson.id, taskID: taskID))
        }
    }
}

private enum Route: Hashable {
    case lesson(String?)
    case theory(lessonID: String, sectionID: String)
    case practice(lessonID: String, taskID: String?)
}

#Preview {
    ContentView()
}
