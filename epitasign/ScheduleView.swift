//
//  ScheduleView.swift
//  epitasign
//

import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var selectedScope: ScheduleScope = .day
    @State private var courses: [Course] = []
    @State private var loadingError: String?

    var body: some View {
        PageContainer(title: "Emploi du temps", subtitle: selectedScope.subtitle) {
            VStack(spacing: 14) {
                Picker("Vue", selection: $selectedScope) {
                    ForEach(ScheduleScope.allCases) { scope in
                        Text(scope.title).tag(scope)
                    }
                }
                .pickerStyle(.segmented)

                VStack(spacing: 12) {
                    if selectedCourses.isEmpty {
                        EmptyScheduleView(message: loadingError ?? "Aucun cours trouve.")
                    }

                    ForEach(selectedCourses) { course in
                        CourseRow(course: course, showsDay: selectedScope == .week)
                    }
                }
            }
        }
        .task {
            await loadCourses()
        }
    }

    private var selectedCourses: [Course] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedScope {
        case .day:
            return courses.filter { calendar.isDate($0.startsAt, inSameDayAs: now) }
        case .week:
            guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else {
                return courses
            }

            return courses.filter { week.contains($0.startsAt) }
        }
    }

    private func loadCourses() async {
        do {
            courses = try await environment.courseService.fetchCourses()
            loadingError = nil
        } catch {
            loadingError = error.localizedDescription
        }
    }
}

struct EmptyScheduleView: View {
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.title2)
            Text(message)
                .font(.callout.weight(.medium))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

enum ScheduleScope: String, CaseIterable, Identifiable {
    case day
    case week

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: "Jour"
        case .week: "Semaine"
        }
    }

    var subtitle: String {
        switch self {
        case .day: "Aujourd'hui"
        case .week: "Vue de la semaine"
        }
    }
}

struct CourseRow: View {
    let course: Course
    let showsDay: Bool

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 3) {
                Text(course.time)
                    .font(.headline.monospacedDigit())
                Text(course.status.shortLabel)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(course.status.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(width: 76)

            VStack(alignment: .leading, spacing: 5) {
                Text(course.title)
                    .font(.headline)
                HStack(spacing: 8) {
                    if showsDay {
                        Label(course.day, systemImage: "calendar")
                    }
                    Label(course.room, systemImage: "mappin.and.ellipse")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: course.status.icon)
                .font(.title3)
                .foregroundStyle(course.status.color)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
