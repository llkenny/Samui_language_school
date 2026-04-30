//
//  SLSComponents.swift
//  SamuiLanguageSchool
//
//  Created by Codex on 30.04.2026.
//

import SwiftUI

struct SLSTopBar: View {
    let title: String
    var backAction: (() -> Void)?
    var showsSeparator = true

    var body: some View {
        ZStack {
            Text(title)
                .font(SLSTypography.navigationTitle)
                .foregroundStyle(SLSColors.textPrimary)

            HStack {
                if let backAction {
                    Button(action: backAction) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(SLSColors.brand)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                }
                Spacer()
            }
        }
        .frame(height: 88)
        .padding(.horizontal, SLSSpacing.lg)
        .background(SLSColors.surface)
        .overlay(alignment: .bottom) {
            if showsSeparator {
                Rectangle()
                    .fill(SLSColors.separator)
                    .frame(height: 1)
            }
        }
    }
}

struct SLSCard<Content: View>: View {
    var padding: CGFloat = SLSSpacing.lg
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SLSColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: SLSRadius.lg, style: .continuous))
            .shadow(color: .black.opacity(0.10), radius: 7, x: 0, y: 3)
    }
}

struct SLSPill: View {
    let title: String
    var foreground: Color = SLSColors.purple
    var background: Color = SLSColors.purpleSoft

    var body: some View {
        Text(title)
            .font(SLSTypography.caption)
            .foregroundStyle(foreground)
            .padding(.horizontal, SLSSpacing.md)
            .padding(.vertical, 7)
            .background(background)
            .clipShape(Capsule())
    }
}

struct SLSProgressBar: View {
    let value: Double
    var trackColor: Color = SLSColors.disabledFill
    var fillColor: Color = SLSColors.brand
    var height: CGFloat = 9

    private var progress: Double {
        min(max(value, 0), 1)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackColor)
                Capsule()
                    .fill(fillColor)
                    .frame(width: max(height, geometry.size.width * progress))
            }
        }
        .frame(height: height)
    }
}

struct SLSPrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(SLSTypography.button)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 24, weight: .bold))
            }
            .foregroundStyle(isEnabled ? .white : SLSColors.textTertiary)
            .padding(.horizontal, 20)
            .frame(height: 68)
            .background(isEnabled ? SLSColors.brand : SLSColors.disabledFill)
            .clipShape(RoundedRectangle(cornerRadius: SLSRadius.md, style: .continuous))
            .shadow(color: isEnabled ? SLSColors.brand.opacity(0.22) : .clear, radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

struct SLSBottomActionBar: View {
    let title: String
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(SLSColors.separator)
                .frame(height: 1)
            SLSPrimaryButton(title: title, isEnabled: isEnabled, action: action)
                .padding(.horizontal, SLSSpacing.lg)
                .padding(.top, SLSSpacing.lg)
                .padding(.bottom, 32)
                .background(SLSColors.surface)
        }
    }
}

struct SLSIconCircle: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 23, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 46, height: 46)
            .background(.white.opacity(0.24))
            .clipShape(Circle())
    }
}
