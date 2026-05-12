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
    let courseService: CourseServicing

    init(
        authService: AuthServicing = SupabaseAuthService(),
        nfcScanner: NFCScanning = RealNFCScanner(),
        attendanceService: AttendanceServicing = SupabaseAttendanceService(),
        courseService: CourseServicing = SupabaseCourseService()
    ) {
        self.authService = authService
        self.nfcScanner = nfcScanner
        self.attendanceService = attendanceService
        self.courseService = courseService
    }
}
