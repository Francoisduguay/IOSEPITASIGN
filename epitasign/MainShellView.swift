//
//  MainShellView.swift
//  epitasign
//

import SwiftUI

struct MainShellView: View {
    @State private var selectedPage = 1
    @State private var flowState: AttendanceFlowState = .ready
    let user: AuthUser?
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

                SettingsView(user: user, onLogout: onLogout)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            BottomPager(selectedPage: $selectedPage, flowState: flowState)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
        }
    }
}

struct BottomPager: View {
    @Binding var selectedPage: Int
    let flowState: AttendanceFlowState

    private let items = [
        PagerItem(title: "Cours", icon: "calendar"),
        PagerItem(title: "Signer", icon: "signature"),
        PagerItem(title: "Historique", icon: "clock.arrow.circlepath"),
        PagerItem(title: "Parametres", icon: "gearshape.fill")
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
