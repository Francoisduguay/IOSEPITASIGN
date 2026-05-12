//
//  SettingsView.swift
//  epitasign
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("usesDarkMode") private var usesDarkMode = false
    @AppStorage("allowsNotifications") private var allowsNotifications = true
    @AppStorage("usesHaptics") private var usesHaptics = true
    let user: AuthUser?
    let onLogout: () -> Void

    var body: some View {
        PageContainer(title: "Parametres", subtitle: "Compte et reglages") {
            VStack(spacing: 14) {
                ProfileHeader(user: user)

                SettingToggle(icon: "moon.fill", title: "Mode sombre", subtitle: "Forcer l'apparence sombre", isOn: $usesDarkMode)
                SettingToggle(icon: "bell.badge.fill", title: "Notifications", subtitle: "Rappels avant les cours", isOn: $allowsNotifications)
                SettingToggle(icon: "iphone.radiowaves.left.and.right", title: "Vibrations", subtitle: "Retour tactile apres une action", isOn: $usesHaptics)

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
    let user: AuthUser?

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.appBlue.gradient)
                .frame(width: 56, height: 56)
                .overlay {
                    Text(initials)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(user?.email ?? "Compte connecte")
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text("Role : \(user?.role.label ?? "Non defini")")
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

    private var initials: String {
        guard let email = user?.email, let localPart = email.split(separator: "@").first else {
            return "?"
        }

        let parts = localPart.split(separator: ".")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? String(localPart.prefix(2)).uppercased() : String(letters).uppercased()
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
                .background(Color.appBlue.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.appBlue)

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
