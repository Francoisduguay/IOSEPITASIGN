//
//  SignView.swift
//  epitasign
//

import SwiftUI

struct SignView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Binding var flowState: AttendanceFlowState
    @State private var points: [CGPoint] = []
    @State private var signatureStartedAt: Date?
    @State private var signatureDuration: TimeInterval = 0
    @State private var activeToken: AttendanceToken?
    @State private var activeCourse: Course?
    @State private var backendError: String?
    @State private var enteredCode = ""
    @State private var isWorking = false
    @State private var showsValidationToast = false
    @State private var validationToastTask: Task<Void, Never>?

    private var metrics: SignatureMetrics {
        SignatureMetrics(points: points, duration: signatureDuration)
    }

    var body: some View {
        PageContainer(title: "Signer", subtitle: signSubtitle) {
            VStack(spacing: 18) {
                StatusBanner(flowState: flowState)

                if needsCode {
                    CodeEntryCard(
                        code: $enteredCode,
                        flowState: $flowState,
                        isWorking: isWorking
                    )
                } else {
                    SignaturePanel(
                        points: $points,
                        startedAt: $signatureStartedAt,
                        duration: $signatureDuration,
                        isEnabled: true
                    )

                    SignatureRules(metrics: metrics)
                }

                if let backendError {
                    Label(backendError, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }

                if showsValidationToast {
                    Label("Presence validee", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(.green.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                }

                Spacer(minLength: 90)
            }
        } bottomAction: {
            if flowState == .validated && !showsValidationToast {
                EmptyView()
            } else {
                Button {
                    validateSignature()
                } label: {
                    Label(actionTitle, systemImage: actionIcon)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                }
                .buttonStyle(PrimaryButtonStyle(tint: actionTint))
                .disabled(!canTapMainAction)
                .opacity(canTapMainAction ? 1 : 0.45)
            }
        }
        .onChange(of: points.count) {
            if flowState == .tokenReady {
                flowState = .signing
            }
        }
        .task {
            await loadActiveCourse()
        }
    }

    private var needsCode: Bool {
        flowState == .ready || flowState == .scanning
    }

    private var signSubtitle: String {
        if needsCode {
            return activeCourse?.title ?? "Code du cours"
        }

        return activeCourse?.title ?? "Signature"
    }

    private var actionTitle: String {
        switch flowState {
        case .ready: "Verifier le code"
        case .scanning: isWorking ? "Traitement en cours" : "Verification du code"
        case .tokenReady, .signing, .signatureRejected: "Valider la signature"
        case .validated: "Presence validee"
        }
    }

    private var actionIcon: String {
        switch flowState {
        case .ready: "number.circle.fill"
        case .scanning: "key.fill"
        case .tokenReady, .signing, .signatureRejected: "signature"
        case .validated: "checkmark.seal.fill"
        }
    }

    private var actionTint: Color {
        needsCode ? Color(red: 0.43, green: 0.58, blue: 0.88) : flowState.statusColor
    }

    private var canTapMainAction: Bool {
        !isWorking && ((flowState == .ready && !enteredCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) || flowState == .tokenReady || flowState == .signing || flowState == .signatureRejected)
    }

    private func validateCode() {
        guard !isWorking else { return }

        guard AttendanceCode.isValid(enteredCode) else {
            backendError = "Code incorrect. Entre le code donne pour le cours."
            activeToken = nil
            flowState = .ready
            haptic(.warning)
            return
        }

        points.removeAll()
        signatureDuration = 0
        signatureStartedAt = nil
        activeToken = nil
        showsValidationToast = false
        validationToastTask?.cancel()
        backendError = nil

        guard let courseId = activeCourse?.id else {
            backendError = "Aucun cours disponible pour generer le token."
            flowState = .ready
            haptic(.warning)
            return
        }

        Task {
            isWorking = true
            flowState = .scanning
            backendError = nil
            haptic(.light)

            do {
                let code = AttendanceCode.scanResult(from: enteredCode)
                activeToken = try await environment.attendanceService.requestToken(for: code, courseId: courseId)
                flowState = .tokenReady
                haptic(.success)
            } catch {
                backendError = error.localizedDescription
                flowState = .ready
                haptic(.warning)
            }

            isWorking = false
        }
    }

    private func validateSignature() {
        if flowState == .ready {
            validateCode()
            return
        }

        guard metrics.isValid else {
            flowState = .signatureRejected
            haptic(.warning)
            return
        }

        guard let activeToken else {
            backendError = "Aucun token actif. Valide a nouveau le code."
            flowState = .ready
            haptic(.warning)
            return
        }

        Task {
            isWorking = true
            backendError = nil

            do {
                guard let courseId = activeCourse?.id else {
                    throw AttendanceBackendError.missingActiveCourse
                }

                let proof = try SignatureProofBuilder.makeProof(points: points, duration: signatureDuration)
                let request = AttendanceValidationRequest(
                    token: activeToken,
                    signatureProof: proof,
                    signatureMetrics: metrics,
                    courseId: courseId
                )

                try await environment.attendanceService.submitSignature(request)
                environment.markCourseSigned(courseId)
                flowState = .validated
                scheduleValidationToast()
                haptic(.success)
            } catch {
                backendError = error.localizedDescription
                flowState = .signatureRejected
                haptic(.warning)
            }

            isWorking = false
        }
    }

    private func scheduleValidationToast() {
        validationToastTask?.cancel()
        showsValidationToast = true

        validationToastTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                showsValidationToast = false
                validationToastTask = nil
            }
        }
    }

    private func loadActiveCourse() async {
        do {
            let courses = try await environment.courseService.fetchCourses()
            activeCourse = pickActiveCourse(from: courses)
        } catch {
            backendError = error.localizedDescription
        }
    }

    private func pickActiveCourse(from courses: [Course]) -> Course? {
        let calendar = Calendar.current
        let now = Date()
        let sortedCourses = courses.sorted { $0.startsAt < $1.startsAt }

        if let current = sortedCourses.first(where: { $0.status == .current }) {
            return current
        }

        if let today = sortedCourses.first(where: { calendar.isDate($0.startsAt, inSameDayAs: now) }) {
            return today
        }

        return sortedCourses.first(where: { $0.startsAt > now }) ?? sortedCourses.first
    }
}

