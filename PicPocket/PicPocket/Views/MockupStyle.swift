import SwiftUI

enum MockupStyle {
    static let background = Color(red: 0.973, green: 0.980, blue: 0.988)
    static let surface = Color.white
    static let surfaceMuted = Color(red: 0.945, green: 0.961, blue: 0.976)
    static let text = Color(red: 0.059, green: 0.090, blue: 0.165)
    static let secondaryText = Color(red: 0.392, green: 0.455, blue: 0.545)
    static let accent = Color(red: 0.145, green: 0.388, blue: 0.922)
    static let accentSoft = Color(red: 0.859, green: 0.918, blue: 0.996)
    static let border = Color(red: 0.886, green: 0.910, blue: 0.941)
    static let success = Color(red: 0.063, green: 0.725, blue: 0.506)
    static let warning = Color(red: 0.961, green: 0.620, blue: 0.043)
    static let danger = Color(red: 0.937, green: 0.267, blue: 0.267)

    static let largeRadius: CGFloat = 24
    static let mediumRadius: CGFloat = 16
}

struct MockupScreen<Content: View>: View {
    let title: String
    var trailing: AnyView?
    @ViewBuilder var content: Content

    init(title: String, trailing: AnyView? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.trailing = trailing
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(MockupStyle.text)
                Spacer()
                trailing
            }
            .padding(.horizontal, 24)
            .padding(.top, 42)
            .padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    content
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 118)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MockupStyle.background)
    }
}

struct MockupCard<Content: View>: View {
    var radius: CGFloat = MockupStyle.mediumRadius
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(20)
        .background(MockupStyle.surface)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(MockupStyle.border, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
    }
}

struct MockupPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(MockupStyle.accent)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
    }
}

struct MockupSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(MockupStyle.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(MockupStyle.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct MockupSectionTitle: View {
    let title: String
    var trailing: String?

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MockupStyle.text)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(MockupStyle.accent)
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 16)
    }
}

struct MockupPlaceholderThumbnail: View {
    var height: CGFloat

    var body: some View {
        LinearGradient(
            colors: [
                MockupStyle.surfaceMuted,
                Color(red: 0.820, green: 0.867, blue: 0.933),
                MockupStyle.accentSoft
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
