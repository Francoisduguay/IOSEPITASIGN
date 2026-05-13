//
//  SettingsView.swift
//  epitasign
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("usesDarkMode") private var usesDarkMode = false
    @AppStorage("allowsNotifications") private var allowsNotifications = true
    @AppStorage("usesHaptics") private var usesHaptics = true
    @State private var showsPrivacyPolicy = false
    let user: AuthUser?
    let onLogout: () -> Void

    var body: some View {
        PageContainer(title: "Parametres", subtitle: "Compte et reglages") {
            VStack(spacing: 14) {
                ProfileHeader(user: user)

                SettingToggle(icon: "moon.fill", title: "Mode sombre", subtitle: "Forcer l'apparence sombre", isOn: $usesDarkMode)
                SettingToggle(icon: "bell.badge.fill", title: "Notifications", subtitle: "Rappels avant les cours", isOn: $allowsNotifications)
                SettingToggle(icon: "iphone.radiowaves.left.and.right", title: "Vibrations", subtitle: "Retour tactile apres une action", isOn: $usesHaptics)

                Button {
                    showsPrivacyPolicy = true
                } label: {
                    SettingsLinkRow(
                        icon: "lock.shield.fill",
                        title: "Conditions RGPD",
                        subtitle: "Confidentialite et traitement des donnees"
                    )
                }
                .buttonStyle(.plain)

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
        .sheet(isPresented: $showsPrivacyPolicy) {
            PrivacyPolicyView()
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
                .foregroundStyle(Color.appBlue)

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

struct SettingsLinkRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .frame(width: 42, height: 42)
                .background(Color.appBlue.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(Color.appBlue)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PrivacySection(
                        title: "Conditions RGPD EpitaSign",
                        text: "Cette page explique comment EpitaSign traite les donnees personnelles dans le cadre de la gestion des presences aux cours."
                    )
                    PrivacySection(
                        title: "Donnees collectees",
                        text: "EpitaSign utilise les donnees necessaires au suivi de presence: adresse email, role, cours, statut de presence et signature associee a un cours."
                    )
                    PrivacySection(
                        title: "Finalite",
                        text: "Ces donnees servent uniquement a verifier et justifier la presence aux cours, ainsi qu'a permettre aux enseignants de suivre les presents et absents."
                    )
                    PrivacySection(
                        title: "Conservation",
                        text: "Les donnees sont conservees pendant la duree utile au suivi pedagogique. En mode mock, elles restent locales et temporaires dans l'application."
                    )
                    PrivacySection(
                        title: "Acces et droits",
                        text: "Tu peux demander l'acces, la rectification ou la suppression de tes donnees aupres de l'administrateur de l'application ou de l'etablissement."
                    )
                    PrivacySection(
                        title: "Securite",
                        text: "Les signatures et informations de presence sont limitees aux personnes autorisees: l'etudiant concerne, les enseignants et les administrateurs habilites."
                    )
                    PrivacySection(
                        title: "Contact",
                        text: "Pour toute demande RGPD, contacte l'administrateur EpitaSign ou le responsable pedagogique de ton etablissement."
                    )
                }
                .padding(20)
            }
            .navigationTitle("Conditions RGPD")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PrivacySection: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
