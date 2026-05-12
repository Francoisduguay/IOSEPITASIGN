//
//  AttendanceBackendModels.swift
//  epitasign
//

import Foundation

enum AttendanceCode {
    static let validCode = "EPITA2026"

    static func isValid(_ code: String) -> Bool {
        normalized(code) == validCode
    }

    static func normalized(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    static func scanResult(from code: String) -> NFCScanResult {
        NFCScanResult(
            tagIdentifier: normalized(code),
            tagType: "Code fixe",
            technologies: ["ManualCode"],
            scannedAt: Date()
        )
    }
}

struct NFCScanResult: Equatable {
    let tagIdentifier: String
    let tagType: String
    let technologies: [String]
    let scannedAt: Date
}

struct AttendanceToken: Equatable {
    let id: String
    let expiresAt: Date
}

struct SignatureProof: Equatable {
    let base64PNG: String
    let pointCount: Int
    let duration: TimeInterval
    let width: Double
    let height: Double
}

struct AttendanceValidationRequest {
    let token: AttendanceToken
    let signatureProof: SignatureProof
    let signatureMetrics: SignatureMetrics
    let courseId: String
}

protocol NFCScanning {
    func scanStudentCard() async throws -> NFCScanResult
}

protocol AttendanceServicing {
    func requestToken(for scan: NFCScanResult, courseId: String) async throws -> AttendanceToken
    func submitSignature(_ request: AttendanceValidationRequest) async throws
}

enum AttendanceBackendError: LocalizedError {
    case invalidSignature
    case missingSupabaseSDK
    case missingActiveCourse
    case malformedServerResponse

    var errorDescription: String? {
        switch self {
        case .invalidSignature:
            "La signature ne respecte pas les regles minimales."
        case .missingSupabaseSDK:
            "Supabase SDK n'est pas encore ajoute au projet Xcode."
        case .missingActiveCourse:
            "Aucun cours actif n'est disponible."
        case .malformedServerResponse:
            "La reponse du serveur Supabase est invalide."
        }
    }
}
