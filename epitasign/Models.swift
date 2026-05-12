//
//  Models.swift
//  epitasign
//

import SwiftUI

enum AttendanceFlowState {
    case ready
    case scanning
    case tokenReady
    case signing
    case signatureRejected
    case validated

    var title: String {
        switch self {
        case .ready: "Pret a scanner"
        case .scanning: "Lecture NFC"
        case .tokenReady: "Token temporaire actif"
        case .signing: "Signature en cours"
        case .signatureRejected: "Signature insuffisante"
        case .validated: "Presence validee"
        }
    }

    var message: String {
        switch self {
        case .ready: "Le bouton principal reste accessible en bas."
        case .scanning: "Simulation du scan physique de la carte."
        case .tokenReady: "Le token est pret. Signe dans la zone."
        case .signing: "Complete la signature puis valide."
        case .signatureRejected: "Ajoute plus de mouvement, duree et complexite."
        case .validated: "La preuve serait envoyee a Supabase Storage."
        }
    }

    var shortLabel: String {
        switch self {
        case .ready: "NFC"
        case .scanning: "SCAN"
        case .tokenReady: "TOKEN"
        case .signing: "SIGN"
        case .signatureRejected: "REFUS"
        case .validated: "OK"
        }
    }

    var icon: String {
        switch self {
        case .ready: "wave.3.right.circle.fill"
        case .scanning: "dot.radiowaves.left.and.right"
        case .tokenReady: "key.fill"
        case .signing: "signature"
        case .signatureRejected: "exclamationmark.triangle.fill"
        case .validated: "checkmark.seal.fill"
        }
    }

    var statusColor: Color {
        switch self {
        case .ready, .scanning: .blue
        case .tokenReady, .signing: .orange
        case .signatureRejected: .red
        case .validated: .green
        }
    }

    var progress: Int {
        switch self {
        case .ready: 0
        case .scanning: 1
        case .tokenReady: 2
        case .signing, .signatureRejected: 3
        case .validated: 4
        }
    }
}

struct SignatureMetrics {
    let points: [CGPoint]
    let duration: TimeInterval

    var hasEnoughPoints: Bool {
        points.count >= 32
    }

    var hasMinimumDuration: Bool {
        duration > 0.5
    }

    var hasMinimumBox: Bool {
        guard let box = boundingBox else { return false }
        return max(box.width, box.height) >= 250 || pathLength >= 250
    }

    var hasComplexity: Bool {
        angleChanges >= 5 && straightness < 0.92
    }

    var isValid: Bool {
        hasEnoughPoints && hasMinimumDuration && hasMinimumBox && hasComplexity
    }

    private var boundingBox: CGRect? {
        guard let first = points.first else { return nil }

        var minX = first.x
        var maxX = first.x
        var minY = first.y
        var maxY = first.y

        for point in points {
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)
        }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private var pathLength: CGFloat {
        guard points.count > 1 else { return 0 }

        return zip(points, points.dropFirst()).reduce(CGFloat.zero) { total, pair in
            let dx = pair.1.x - pair.0.x
            let dy = pair.1.y - pair.0.y
            return total + sqrt(dx * dx + dy * dy)
        }
    }

    private var straightness: CGFloat {
        guard let first = points.first, let last = points.last, pathLength > 0 else { return 1 }

        let dx = last.x - first.x
        let dy = last.y - first.y
        let directDistance = sqrt(dx * dx + dy * dy)
        return directDistance / pathLength
    }

    private var angleChanges: Int {
        guard points.count >= 3 else { return 0 }

        var changes = 0
        var lastAngle: CGFloat?

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let angle = atan2(current.y - previous.y, current.x - previous.x)

            if let lastAngle, abs(angle - lastAngle) > 0.35 {
                changes += 1
            }

            lastAngle = angle
        }

        return changes
    }
}

struct Course: Identifiable {
    let id = UUID()
    let title: String
    let room: String
    let time: String
    let status: AttendanceStatus
}

struct AttendanceRecord: Identifiable {
    let id = UUID()
    let course: String
    let date: String
    let time: String
    let status: AttendanceStatus
}

struct PagerItem {
    let title: String
    let icon: String
}

enum AttendanceStatus {
    case signed
    case current
    case upcoming
    case late
    case missed

    var label: String {
        switch self {
        case .signed: "Signe"
        case .current: "En cours"
        case .upcoming: "A venir"
        case .late: "Retard"
        case .missed: "Absent"
        }
    }

    var shortLabel: String {
        switch self {
        case .signed: "OK"
        case .current: "NOW"
        case .upcoming: "NEXT"
        case .late: "+12"
        case .missed: "ABS"
        }
    }

    var icon: String {
        switch self {
        case .signed: "checkmark.circle.fill"
        case .current: "wave.3.right.circle.fill"
        case .upcoming: "clock.fill"
        case .late: "exclamationmark.circle.fill"
        case .missed: "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .signed: .green
        case .current: .blue
        case .upcoming: .secondary
        case .late: .orange
        case .missed: .red
        }
    }
}
