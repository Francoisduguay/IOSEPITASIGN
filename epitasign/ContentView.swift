//
//  ContentView.swift
//  epitasign
//
//  Created by Guest User on 24/04/2026.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @AppStorage("usesDarkMode") private var usesDarkMode = false
    @State private var isAuthenticated = false

    var body: some View {
        Group {
            if isAuthenticated {
                MainShellView {
                    isAuthenticated = false
                }
            } else {
                LoginView {
                    isAuthenticated = true
                }
            }
        }
        .preferredColorScheme(usesDarkMode ? .dark : nil)
    }
}

private struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showDomainError = false
    let onLogin: () -> Void

    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: 28) {
                Spacer(minLength: 24)

                VStack(alignment: .leading, spacing: 10) {
                    LogoMark(size: 58)

                    Text("EpitaSign")
                        .font(.system(size: 38, weight: .bold, design: .rounded))

                    Text("Presence NFC et signature numerique pour les cours.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 14) {
                    FieldRow(icon: "envelope.fill", placeholder: "prenom.nom@epita.fr", text: $email)

                    SecureField("Mot de passe", text: $password)
                        .textContentType(.password)
                        .padding(.horizontal, 16)
                        .frame(height: 54)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))

                    if showDomainError {
                        Label("Utilise une adresse EPITA valide.", systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                Button {
                    if email.lowercased().hasSuffix("@epita.fr") || email.isEmpty {
                        showDomainError = false
                        haptic(.success)
                        onLogin()
                    } else {
                        showDomainError = true
                        haptic(.warning)
                    }
                } label: {
                    Label("Continuer", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                }
                .buttonStyle(PrimaryButtonStyle(tint: .blue))
                .padding(.bottom, 18)
            }
            .padding(22)
        }
    }
}

private struct MainShellView: View {
    @State private var selectedPage = 1
    @State private var flowState: AttendanceFlowState = .ready
    let onLogout: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground()

            TabView(selection: $selectedPage) {
                ScheduleView()
                    .tag(0)

                SignView(flowState: $flowState)
                    .tag(1)

                HistoryView()
                    .tag(2)

                SettingsView(onLogout: onLogout)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            BottomPager(selectedPage: $selectedPage, flowState: flowState)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
        }
    }
}

