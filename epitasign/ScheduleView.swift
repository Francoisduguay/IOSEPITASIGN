//
//  ScheduleView.swift
//  epitasign
//

import SwiftUI

struct ScheduleView: View {
    private let courses = [
        Course(title: "Mathematiques", room: "A204", time: "08:30", status: .signed),
        Course(title: "Programmation iOS", room: "B312", time: "10:15", status: .current),
        Course(title: "Reseaux", room: "C101", time: "13:30", status: .upcoming),
        Course(title: "Projet", room: "Lab 4", time: "15:45", status: .late)
    ]

    var body: some View {
        PageContainer(title: "Emploi du temps", subtitle: "Aujourd'hui") {
            VStack(spacing: 12) {
                ForEach(courses) { course in
                    CourseRow(course: course)
                }
            }
        }
    }
}

struct CourseRow: View {
    let course: Course

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 3) {
                Text(course.time)
                    .font(.headline.monospacedDigit())
                Text(course.status.shortLabel)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(course.status.color)
            }
            .frame(width: 68)

            VStack(alignment: .leading, spacing: 5) {
                Text(course.title)
                    .font(.headline)
                Label(course.room, systemImage: "mappin.and.ellipse")
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
