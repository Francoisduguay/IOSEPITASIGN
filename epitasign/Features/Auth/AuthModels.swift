//
//  AuthModels.swift
//  epitasign
//

import Foundation

struct AuthUser: Equatable {
    let uid: String
    let email: String
    let role: UserRole
}

enum UserRole: String, Equatable {
    case student
    case teacher

    var label: String {
        switch self {
        case .student: "Etudiant"
        case .teacher: "Enseignant"
        }
    }

    var canSignStudents: Bool {
        self == .teacher
    }

    static func inferred(from email: String) -> UserRole {
        let localPart = email.split(separator: "@").first?.lowercased() ?? ""

        if localPart.contains("teacher") || localPart.contains("prof") || localPart.contains("enseignant") {
            return .teacher
        }

        return .student
    }
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
