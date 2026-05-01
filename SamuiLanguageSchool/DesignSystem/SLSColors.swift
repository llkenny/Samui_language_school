//
//  SLSColors.swift
//  SamuiLanguageSchool
//
//  Created by Codex on 30.04.2026.
//

import SwiftUI

enum SLSColors {
    static let brand = Color(hex: 0xFF5F00)
    static let brandStrong = Color(hex: 0xF24A00)
    static let brandSoft = Color(hex: 0xFFECD2)
    static let brandMuted = Color(hex: 0xFFB47D)

    static let orange = Color(hex: 0xFF7A1A)
    static let orangeSoft = Color(hex: 0xFFF4E6)
    static let warmSurface = Color(hex: 0xFFF8EF)
    static let lavenderSoft = Color(hex: 0xF2E2FF)

    static let background = Color(hex: 0xF7F8FA)
    static let surface = Color.white
    static let textPrimary = Color(hex: 0x111827)
    static let textSecondary = Color(hex: 0x667085)
    static let textTertiary = Color(hex: 0x98A2B3)
    static let border = Color(hex: 0xE3E5EA)
    static let separator = Color(hex: 0xE5E7EB)
    static let disabledFill = Color(hex: 0xE4E6EB)
    static let lessonSurface = Color(hex: 0xFFF7EC)
}

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
