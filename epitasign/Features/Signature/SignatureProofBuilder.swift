//
//  SignatureProofBuilder.swift
//  epitasign
//

import SwiftUI
import UIKit

enum SignatureProofBuilder {
    static func makeProof(points: [CGPoint], duration: TimeInterval) throws -> SignatureProof {
        let size = CGSize(width: 600, height: 250)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            context.cgContext.setFillColor(UIColor.clear.cgColor)
            context.cgContext.fill(CGRect(origin: .zero, size: size))

            guard points.count > 1 else { return }

            let normalized = normalize(points: points, into: size)
            let path = UIBezierPath()
            path.lineWidth = 4
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.move(to: normalized[0])

            for point in normalized.dropFirst() {
                path.addLine(to: point)
            }

            UIColor.label.setStroke()
            path.stroke()
        }

        guard let png = image.pngData() else {
            throw AttendanceBackendError.invalidSignature
        }

        let box = boundingBox(for: points)

        return SignatureProof(
            base64PNG: png.base64EncodedString(),
            pointCount: points.count,
            duration: duration,
            width: box.width,
            height: box.height
        )
    }

    private static func normalize(points: [CGPoint], into size: CGSize) -> [CGPoint] {
        let box = boundingBox(for: points)
        guard box.width > 0, box.height > 0 else { return points }

        let inset: CGFloat = 20
        let scale = min((size.width - inset * 2) / box.width, (size.height - inset * 2) / box.height)

        return points.map { point in
            CGPoint(
                x: (point.x - box.minX) * scale + inset,
                y: (point.y - box.minY) * scale + inset
            )
        }
    }

    private static func boundingBox(for points: [CGPoint]) -> CGRect {
        guard let first = points.first else { return .zero }

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
}
