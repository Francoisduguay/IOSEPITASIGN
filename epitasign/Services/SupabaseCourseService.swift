//
//  SupabaseCourseService.swift
//  epitasign
//

import Foundation

#if canImport(Supabase)
import Supabase
#endif

final class SupabaseCourseService: CourseServicing {
    private let fallback = MockCourseService()

    #if canImport(Supabase)
    private let client: SupabaseClient?

    init() {
        if let url = SupabaseConfig.projectURL, let anonKey = SupabaseConfig.anonKey {
            client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
        } else {
            client = nil
        }
    }
    #endif

    func fetchCourses() async throws -> [Course] {
        #if canImport(Supabase)
        guard let client else {
            return try await fallback.fetchCourses()
        }

        let rows: [CoursePayload] = try await client
            .from("courses")
            .select("id,title,room,starts_at,ends_at")
            .order("starts_at")
            .execute()
            .value

        return rows.compactMap { payload in
            guard let startsAt = ISO8601DateFormatter().date(from: payload.startsAt),
                  let endsAt = ISO8601DateFormatter().date(from: payload.endsAt) else {
                return nil
            }

            return Course(
                id: payload.id,
                title: payload.title,
                room: payload.room ?? "Salle a confirmer",
                startsAt: startsAt,
                endsAt: endsAt,
                status: CourseStatusResolver.status(for: startsAt, endsAt: endsAt)
            )
        }
        #else
        return try await fallback.fetchCourses()
        #endif
    }
}

struct MockCourseService: CourseServicing {
    func fetchCourses() async throws -> [Course] {
        let calendar = Calendar.current
        let today = Date()

        return [
            makeCourse(id: "maths", title: "Mathematiques", room: "A204", dayOffset: 0, hour: 8, minute: 30, calendar: calendar, baseDate: today),
            makeCourse(id: "ios", title: "Programmation iOS", room: "B312", dayOffset: 0, hour: 10, minute: 15, calendar: calendar, baseDate: today),
            makeCourse(id: "anglais", title: "Anglais", room: "D018", dayOffset: 1, hour: 9, minute: 0, calendar: calendar, baseDate: today),
            makeCourse(id: "reseaux", title: "Reseaux", room: "C101", dayOffset: 2, hour: 13, minute: 30, calendar: calendar, baseDate: today),
            makeCourse(id: "projet", title: "Projet", room: "Lab 4", dayOffset: 3, hour: 15, minute: 45, calendar: calendar, baseDate: today),
            makeCourse(id: "archi", title: "Architecture logicielle", room: "B210", dayOffset: 4, hour: 11, minute: 0, calendar: calendar, baseDate: today)
        ]
    }

    private func makeCourse(
        id: String,
        title: String,
        room: String,
        dayOffset: Int,
        hour: Int,
        minute: Int,
        calendar: Calendar,
        baseDate: Date
    ) -> Course {
        let targetDay = calendar.date(byAdding: .day, value: dayOffset, to: baseDate) ?? baseDate
        let startsAt = calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: targetDay
        ) ?? targetDay
        let endsAt = calendar.date(byAdding: .minute, value: 90, to: startsAt) ?? startsAt

        return Course(
            id: id,
            title: title,
            room: room,
            startsAt: startsAt,
            endsAt: endsAt,
            status: CourseStatusResolver.status(for: startsAt, endsAt: endsAt)
        )
    }
}

enum CourseStatusResolver {
    static func status(for startsAt: Date, endsAt: Date, now: Date = Date()) -> AttendanceStatus {
        if now >= startsAt && now <= endsAt {
            return .current
        }

        if now > endsAt {
            return .signed
        }

        return .upcoming
    }
}

#if canImport(Supabase)
private struct CoursePayload: Decodable {
    let id: String
    let title: String
    let room: String?
    let startsAt: String
    let endsAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case room
        case startsAt = "starts_at"
        case endsAt = "ends_at"
    }
}
#endif
