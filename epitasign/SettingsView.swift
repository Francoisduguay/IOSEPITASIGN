//
//  SettingsView.swift
//  epitasign
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("usesDarkMode") private var usesDarkMode = false
    @AppStorage("allowsNotifications") private var allowsNotifications = true
    @AppStorage("usesHaptics") private var usesHaptics = true
    let onLogout: () -> Void

    var body: some View {
        PageContainer(title: "Parametres", subtitle: "Compte et preferences") {
            VStack(spacing: 14) {
                ProfileHeader()

                SettingToggle(icon: "moon.fill", title: "Dark mode", subtitle: "Forcer l'apparence sombre", isOn: $usesDarkMode)
                SettingToggle(icon: "bell.badge.fill", title: "Notifications", subtitle: "Rappels avant les cours", isOn: $allowsNotifications)
                SettingToggle(icon: "iphone.radiowaves.left.and.right", title: "Haptique", subtitle: "Retour immediat au scan", isOn: $usesHaptics)

                Button(role: .destructive) {
                    haptic(.warning)
                    onLogout()
                } label: {
                    Label("Se deconnecter", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.top, 6)

                Spacer(minLength: 90)
            }
        }
    }
}

struct ProfileHeader: View {
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 56, height: 56)
                .overlay {
                    Text("NE")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("nadir.etudiant@epita.fr")
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text("Role: student")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.shield.fill")
                .font(.title3)
                .foregroundStyle(.green)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct SettingToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .frame(width: 42, height: 42)
                .background(Color.blue.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
