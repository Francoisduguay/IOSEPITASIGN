//
//  FirebaseAttendanceService.swift
//  epitasign
//

import Foundation

#if canImport(FirebaseFunctions)
import FirebaseFunctions
#endif

final class FirebaseAttendanceService: AttendanceServicing {
    private let fallback = MockAttendanceService()

    func requestToken(for scan: NFCScanResult, courseId: String) async throws -> AttendanceToken {
        #if canImport(FirebaseFunctions)
        let payload: [String: Any] = [
            "courseId": courseId,
            "tagIdentifier": scan.tagIdentifier,
            "tagType": scan.tagType,
            "technologies": scan.technologies,
            "scannedAt": ISO8601DateFormatter().string(from: scan.scannedAt)
        ]

        let result = try await Functions.functions().httpsCallable("requestAttendanceToken").call(payload)
        guard
            let data = result.data as? [String: Any],
            let tokenId = data["tokenId"] as? String,
            let expiresAtMillis = data["expiresAt"] as? TimeInterval
        else {
            throw AttendanceBackendError.malformedServerResponse
        }

        return AttendanceToken(
            id: tokenId,
            expiresAt: Date(timeIntervalSince1970: expiresAtMillis / 1000)
        )
        #else
        try await fallback.requestToken(for: scan, courseId: courseId)
        #endif
    }

    func submitSignature(_ request: AttendanceValidationRequest) async throws {
        guard request.signatureMetrics.isValid else {
            throw AttendanceBackendError.invalidSignature
        }

        #if canImport(FirebaseFunctions)
        let payload: [String: Any] = [
            "courseId": request.courseId,
            "tokenId": request.token.id,
            "signatureBase64PNG": request.signatureProof.base64PNG,
            "signatureMetrics": [
                "pointCount": request.signatureProof.pointCount,
                "duration": request.signatureProof.duration,
                "width": request.signatureProof.width,
                "height": request.signatureProof.height
            ]
        ]

        _ = try await Functions.functions().httpsCallable("submitAttendanceSignature").call(payload)
        #else
        try await fallback.submitSignature(request)
        #endif
    }
}
