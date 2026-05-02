import ComposableArchitecture
import Photos
import SwiftUI

struct SettingsView: View {
    let store: StoreOf<SettingsFeature>
    @State private var faceIDEnabled = true

    var body: some View {
        MockupScreen(title: "설정") {
            MockupSectionTitle(title: "데이터 및 권한")
            settingsGroup {
                settingsRow(title: "사진 접근 권한", trailing: title(for: store.authorizationStatus), trailingColor: MockupStyle.success) {
                    store.send(.manageSelectedPhotosButtonTapped)
                }

                settingsRow(title: "분석 데이터 초기화", trailing: "초기화", trailingColor: MockupStyle.danger) {}

                Button {
                    faceIDEnabled.toggle()
                } label: {
                    HStack {
                        Text("Face ID 잠금")
                            .foregroundStyle(MockupStyle.text)
                        Spacer()
                        ToggleSwitch(isOn: faceIDEnabled)
                    }
                    .padding(18)
                }
                .buttonStyle(.plain)
            }

            MockupSectionTitle(title: "앱 정보")
            settingsGroup {
                HStack {
                    Text("버전")
                        .foregroundStyle(MockupStyle.text)
                    Spacer()
                    Text("1.0.0 (MVP)")
                        .foregroundStyle(MockupStyle.secondaryText)
                }
                .padding(18)

                Divider().background(MockupStyle.border)

                settingsRow(title: "오픈소스 라이선스", trailingSystemImage: "chevron.right") {}
            }

            Text("PicPocket은 당신의 소중한 개인정보를\n기기 밖으로 보내지 않습니다. 🔒")
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundStyle(MockupStyle.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        }
        .task {
            await store.send(.load).finish()
        }
    }

    private func settingsGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(MockupStyle.surface)
        .clipShape(RoundedRectangle(cornerRadius: MockupStyle.mediumRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MockupStyle.mediumRadius, style: .continuous)
                .stroke(MockupStyle.border, lineWidth: 1)
        }
    }

    private func settingsRow(
        title: String,
        trailing: String? = nil,
        trailingColor: Color = MockupStyle.secondaryText,
        trailingSystemImage: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(MockupStyle.text)
                Spacer()
                if let trailing {
                    Text(trailing)
                        .fontWeight(.semibold)
                        .foregroundStyle(trailingColor)
                }
                if let trailingSystemImage {
                    Image(systemName: trailingSystemImage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MockupStyle.secondaryText)
                }
            }
            .padding(18)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MockupStyle.border)
                .frame(height: 1)
                .padding(.leading, 18)
        }
    }

    private func title(for status: PHAuthorizationStatus) -> String {
        switch status {
        case .authorized: "전체 허용"
        case .limited: "선택 허용"
        case .denied: "거부됨"
        case .restricted: "제한됨"
        case .notDetermined: "미결정"
        @unknown default: "알 수 없음"
        }
    }
}

private struct ToggleSwitch: View {
    let isOn: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(isOn ? MockupStyle.accent : MockupStyle.secondaryText)
            .frame(width: 44, height: 24)
            .overlay(alignment: .leading) {
                Circle()
                    .fill(.white)
                    .frame(width: 20, height: 20)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                    .offset(x: isOn ? 22 : 2)
            }
    }
}
