//
//  HistoryView.swift
//  epitasign
//

import SwiftUI

struct HistoryView: View {
    @State private var selectedRecord: AttendanceRecord?

    private let records = [
        AttendanceRecord(course: "Mathematiques", date: "Aujourd'hui", time: "08:32", status: .signed, signaturePreview: "Signature enregistree"),
        AttendanceRecord(course: "Architecture logicielle", date: "Hier", time: "10:21", status: .late, signaturePreview: "Signature enregistree"),
        AttendanceRecord(course: "Anglais", date: "Lun. 11 mai", time: "14:00", status: .signed, signaturePreview: "Signature enregistree"),
        AttendanceRecord(course: "Reseaux", date: "Ven. 8 mai", time: "--", status: .missed, signaturePreview: nil)
    ]

    var body: some View {
        PageContainer(title: "Historique", subtitle: "Presences recentes") {
            VStack(spacing: 12) {
                ForEach(records) { record in
                    Button {
                        selectedRecord = record
                    } label: {
                        HistoryRow(record: record)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(item: $selectedRecord) { record in
            AttendanceRecordDetailView(record: record)
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

struct AttendanceRecordDetailView: View {
    let record: AttendanceRecord

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                HistoryRow(record: record)

                VStack(alignment: .leading, spacing: 10) {
                    Label("Signature du cours", systemImage: "signature")
                        .font(.headline)

                    if record.signaturePreview != nil {
                        SignaturePreview()
                    } else {
                        Text("Aucune signature disponible pour ce cours.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle(record.course)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SignaturePreview: View {
    private let points = [
        CGPoint(x: 20, y: 90),
        CGPoint(x: 55, y: 60),
        CGPoint(x: 92, y: 102),
        CGPoint(x: 135, y: 34),
        CGPoint(x: 178, y: 98),
        CGPoint(x: 224, y: 52),
        CGPoint(x: 270, y: 78)
    ]

    var body: some View {
        Canvas { context, _ in
            var path = Path()
            path.move(to: points[0])

            for point in points.dropFirst() {
                path.addLine(to: point)
            }

            context.stroke(path, with: .color(.primary), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity)
        .background(.background.opacity(0.8), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
        }
    }
}
