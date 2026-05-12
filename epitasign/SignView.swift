//
//  SignView.swift
//  epitasign
//

import SwiftUI

struct SignView: View {
    @Binding var flowState: AttendanceFlowState
    @State private var points: [CGPoint] = []
    @State private var signatureStartedAt: Date?
    @State private var signatureDuration: TimeInterval = 0

    private var metrics: SignatureMetrics {
        SignatureMetrics(points: points, duration: signatureDuration)
    }

    var body: some View {
        PageContainer(title: "Signer", subtitle: "NFC puis signature") {
            VStack(spacing: 18) {
                StatusBanner(flowState: flowState)

                VStack(spacing: 18) {
                    NFCButton(flowState: $flowState) {
                        points.removeAll()
                        signatureDuration = 0
                    }

                    FlowSteps(current: flowState)
                }
                .padding(.top, 4)

                SignaturePanel(
                    points: $points,
                    startedAt: $signatureStartedAt,
                    duration: $signatureDuration,
                    isEnabled: flowState == .tokenReady || flowState == .signing || flowState == .signatureRejected
                )

                SignatureRules(metrics: metrics)

                Spacer(minLength: 90)
            }
        } bottomAction: {
            Button {
                validateSignature()
            } label: {
                Label(actionTitle, systemImage: actionIcon)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
            }
            .buttonStyle(PrimaryButtonStyle(tint: flowState.statusColor))
            .disabled(!canTapMainAction)
            .opacity(canTapMainAction ? 1 : 0.45)
        }
        .onChange(of: points.count) {
            if flowState == .tokenReady {
                flowState = .signing
            }
        }
    }

    private var actionTitle: String {
        switch flowState {
        case .ready: "Scanner NFC"
        case .scanning: "Scan en cours"
        case .tokenReady, .signing, .signatureRejected: "Valider la signature"
        case .validated: "Presence validee"
        }
    }

    private var actionIcon: String {
        switch flowState {
        case .ready: "wave.3.right.circle.fill"
        case .scanning: "dot.radiowaves.left.and.right"
        case .tokenReady, .signing, .signatureRejected: "signature"
        case .validated: "checkmark.seal.fill"
        }
    }

    private var canTapMainAction: Bool {
        flowState == .ready || flowState == .tokenReady || flowState == .signing || flowState == .signatureRejected
    }

    private func validateSignature() {
        if flowState == .ready {
            flowState = .scanning
            haptic(.light)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                flowState = .tokenReady
                haptic(.success)
            }
            return
        }

        if metrics.isValid {
            flowState = .validated
            haptic(.success)
        } else {
            flowState = .signatureRejected
            haptic(.warning)
        }
    }
}

struct NFCButton: View {
    @Binding var flowState: AttendanceFlowState
    let resetSignature: () -> Void

    var body: some View {
        Button {
            flowState = .scanning
            resetSignature()
            haptic(.light)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                flowState = .tokenReady
                haptic(.success)
            }
        } label: {
            VStack(spacing: 12) {
                Image(systemName: flowState == .scanning ? "dot.radiowaves.left.and.right" : "wave.3.right.circle.fill")
                    .font(.system(size: 46, weight: .semibold))

                Text(flowState == .scanning ? "Approche la carte" : "Scanner NFC")
                    .font(.title3.weight(.bold))

                Text("Token temporaire genere apres validation serveur")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 190)
            .background(flowState.statusColor.gradient, in: RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .topTrailing) {
                Text(flowState.shortLabel)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.18), in: Capsule())
                    .padding(14)
            }
        }
        .disabled(flowState == .scanning)
        .buttonStyle(.plain)
    }
}

struct SignaturePanel: View {
    @Binding var points: [CGPoint]
    @Binding var startedAt: Date?
    @Binding var duration: TimeInterval
    let isEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Signature", systemImage: "signature")
                    .font(.headline)
                Spacer()
                Button {
                    points.removeAll()
                    duration = 0
                    startedAt = nil
                    haptic(.light)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.headline)
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(IconButtonStyle())
                .disabled(points.isEmpty)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.background.opacity(0.72))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color(.separator).opacity(isEnabled ? 0.8 : 0.35), lineWidth: 1)
                    }

                Canvas { context, _ in
                    guard points.count > 1 else { return }

                    var path = Path()
                    path.move(to: points[0])

                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }

                    context.stroke(path, with: .color(.primary), style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round))
                }

                if points.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: isEnabled ? "hand.draw.fill" : "lock.fill")
                            .font(.title2)
                        Text(isEnabled ? "Signe ici avec le doigt" : "Scanne le NFC avant de signer")
                            .font(.callout.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 250)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isEnabled else { return }

                        if startedAt == nil {
                            startedAt = Date()
                        }

                        points.append(value.location)

                        if let startedAt {
                            duration = Date().timeIntervalSince(startedAt)
                        }
                    }
                    .onEnded { _ in
                        if let startedAt {
                            duration = Date().timeIntervalSince(startedAt)
                        }
                    }
            )
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct SignatureRules: View {
    let metrics: SignatureMetrics

    var body: some View {
        VStack(spacing: 8) {
            RuleRow(title: "Minimum 250 px", isValid: metrics.hasMinimumBox)
            RuleRow(title: "Assez de points", isValid: metrics.hasEnoughPoints)
            RuleRow(title: "Duree superieure a 0.5s", isValid: metrics.hasMinimumDuration)
            RuleRow(title: "Pas une ligne droite", isValid: metrics.hasComplexity)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct RuleRow: View {
    let title: String
    let isValid: Bool

    var body: some View {
        HStack {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isValid ? .green : .secondary)
            Text(title)
                .font(.subheadline.weight(.medium))
            Spacer()
        }
    }
}

struct StatusBanner: View {
    let flowState: AttendanceFlowState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: flowState.icon)
                .font(.title3)
                .frame(width: 42, height: 42)
                .background(flowState.statusColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(flowState.statusColor)

            VStack(alignment: .leading, spacing: 3) {
                Text(flowState.title)
                    .font(.headline)
                Text(flowState.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct FlowSteps: View {
    let current: AttendanceFlowState

    var body: some View {
        HStack(spacing: 6) {
            StepChip(title: "NFC", icon: "wave.3.right", isActive: current.progress >= 1, color: current.statusColor)
            StepDivider(isActive: current.progress >= 2)
            StepChip(title: "Token", icon: "key.fill", isActive: current.progress >= 2, color: current.statusColor)
            StepDivider(isActive: current.progress >= 3)
            StepChip(title: "Signature", icon: "signature", isActive: current.progress >= 3, color: current.statusColor)
            StepDivider(isActive: current.progress >= 4)
            StepChip(title: "Valide", icon: "checkmark", isActive: current.progress >= 4, color: current.statusColor)
        }
    }
}

struct StepChip: View {
    let title: String
    let icon: String
    let isActive: Bool
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
            Text(title)
                .font(.caption2.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(isActive ? .white : .secondary)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(isActive ? color : Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct StepDivider: View {
    let isActive: Bool

    var body: some View {
        Capsule()
            .fill(isActive ? Color.green : Color.secondary.opacity(0.22))
            .frame(width: 12, height: 3)
    }
}
