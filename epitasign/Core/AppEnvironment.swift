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
        authService: AuthServicing = SupabaseAuthService(),
        nfcScanner: NFCScanning = RealNFCScanner(),
        attendanceService: AttendanceServicing = SupabaseAttendanceService()
    ) {
        self.authService = authService
        self.nfcScanner = nfcScanner
        self.attendanceService = attendanceService
    }
}
