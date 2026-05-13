//
//  LoginView.swift
//  epitasign
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var email = ""
    @State private var password = ""
    @State private var acceptedTerms = false
    @State private var errorMessage: String?
    @State private var isWorking = false
    @State private var showsPrivacyPolicy = false
    let onLogin: (AuthUser) -> Void

    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: 28) {
                Spacer(minLength: 24)

                VStack(alignment: .leading, spacing: 10) {
                    LogoMark(size: 58)

                    Text("EpitaSign")
                        .font(.system(size: 38, weight: .bold, design: .rounded))

                    Text("Code unique et signature numerique pour les cours.")
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

                    Toggle(isOn: $acceptedTerms) {
                        Text("J'accepte les conditions obligatoires RGPD")
                            .font(.footnote.weight(.semibold))
                    }
                    .toggleStyle(.switch)
                    .padding(14)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))

                    Button {
                        showsPrivacyPolicy = true
                    } label: {
                        Label("Lire les conditions RGPD", systemImage: "doc.text.magnifyingglass")
                            .font(.footnote.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.appBlue)

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
                .disabled(isWorking || !acceptedTerms)
                .opacity((isWorking || !acceptedTerms) ? 0.65 : 1)
                .padding(.bottom, 18)
            }
            .padding(22)
        }
        .sheet(isPresented: $showsPrivacyPolicy) {
            PrivacyPolicyView()
        }
    }

    private func signIn() {
        guard !isWorking else { return }
        guard acceptedTerms else {
            errorMessage = "Tu dois accepter les conditions RGPD pour continuer."
            haptic(.warning)
            return
        }

        Task {
            isWorking = true
            errorMessage = nil

            do {
                let user = try await environment.authService.signIn(email: email, password: password)
                haptic(.success)
                onLogin(user)
            } catch {
                errorMessage = error.localizedDescription
                haptic(.warning)
            }

            isWorking = false
        }
    }
}
