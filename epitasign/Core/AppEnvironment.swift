//
//  AppEnvironment.swift
//  epitasign
//

import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let authService: AuthServicing
    let nfcScanner: NFCScanning
    let attendanceService: AttendanceServicing

    init(
        authService: AuthServicing = FirebaseAuthService(),
        nfcScanner: NFCScanning = RealNFCScanner(),
        attendanceService: AttendanceServicing = FirebaseAttendanceService()
    ) {
        self.authService = authService
        self.nfcScanner = nfcScanner
        self.attendanceService = attendanceService
    }
}
