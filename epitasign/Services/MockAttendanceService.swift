//
//  MockAttendanceService.swift
//  epitasign
//

import Foundation

struct MockNFCScanner: NFCScanning {
    func scanStudentCard() async throws -> NFCScanResult {
        try await Task.sleep(nanoseconds: 700_000_000)

        return NFCScanResult(
            tagIdentifier: AttendanceCode.validCode,
            tagType: "Code fixe",
            technologies: ["ManualCode"],
            scannedAt: Date()
        )
    }
}

struct MockAttendanceService: AttendanceServicing {
    func requestToken(for scan: NFCScanResult, courseId: String) async throws -> AttendanceToken {
        try await Task.sleep(nanoseconds: 500_000_000)

        return AttendanceToken(
            id: "mock-token-\(scan.tagIdentifier)",
            expiresAt: Date().addingTimeInterval(120)
        )
    }

    func submitSignature(_ request: AttendanceValidationRequest) async throws {
        guard request.signatureMetrics.isValid else {
            throw AttendanceBackendError.invalidSignature
        }

        try await Task.sleep(nanoseconds: 500_000_000)
    }
}
