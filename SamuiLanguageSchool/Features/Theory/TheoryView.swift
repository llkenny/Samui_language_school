//
//  TheoryView.swift
//  SamuiLanguageSchool
//
//  Created by Codex on 30.04.2026.
//

import SwiftUI

struct TheoryView: View {
    var onBack: () -> Void
    var onStartPractice: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            SLSColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                SLSTopBar(title: "Theory", backAction: onBack)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        LessonHeroCard()
                        formationCard
                        usageCard
                    }
                    .padding(.horizontal, SLSSpacing.lg)
                    .padding(.top, 28)
                    .padding(.bottom, 130)
                }
            }

            SLSBottomActionBar(title: "Start Practice", action: onStartPractice)
        }
        .navigationBarBackButtonHidden()
    }

    private var formationCard: some View {
        SLSCard(padding: 28) {
            VStack(alignment: .leading, spacing: SLSSpacing.lg) {
                Text("Formation")
                    .font(SLSTypography.sectionTitle)
                    .foregroundStyle(SLSColors.textPrimary)

                LessonInfoPanel(
                    title: "Regular verbs",
                    formula: "Verb + -ed",
                    highlightedPart: "-ed",
                    example: "Example: work -> worked, play -> played",
                    background: SLSColors.lessonSurface
                )

                LessonInfoPanel(
                    title: "Irregular verbs",
                    formula: "Special forms",
                    highlightedPart: nil,
                    example: "Example: go -> went, see -> saw",
                    background: SLSColors.lessonSurface
                )
            }
        }
    }

    private var usageCard: some View {
        SLSCard(padding: 28) {
            VStack(alignment: .leading, spacing: SLSSpacing.md) {
                Text("Usage")
                    .font(SLSTypography.sectionTitle)
                    .foregroundStyle(SLSColors.textPrimary)
                Text("Use the past simple for finished actions in the past.")
                    .font(SLSTypography.body)
                    .foregroundStyle(SLSColors.textSecondary)
            }
        }
    }
}

private struct LessonHeroCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            HStack {
                SLSPill(title: "Lesson 3", foreground: .white, background: .white.opacity(0.22))
                Spacer()
                Text("15 min read")
                    .font(SLSTypography.caption)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("Past Simple Tense")
                    .font(.system(size: 31, weight: .bold))
                    .foregroundStyle(.white)
                Text("Regular and irregular verbs")
                    .font(SLSTypography.heroSubtitle)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .leading)
        .background(
            LinearGradient(
                colors: [SLSColors.orange, SLSColors.brandStrong],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: SLSRadius.xl, style: .continuous))
    }
}

private struct LessonInfoPanel: View {
    let title: String
    let formula: String
    let highlightedPart: String?
    let example: String
    let background: Color

    var body: some View {
        VStack(alignment: .leading, spacing: SLSSpacing.md) {
            Text(title)
                .font(SLSTypography.body)
                .foregroundStyle(Color(hex: 0x475467))

            formulaText
                .font(SLSTypography.bodyStrong)
                .foregroundStyle(SLSColors.textPrimary)

            Text(example)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(SLSColors.textSecondary)
                .lineSpacing(5)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: SLSRadius.md, style: .continuous))
    }

    private var formulaText: Text {
        guard let highlightedPart, let range = formula.range(of: highlightedPart) else {
            return Text(formula)
        }

        let prefix = String(formula[..<range.lowerBound])
        let suffix = String(formula[range.upperBound...])
        return Text("\(prefix)\(Text(highlightedPart).foregroundColor(SLSColors.brandStrong))\(suffix)")
    }
}

#Preview {
    TheoryView(onBack: {}, onStartPractice: {})
}
