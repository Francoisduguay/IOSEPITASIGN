//
//  MainShellView.swift
//  epitasign
//

import SwiftUI

struct MainShellView: View {
    @State private var selectedPage = 0
    @State private var flowState: AttendanceFlowState = .ready
    let user: AuthUser?
    let onLogout: () -> Void

    private var isTeacher: Bool {
        user?.role == .teacher
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground()

            TabView(selection: $selectedPage) {
                ScheduleView(user: user)
                    .tag(0)

                if isTeacher {
                    SettingsView(user: user, onLogout: onLogout)
                        .tag(1)
                } else {
                    SignView(flowState: $flowState)
                        .tag(1)

                    HistoryView()
                        .tag(2)

                    SettingsView(user: user, onLogout: onLogout)
                        .tag(3)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: isTeacher) {
                selectedPage = 0
            }

            BottomPager(selectedPage: $selectedPage, flowState: flowState, isTeacher: isTeacher)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
        }
    }
}

struct BottomPager: View {
    @Binding var selectedPage: Int
    let flowState: AttendanceFlowState
    let isTeacher: Bool

    private var items: [PagerItem] {
        if isTeacher {
            return [
                PagerItem(title: "Emploi du temps", icon: "calendar"),
                PagerItem(title: "Parametres", icon: "gearshape.fill")
            ]
        }

        return [
            PagerItem(title: "Emploi du temps", icon: "calendar"),
            PagerItem(title: "Signer", icon: "signature"),
            PagerItem(title: "Historique", icon: "clock.arrow.circlepath"),
            PagerItem(title: "Parametres", icon: "gearshape.fill")
        ]
    }

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
        !isTeacher && index == 1 ? flowState.statusColor : Color.appBlue
    }
}
