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
    @Published private(set) var signedCourseIds: Set<String> = []

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

    func markCourseSigned(_ courseId: String) {
        signedCourseIds.insert(courseId)
    }

    func isCourseSigned(_ courseId: String) -> Bool {
        signedCourseIds.contains(courseId)
    }
}
