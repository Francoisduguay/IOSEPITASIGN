//
//  AuthModels.swift
//  epitasign
//

import Foundation

struct AuthUser: Equatable {
    let uid: String
    let email: String
}

protocol AuthServicing {
    func signIn(email: String, password: String) async throws -> AuthUser
    func signOut() throws
}

enum AuthError: LocalizedError {
    case invalidEpitaEmail

    var errorDescription: String? {
        switch self {
        case .invalidEpitaEmail:
            "Utilise une adresse EPITA valide."
        }
    }
}
