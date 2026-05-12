//
//  SharedComponents.swift
//  epitasign
//

import SwiftUI

struct PageContainer<Content: View, BottomAction: View>: View {
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

extension PageContainer where BottomAction == EmptyView {
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

struct LogoMark: View {
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

struct FieldRow: View {
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
