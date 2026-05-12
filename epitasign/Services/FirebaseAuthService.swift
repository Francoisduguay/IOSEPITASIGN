//
//  FirebaseAuthService.swift
//  epitasign
//

import Foundation

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

final class FirebaseAuthService: AuthServicing {
    func signIn(email: String, password: String) async throws -> AuthUser {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalizedEmail.hasSuffix("@epita.fr") else {
            throw AuthError.invalidEpitaEmail
        }

        #if canImport(FirebaseAuth)
        let result = try await Auth.auth().signIn(withEmail: normalizedEmail, password: password)
        guard let email = result.user.email?.lowercased(), email.hasSuffix("@epita.fr") else {
            try Auth.auth().signOut()
            throw AuthError.invalidEpitaEmail
        }

        return AuthUser(uid: result.user.uid, email: email)
        #else
        try await Task.sleep(nanoseconds: 350_000_000)
        return AuthUser(uid: "mock-user", email: normalizedEmail)
        #endif
    }

    func signOut() throws {
        #if canImport(FirebaseAuth)
        try Auth.auth().signOut()
        #endif
    }
}
