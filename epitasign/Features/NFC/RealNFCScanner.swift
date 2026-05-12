//
//  RealNFCScanner.swift
//  epitasign
//

import Foundation

struct RealNFCScanner: NFCScanning {
    func scanStudentCard() async throws -> NFCScanResult {
        try await Task.sleep(nanoseconds: 300_000_000)

        return NFCScanResult(
            tagIdentifier: AttendanceCode.validCode,
            tagType: "Code fixe",
            technologies: ["ManualCode"],
            scannedAt: Date()
        )
    }
}
