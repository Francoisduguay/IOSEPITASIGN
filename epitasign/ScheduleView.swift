//
//  ScheduleView.swift
//  epitasign
//

import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var selectedScope: ScheduleScope = .day
    @State private var focusedDate = Date()
    @State private var courses: [Course] = []
    @State private var selectedCourse: Course?
    @State private var loadingError: String?
    let user: AuthUser?

    var body: some View {
        PageContainer(title: "Emploi du temps", subtitle: scheduleSubtitle) {
            VStack(spacing: 14) {
                Picker("Vue", selection: $selectedScope) {
                    ForEach(ScheduleScope.allCases) { scope in
                        Text(scope.title).tag(scope)
                    }
                }
                .pickerStyle(.segmented)

                ScheduleNavigator(
                    title: navigationTitle,
                    previousAction: { moveFocusedDate(by: -1) },
                    nextAction: { moveFocusedDate(by: 1) }
                )

                VStack(spacing: 12) {
                    if selectedCourses.isEmpty {
                        EmptyScheduleView(message: loadingError ?? "Aucun cours trouve.")
                    }

                    ForEach(groupedCourses) { section in
                        if selectedScope == .week {
                            DaySeparator(title: section.title)
                        }

                        ForEach(section.courses) { course in
                            Button {
                                selectedCourse = course
                            } label: {
                                CourseRow(course: course, showsStatus: user?.role != .teacher)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .task {
            await loadCourses()
        }
        .sheet(item: $selectedCourse) { course in
            if user?.role.canSignStudents == true {
                if course.status == .current {
                    TeacherAttendanceView(course: course)
                } else {
                    TeacherCourseDetailView(course: course)
                }
            } else {
                CourseDetailView(course: course)
            }
        }
    }

    private var selectedCourses: [Course] {
        let calendar = Calendar.current

        switch selectedScope {
        case .day:
            return courses
                .filter { calendar.isDate($0.startsAt, inSameDayAs: focusedDate) }
                .sorted { $0.startsAt < $1.startsAt }
        case .week:
            guard let week = calendar.dateInterval(of: .weekOfYear, for: focusedDate) else {
                return courses
            }

            return courses
                .filter { week.contains($0.startsAt) }
                .sorted { $0.startsAt < $1.startsAt }
        }
    }

    private var groupedCourses: [CourseSection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: selectedCourses) { course in
            calendar.startOfDay(for: course.startsAt)
        }

        return grouped.keys.sorted().map { date in
            CourseSection(
                id: date,
                title: CourseFormatters.dayHeader.string(from: date).capitalized,
                courses: grouped[date, default: []].sorted { $0.startsAt < $1.startsAt }
            )
        }
    }

    private var scheduleSubtitle: String {
        switch selectedScope {
        case .day: "Vue par jour"
        case .week: "Vue par semaine"
        }
    }

    private var navigationTitle: String {
        switch selectedScope {
        case .day:
            return CourseFormatters.fullDate.string(from: focusedDate)
        case .week:
            guard let week = Calendar.current.dateInterval(of: .weekOfYear, for: focusedDate) else {
                return "Semaine"
            }

            let end = Calendar.current.date(byAdding: .day, value: -1, to: week.end) ?? week.end
            return "\(CourseFormatters.shortDate.string(from: week.start)) - \(CourseFormatters.shortDate.string(from: end))"
        }
    }

    private func moveFocusedDate(by value: Int) {
        let component: Calendar.Component = selectedScope == .day ? .day : .weekOfYear
        focusedDate = Calendar.current.date(byAdding: component, value: value, to: focusedDate) ?? focusedDate
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

struct CourseSection: Identifiable {
    let id: Date
    let title: String
    let courses: [Course]
}

struct ScheduleNavigator: View {
    let title: String
    let previousAction: () -> Void
    let nextAction: () -> Void

    var body: some View {
        HStack {
            Button(action: previousAction) {
                Image(systemName: "chevron.left")
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(IconButtonStyle())

            Text(title)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)

            Button(action: nextAction) {
                Image(systemName: "chevron.right")
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(IconButtonStyle())
        }
    }
}

struct DaySeparator: View {
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Rectangle()
                .fill(Color.secondary.opacity(0.25))
                .frame(height: 1)
        }
        .padding(.top, 6)
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
    let showsStatus: Bool

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: showsStatus ? 3 : 0) {
                Text(course.time)
                    .font(.headline.monospacedDigit())
                if showsStatus {
                    Text(course.status.shortLabel)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(course.status.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .frame(width: 76)

            VStack(alignment: .leading, spacing: 5) {
                Text(course.title)
                    .font(.headline)
                HStack(spacing: 8) {
                    Label(course.room, systemImage: "mappin.and.ellipse")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if showsStatus {
                Image(systemName: course.status.icon)
                    .font(.title3)
                    .foregroundStyle(course.status.color)
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct CourseDetailView: View {
    let course: Course

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                CourseRow(course: course, showsStatus: true)
                Text("Ce cours est disponible dans ton emploi du temps.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(20)
            .navigationTitle(course.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TeacherCourseDetailView: View {
    let course: Course

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                CourseRow(course: course, showsStatus: false)
                Text("Les signatures sont disponibles uniquement pendant le cours en cours.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(20)
            .navigationTitle(course.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TeacherAttendanceView: View {
    let course: Course
    @State private var students = [
        StudentAttendance(id: "1", name: "Nadir Koudri", status: .signed),
        StudentAttendance(id: "2", name: "Sarah Martin", status: .pending),
        StudentAttendance(id: "3", name: "Yanis Benali", status: .signed),
        StudentAttendance(id: "4", name: "Lea Bernard", status: .pending)
    ]
    @State private var signingStudent: StudentAttendance?

    private var signedCount: Int {
        students.filter { $0.status == .signed }.count
    }

    private var pendingCount: Int {
        students.filter { $0.status == .pending }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    AttendanceCountCard(title: "Signes", count: signedCount, color: .green)
                    AttendanceCountCard(title: "A signer", count: pendingCount, color: .orange)
                }

                ForEach($students) { $student in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(student.status.color.opacity(0.16))
                            .frame(width: 38, height: 38)
                            .overlay {
                                Image(systemName: student.status.icon)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(student.status.color)
                            }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(student.name)
                                .font(.headline)
                            Text(student.status.label)
                                .font(.caption)
                                .foregroundStyle(student.status.color)
                        }

                        Spacer()

                        if student.status == .pending {
                            Button {
                                signingStudent = student
                            } label: {
                                Text("Faire signer")
                                    .font(.caption.weight(.bold))
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button(role: .destructive) {
                                markPending(studentId: student.id)
                            } label: {
                                Text("Defaire")
                                    .font(.caption.weight(.bold))
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle(course.title)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $signingStudent) { student in
                TeacherStudentSignatureView(student: student) {
                    markPresent(studentId: student.id)
                }
            }
        }
    }

    private func markPresent(studentId: String) {
        guard let index = students.firstIndex(where: { $0.id == studentId }) else { return }
        students[index].status = .signed
    }

    private func markPending(studentId: String) {
        guard let index = students.firstIndex(where: { $0.id == studentId }) else { return }
        students[index].status = .pending
    }
}

struct AttendanceCountCard: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2.weight(.bold))
            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct TeacherStudentSignatureView: View {
    let student: StudentAttendance
    let onValidate: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var points: [CGPoint] = []
    @State private var startedAt: Date?
    @State private var duration: TimeInterval = 0

    private var metrics: SignatureMetrics {
        SignatureMetrics(points: points, duration: duration)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                SignaturePanel(points: $points, startedAt: $startedAt, duration: $duration, isEnabled: true)
                SignatureRules(metrics: metrics)
                Spacer()
                Button {
                    onValidate()
                    dismiss()
                } label: {
                    Label("Valider la presence", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                }
                .buttonStyle(PrimaryButtonStyle(tint: .green))
                .disabled(!metrics.isValid)
                .opacity(metrics.isValid ? 1 : 0.45)
            }
            .padding(20)
            .navigationTitle(student.name)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
