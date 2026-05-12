//
//  LoginView.swift
//  epitasign
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isWorking = false
    let onLogin: () -> Void

    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: 28) {
                Spacer(minLength: 24)

                VStack(alignment: .leading, spacing: 10) {
                    LogoMark(size: 58)

                    Text("EpitaSign")
                        .font(.system(size: 38, weight: .bold, design: .rounded))

                    Text("Presence NFC et signature numerique pour les cours.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 14) {
                    FieldRow(icon: "envelope.fill", placeholder: "prenom.nom@epita.fr", text: $email)

                    SecureField("Mot de passe", text: $password)
                        .textContentType(.password)
                        .padding(.horizontal, 16)
                        .frame(height: 54)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                Button {
                    signIn()
                } label: {
                    Label(isWorking ? "Connexion" : "Continuer", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                }
                .buttonStyle(PrimaryButtonStyle(tint: .blue))
                .disabled(isWorking)
                .opacity(isWorking ? 0.65 : 1)
                .padding(.bottom, 18)
            }
            .padding(22)
        }
    }

    private func signIn() {
        guard !isWorking else { return }

        Task {
            isWorking = true
            errorMessage = nil

            do {
                _ = try await environment.authService.signIn(email: email, password: password)
                haptic(.success)
                onLogin()
            } catch {
                errorMessage = error.localizedDescription
                haptic(.warning)
            }

            isWorking = false
        }
    }
}
