//
//  RealNFCScanner.swift
//  epitasign
//

import Foundation

struct RealNFCScanner: NFCScanning {
    private let fixedCode = "EPITA2026"

    func scanStudentCard() async throws -> NFCScanResult {
        try await Task.sleep(nanoseconds: 300_000_000)

        return NFCScanResult(
            tagIdentifier: fixedCode,
            tagType: "Code fixe",
            technologies: ["ManualCode"],
            scannedAt: Date()
        )
    }
}
