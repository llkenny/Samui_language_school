//
//  ContentView.swift
//  SamuiLanguageSchool
//
//  Created by max on 30.04.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            StartView {
                path.append(.lesson)
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .lesson:
                    LessonView(
                        onBack: pop,
                        onStartPractice: { path.append(.practice) }
                    )
                case .theory:
                    TheoryView(
                        onBack: pop,
                        onStartPractice: { path.append(.practice) }
                    )
                case .practice:
                    PracticeView(onBack: pop)
                }
            }
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

private enum Route: Hashable {
    case lesson
    case theory
    case practice
}

#Preview {
    ContentView()
}
