//
//  RealNFCScanner.swift
//  epitasign
//

import Foundation

#if canImport(CoreNFC)
import CoreNFC

final class RealNFCScanner: NSObject, NFCScanning, NFCTagReaderSessionDelegate {
    private var session: NFCTagReaderSession?
    private var continuation: CheckedContinuation<NFCScanResult, Error>?

    func scanStudentCard() async throws -> NFCScanResult {
        guard NFCTagReaderSession.readingAvailable else {
            throw AttendanceBackendError.missingNFC
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
            session.alertMessage = "Approche ta carte etudiante du haut de l'iPhone."
            self.session = session
            session.begin()
        }
    }

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
        self.session = nil
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else { return }

        session.connect(to: tag) { [weak self] error in
            if let error {
                session.invalidate(errorMessage: "Lecture NFC impossible.")
                self?.continuation?.resume(throwing: error)
                self?.continuation = nil
                return
            }

            let result = self?.scanResult(from: tag) ?? NFCScanResult(
                tagIdentifier: "unknown",
                tagType: "unknown",
                technologies: ["iso14443"],
                scannedAt: Date()
            )

            session.alertMessage = "Carte detectee."
            session.invalidate()
            self?.continuation?.resume(returning: result)
            self?.continuation = nil
        }
    }

    private func scanResult(from tag: NFCTag) -> NFCScanResult {
        switch tag {
        case .miFare(let mifareTag):
            return NFCScanResult(
                tagIdentifier: mifareTag.identifier.hexColonString,
                tagType: "MIFARE / ISO 14443-3A",
                technologies: ["Type A", "IsoDep"],
                scannedAt: Date()
            )
        case .iso7816(let isoTag):
            return NFCScanResult(
                tagIdentifier: isoTag.identifier.hexColonString,
                tagType: "ISO 7816 / IsoDep",
                technologies: ["IsoDep"],
                scannedAt: Date()
            )
        case .iso15693(let isoTag):
            return NFCScanResult(
                tagIdentifier: isoTag.identifier.hexColonString,
                tagType: "ISO 15693",
                technologies: ["ISO 15693"],
                scannedAt: Date()
            )
        case .feliCa(let feliCaTag):
            return NFCScanResult(
                tagIdentifier: feliCaTag.currentIDm.hexColonString,
                tagType: "FeliCa",
                technologies: ["FeliCa"],
                scannedAt: Date()
            )
        @unknown default:
            return NFCScanResult(
                tagIdentifier: "unknown",
                tagType: "unknown",
                technologies: ["unknown"],
                scannedAt: Date()
            )
        }
    }
}

private extension Data {
    var hexColonString: String {
        map { String(format: "%02X", $0) }.joined(separator: ":")
    }
}
#else
struct RealNFCScanner: NFCScanning {
    private let fallback = MockNFCScanner()

    func scanStudentCard() async throws -> NFCScanResult {
        try await fallback.scanStudentCard()
    }
}
#endif
