//
//  AppStyles.swift
//  epitasign
//

import SwiftUI
import UIKit

extension Color {
    static let appBlue = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.10, green: 0.32, blue: 0.68, alpha: 1)
                : UIColor.systemBlue
        }
    )
}

struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                blueAccent,
                Color.green.opacity(colorScheme == .dark ? 0.08 : 0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var blueAccent: Color {
        colorScheme == .dark
            ? Color(red: 0.03, green: 0.12, blue: 0.26).opacity(0.72)
            : Color.appBlue.opacity(0.08)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(tint.gradient, in: RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.16), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.red)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
    }
}

func haptic(_ style: HapticStyle) {
    switch style {
    case .light:
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    case .success:
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    case .warning:
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

enum HapticStyle {
    case light
    case success
    case warning
}
