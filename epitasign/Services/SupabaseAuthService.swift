//
//  SupabaseAuthService.swift
//  epitasign
//

import Foundation

#if canImport(Supabase)
import Supabase
#endif

final class SupabaseAuthService: AuthServicing {
    #if canImport(Supabase)
    private let client: SupabaseClient?

    init() {
        if let url = SupabaseConfig.projectURL, let anonKey = SupabaseConfig.anonKey {
            client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
        } else {
            client = nil
        }
    }
    #endif

    func signIn(email: String, password: String) async throws -> AuthUser {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalizedEmail.hasSuffix("@epita.fr") else {
            throw AuthError.invalidEpitaEmail
        }

        #if canImport(Supabase)
        guard let client else {
            return try await mockSignIn(email: normalizedEmail)
        }

        let session = try await client.auth.signIn(email: normalizedEmail, password: password)
        guard let email = session.user.email?.lowercased(), email.hasSuffix("@epita.fr") else {
            try await client.auth.signOut()
            throw AuthError.invalidEpitaEmail
        }

        return AuthUser(uid: session.user.id.uuidString, email: email)
        #else
        return try await mockSignIn(email: normalizedEmail)
        #endif
    }

    func signOut() throws {
        #if canImport(Supabase)
        guard let client else { return }

        Task {
            try? await client.auth.signOut()
        }
        #endif
    }

    private func mockSignIn(email: String) async throws -> AuthUser {
        try await Task.sleep(nanoseconds: 350_000_000)
        return AuthUser(uid: "mock-user", email: email)
    }
}
