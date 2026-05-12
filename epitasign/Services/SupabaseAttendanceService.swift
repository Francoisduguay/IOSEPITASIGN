//
//  SupabaseAttendanceService.swift
//  epitasign
//

import Foundation

#if canImport(Supabase)
import Supabase
#endif

final class SupabaseAttendanceService: AttendanceServicing {
    private let fallback = MockAttendanceService()

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

    func requestToken(for scan: NFCScanResult, courseId: String) async throws -> AttendanceToken {
        #if canImport(Supabase)
        guard let client else {
            return try await fallback.requestToken(for: scan, courseId: courseId)
        }

        let payload = RequestAttendanceTokenPayload(
            courseId: courseId,
            tagIdentifier: scan.tagIdentifier,
            tagType: scan.tagType,
            technologies: scan.technologies,
            scannedAt: ISO8601DateFormatter().string(from: scan.scannedAt)
        )

        let response: RequestAttendanceTokenResponse = try await client.functions.invoke(
            "request-attendance-token",
            options: FunctionInvokeOptions(body: payload)
        )

        return AttendanceToken(
            id: response.tokenId,
            expiresAt: Date(timeIntervalSince1970: response.expiresAt / 1000)
        )
        #else
        return try await fallback.requestToken(for: scan, courseId: courseId)
        #endif
    }

    func submitSignature(_ request: AttendanceValidationRequest) async throws {
        guard request.signatureMetrics.isValid else {
            throw AttendanceBackendError.invalidSignature
        }

        #if canImport(Supabase)
        guard let client else {
            return try await fallback.submitSignature(request)
        }

        let payload = SubmitAttendanceSignaturePayload(
            courseId: request.courseId,
            tokenId: request.token.id,
            signatureBase64PNG: request.signatureProof.base64PNG,
            signatureMetrics: SignatureMetricsPayload(
                pointCount: request.signatureProof.pointCount,
                duration: request.signatureProof.duration,
                width: request.signatureProof.width,
                height: request.signatureProof.height
            )
        )

        let _: SubmitAttendanceSignatureResponse = try await client.functions.invoke(
            "submit-attendance-signature",
            options: FunctionInvokeOptions(body: payload)
        )
        #else
        try await fallback.submitSignature(request)
        #endif
    }
}

private struct RequestAttendanceTokenPayload: Encodable {
    let courseId: String
    let tagIdentifier: String
    let tagType: String
    let technologies: [String]
    let scannedAt: String
}

private struct RequestAttendanceTokenResponse: Decodable {
    let tokenId: String
    let expiresAt: TimeInterval
}

private struct SubmitAttendanceSignaturePayload: Encodable {
    let courseId: String
    let tokenId: String
    let signatureBase64PNG: String
    let signatureMetrics: SignatureMetricsPayload
}

private struct SignatureMetricsPayload: Encodable {
    let pointCount: Int
    let duration: TimeInterval
    let width: Double
    let height: Double
}

private struct SubmitAttendanceSignatureResponse: Decodable {
    let attendanceRecordId: String
    let signatureStoragePath: String
}
