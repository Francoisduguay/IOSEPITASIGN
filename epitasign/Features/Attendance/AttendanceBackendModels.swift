//
//  AttendanceBackendModels.swift
//  epitasign
//

import Foundation

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
    case malformedServerResponse

    var errorDescription: String? {
        switch self {
        case .invalidSignature:
            "La signature ne respecte pas les regles minimales."
        case .missingSupabaseSDK:
            "Supabase SDK n'est pas encore ajoute au projet Xcode."
        case .malformedServerResponse:
            "La reponse du serveur Supabase est invalide."
        }
    }
}
