//
//  epitasignTests.swift
//  epitasignTests
//
//  Created by Guest User on 24/04/2026.
//

import Testing
import Foundation
import CoreGraphics
@testable import epitasign

struct epitasignTests {

    @Test func realScannerUsesFixedProjectCode() async throws {
        let scanner = RealNFCScanner()

        let result = try await scanner.scanStudentCard()

        #expect(result.tagIdentifier == "EPITA2026")
        #expect(result.tagType == "Code fixe")
        #expect(result.technologies == ["ManualCode"])
    }

    @Test func mockAttendanceTokenUsesFixedCode() async throws {
        let scanner = MockNFCScanner()
        let service = MockAttendanceService()

        let scan = try await scanner.scanStudentCard()
        let token = try await service.requestToken(for: scan, courseId: "ios-course")

        #expect(scan.tagIdentifier == "EPITA2026")
        #expect(token.id == "mock-token-EPITA2026")
        #expect(token.expiresAt > Date())
    }

    @Test func weakSignatureMetricsAreRejected() {
        let metrics = SignatureMetrics(
            points: [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 10)],
            duration: 0.1
        )

        #expect(metrics.hasEnoughPoints == false)
        #expect(metrics.hasMinimumDuration == false)
        #expect(metrics.isValid == false)
    }

    @Test func complexSignatureMetricsAreAccepted() {
        let points = stride(from: 0, through: 360, by: 10).map { degree in
            let radians = Double(degree) * .pi / 180
            return CGPoint(
                x: 150 + cos(radians) * 140,
                y: 150 + sin(radians) * 90
            )
        }

        let metrics = SignatureMetrics(points: points, duration: 1.2)

        #expect(metrics.hasEnoughPoints)
        #expect(metrics.hasMinimumDuration)
        #expect(metrics.hasMinimumBox)
        #expect(metrics.hasComplexity)
        #expect(metrics.isValid)
    }

    @Test func courseStatusLabelsAreReadable() {
        #expect(AttendanceStatus.signed.shortLabel == "Signe")
        #expect(AttendanceStatus.current.shortLabel == "En cours")
        #expect(AttendanceStatus.upcoming.shortLabel == "A venir")
        #expect(AttendanceStatus.late.shortLabel == "Retard")
        #expect(AttendanceStatus.missed.shortLabel == "Absent")
    }

    @Test func attendanceCodeAcceptsExpectedValueOnly() {
        #expect(AttendanceCode.isValid("EPITA2026"))
        #expect(AttendanceCode.isValid(" epita2026 "))
        #expect(AttendanceCode.isValid("2026") == false)
        #expect(AttendanceCode.isValid("WRONG") == false)
    }

    @Test func userRoleIsInferredFromEmailForDemoAccounts() {
        #expect(UserRole.inferred(from: "admin@epita.fr") == .admin)
        #expect(UserRole.inferred(from: "prof.maths@epita.fr") == .teacher)
        #expect(UserRole.inferred(from: "prenom.nom@epita.fr") == .student)
    }

}
