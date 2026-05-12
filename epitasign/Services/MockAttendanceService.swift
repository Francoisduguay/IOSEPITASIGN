//
//  MockAttendanceService.swift
//  epitasign
//

import Foundation

struct MockNFCScanner: NFCScanning {
    func scanStudentCard() async throws -> NFCScanResult {
        try await Task.sleep(nanoseconds: 700_000_000)

        return NFCScanResult(
            tagIdentifier: "04:82:62:72:4A:1C:90",
            tagType: "ISO 14443-3A / MIFARE DESFire EV3",
            technologies: ["Type A", "IsoDep"],
            scannedAt: Date()
        )
    }
}

struct MockAttendanceService: AttendanceServicing {
    func requestToken(for scan: NFCScanResult, courseId: String) async throws -> AttendanceToken {
        try await Task.sleep(nanoseconds: 500_000_000)

        return AttendanceToken(
            id: "mock-token-\(scan.tagIdentifier.replacingOccurrences(of: ":", with: ""))",
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