struct CodeEntryCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var code: String
    @Binding var flowState: AttendanceFlowState
    let isWorking: Bool

    private var cardColor: Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.15, blue: 0.28)
            : Color(red: 0.86, green: 0.91, blue: 1.0)
    }

    private var fieldColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.12)
            : .white
    }

    private var codeTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var badgeColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.14)
            : Color.white.opacity(0.72)
    }

    private var badgeTextColor: Color {
        colorScheme == .dark
            ? Color(red: 0.72, green: 0.82, blue: 1.0)
            : Color(red: 0.19, green: 0.29, blue: 0.55)
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: flowState == .scanning ? "key.fill" : "number.circle.fill")
                .font(.system(size: 46, weight: .semibold))

            Text(flowState == .scanning ? "Verification" : "Code du cours")
                .font(.title3.weight(.bold))

            Text(isWorking ? "Validation serveur en cours" : "Entre le code pour debloquer la signature")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("Ex: EPITA2026", text: $code)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .textFieldStyle(.plain)
                .font(.headline.monospaced())
                .multilineTextAlignment(.center)
                .foregroundColor(codeTextColor)
                .tint(.blue)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(fieldColor, in: RoundedRectangle(cornerRadius: 8))
        }
        .foregroundStyle(.primary)
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(cardColor, in: RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .topTrailing) {
            Text(flowState.shortLabel)
                .font(.caption.weight(.bold))
                .foregroundStyle(badgeTextColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(badgeColor, in: Capsule())
                .padding(14)
        }
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
                        Text(isEnabled ? "Signe ici avec le doigt" : "Entre le code du cours avant de signer")
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
            StepChip(title: "Code", icon: "number", isActive: current.progress >= 1, color: current.statusColor)
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