private struct ScheduleView: View {
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

private struct SignView: View {
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
        case .ready:
            "Scanner NFC"
        case .scanning:
            "Scan en cours"
        case .tokenReady, .signing, .signatureRejected:
            "Valider la signature"
        case .validated:
            "Presence validee"
        }
    }

    private var actionIcon: String {
        switch flowState {
        case .ready:
            "wave.3.right.circle.fill"
        case .scanning:
            "dot.radiowaves.left.and.right"
        case .tokenReady, .signing, .signatureRejected:
            "signature"
        case .validated:
            "checkmark.seal.fill"
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

private struct HistoryView: View {
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

private struct SettingsView: View {
    @AppStorage("usesDarkMode") private var usesDarkMode = false
    @AppStorage("allowsNotifications") private var allowsNotifications = true
    @AppStorage("usesHaptics") private var usesHaptics = true
    let onLogout: () -> Void

    var body: some View {
        PageContainer(title: "Parametres", subtitle: "Compte et preferences") {
            VStack(spacing: 14) {
                ProfileHeader()

                SettingToggle(icon: "moon.fill", title: "Dark mode", subtitle: "Forcer l'apparence sombre", isOn: $usesDarkMode)
                SettingToggle(icon: "bell.badge.fill", title: "Notifications", subtitle: "Rappels avant les cours", isOn: $allowsNotifications)
                SettingToggle(icon: "iphone.radiowaves.left.and.right", title: "Haptique", subtitle: "Retour immediat au scan", isOn: $usesHaptics)

                Button(role: .destructive) {
                    haptic(.warning)
                    onLogout()
                } label: {
                    Label("Se deconnecter", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.top, 6)

                Spacer(minLength: 90)
            }
        }
    }
}

private struct PageContainer<Content: View, BottomAction: View>: View {
    let title: String
    let subtitle: String
    let content: Content
    let bottomAction: BottomAction

    init(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder bottomAction: () -> BottomAction
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
        self.bottomAction = bottomAction()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                LogoMark(size: 42)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text(subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 18)

            ScrollView(showsIndicators: false) {
                content
                    .padding(.horizontal, 20)
            }

            bottomAction
                .padding(.horizontal, 20)
                .padding(.bottom, 76)
        }
    }
}

private extension PageContainer where BottomAction == EmptyView {
    init(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
        self.bottomAction = EmptyView()
    }
}

private struct NFCButton: View {
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

private struct SignaturePanel: View {
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

private struct SignatureRules: View {
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

private struct RuleRow: View {
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

private struct StatusBanner: View {
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

private struct FlowSteps: View {
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

private struct StepChip: View {
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

private struct StepDivider: View {
    let isActive: Bool

    var body: some View {
        Capsule()
            .fill(isActive ? Color.green : Color.secondary.opacity(0.22))
            .frame(width: 12, height: 3)
    }
}

private struct BottomPager: View {
    @Binding var selectedPage: Int
    let flowState: AttendanceFlowState

    private let items = [
        PagerItem(title: "Cours", icon: "calendar"),
        PagerItem(title: "Signer", icon: "wave.3.right.circle.fill"),
        PagerItem(title: "Historique", icon: "clock.arrow.circlepath"),
        PagerItem(title: "Prefs", icon: "gearshape.fill")
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(items.indices, id: \.self) { index in
                Button {
                    selectedPage = index
                    haptic(.light)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: items[index].icon)
                            .font(.headline)
                        Text(items[index].title)
                            .font(.caption2.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(selectedPage == index ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(selectedPage == index ? activeColor(index) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 8)
    }

    private func activeColor(_ index: Int) -> Color {
        index == 1 ? flowState.statusColor : .blue
    }
}

private struct CourseRow: View {
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

private struct HistoryRow: View {
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

private struct ProfileHeader: View {
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 56, height: 56)
                .overlay {
                    Text("NE")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("nadir.etudiant@epita.fr")
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text("Role: student")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.shield.fill")
                .font(.title3)
                .foregroundStyle(.green)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct SettingToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .frame(width: 42, height: 42)
                .background(Color.blue.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct FieldRow: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct LogoMark: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.gradient)
            Image(systemName: "signature")
                .font(.system(size: size * 0.44, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

private struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color.blue.opacity(0.08),
                Color.green.opacity(0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(tint.gradient, in: RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.16), value: configuration.isPressed)
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.red)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
    }
}

private enum AttendanceFlowState {
    case ready
    case scanning
    case tokenReady
    case signing
    case signatureRejected
    case validated

    var title: String {
        switch self {
        case .ready:
            "Pret a scanner"
        case .scanning:
            "Lecture NFC"
        case .tokenReady:
            "Token temporaire actif"
        case .signing:
            "Signature en cours"
        case .signatureRejected:
            "Signature insuffisante"
        case .validated:
            "Presence validee"
        }
    }

    var message: String {
        switch self {
        case .ready:
            "Le bouton principal reste accessible en bas."
        case .scanning:
            "Simulation du scan physique de la carte."
        case .tokenReady:
            "Le token est pret. Signe dans la zone."
        case .signing:
            "Complete la signature puis valide."
        case .signatureRejected:
            "Ajoute plus de mouvement, duree et complexite."
        case .validated:
            "La preuve serait envoyee a Firebase Storage."
        }
    }

    var shortLabel: String {
        switch self {
        case .ready:
            "NFC"
        case .scanning:
            "SCAN"
        case .tokenReady:
            "TOKEN"
        case .signing:
            "SIGN"
        case .signatureRejected:
            "REFUS"
        case .validated:
            "OK"
        }
    }

    var icon: String {
        switch self {
        case .ready:
            "wave.3.right.circle.fill"
        case .scanning:
            "dot.radiowaves.left.and.right"
        case .tokenReady:
            "key.fill"
        case .signing:
            "signature"
        case .signatureRejected:
            "exclamationmark.triangle.fill"
        case .validated:
            "checkmark.seal.fill"
        }
    }

    var statusColor: Color {
        switch self {
        case .ready, .scanning:
            .blue
        case .tokenReady, .signing:
            .orange
        case .signatureRejected:
            .red
        case .validated:
            .green
        }
    }

    var progress: Int {
        switch self {
        case .ready:
            0
        case .scanning:
            1
        case .tokenReady:
            2
        case .signing, .signatureRejected:
            3
        case .validated:
            4
        }
    }
}

private struct SignatureMetrics {
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

private struct Course: Identifiable {
    let id = UUID()
    let title: String
    let room: String
    let time: String
    let status: AttendanceStatus
}

private struct AttendanceRecord: Identifiable {
    let id = UUID()
    let course: String
    let date: String
    let time: String
    let status: AttendanceStatus
}

private struct PagerItem {
    let title: String
    let icon: String
}

private enum AttendanceStatus {
    case signed
    case current
    case upcoming
    case late
    case missed

    var label: String {
        switch self {
        case .signed:
            "Signe"
        case .current:
            "En cours"
        case .upcoming:
            "A venir"
        case .late:
            "Retard"
        case .missed:
            "Absent"
        }
    }

    var shortLabel: String {
        switch self {
        case .signed:
            "OK"
        case .current:
            "NOW"
        case .upcoming:
            "NEXT"
        case .late:
            "+12"
        case .missed:
            "ABS"
        }
    }

    var icon: String {
        switch self {
        case .signed:
            "checkmark.circle.fill"
        case .current:
            "wave.3.right.circle.fill"
        case .upcoming:
            "clock.fill"
        case .late:
            "exclamationmark.circle.fill"
        case .missed:
            "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .signed:
            .green
        case .current:
            .blue
        case .upcoming:
            .secondary
        case .late:
            .orange
        case .missed:
            .red
        }
    }
}

private func haptic(_ style: HapticStyle) {
    switch style {
    case .light:
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    case .success:
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    case .warning:
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

private enum HapticStyle {
    case light
    case success
    case warning
}

#Preview {
    ContentView()
}
