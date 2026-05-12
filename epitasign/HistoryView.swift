//
//  HistoryView.swift
//  epitasign
//

import SwiftUI

struct HistoryView: View {
    private let records = [
        AttendanceRecord(course: "Mathematiques", date: "Aujourd'hui", time: "08:32", status: .signed),
        AttendanceRecord(course: "Architecture logicielle", date: "Hier", time: "10:21", status: .late),
        AttendanceRecord(course: "Anglais", date: "Lun. 11 mai", time: "14:00", status: .signed),
        AttendanceRecord(course: "Reseaux", date: "Ven. 8 mai", time: "--", status: .missed)
    ]

    var body: some View {
        PageContainer(title: "Historique", subtitle: "Presences recentes") {
            VStack(spacing: 12) {
                ForEach(records) { record in
                    HistoryRow(record: record)
                }
            }
        }
    }
}

struct HistoryRow: View {
    let record: AttendanceRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.status.icon)
                .font(.headline)
                .frame(width: 42, height: 42)
                .background(record.status.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(record.status.color)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.course)
                    .font(.headline)
                Text("\(record.date) - \(record.time)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(record.status.label)
                .font(.caption.weight(.bold))
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(record.status.color.opacity(0.14), in: Capsule())
                .foregroundStyle(record.status.color)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
