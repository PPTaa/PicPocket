import ComposableArchitecture
import SwiftUI

struct OnboardingView: View {
    let store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 120, height: 120)
                .background(MockupStyle.accent)
                .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                .shadow(color: MockupStyle.accent.opacity(0.30), radius: 30, x: 0, y: 18)
                .padding(.bottom, 32)

            Text("반가워요!\nPicPocket 입니다.")
                .font(.system(size: 32, weight: .heavy))
                .multilineTextAlignment(.center)
                .foregroundStyle(MockupStyle.text)
                .padding(.bottom, 12)

            Text("지저분한 스크린샷 속에서\n중요한 정보만 쏙쏙 찾아 드릴게요.")
                .font(.system(size: 16, weight: .regular))
                .lineSpacing(5)
                .multilineTextAlignment(.center)
                .foregroundStyle(MockupStyle.secondaryText)

            VStack(alignment: .leading, spacing: 20) {
                onboardingBullet(
                    icon: "shield",
                    title: "100% 온디바이스 보안",
                    body: "사진을 서버에 올리지 않고 기기 안에서만 분석해요."
                )
                onboardingBullet(
                    icon: "shippingbox",
                    title: "똑똑한 자동 분류",
                    body: "쿠폰, 영수증, 티켓 등을 AI가 알아서 정리해줍니다."
                )
            }
            .padding(.vertical, 32)

            Spacer()

            Button {
                store.send(.photoAccessButtonTapped)
            } label: {
                Text(store.isRequestingPermission ? "권한 요청 중" : "사진 접근 허용하고 시작하기")
            }
            .buttonStyle(MockupPrimaryButtonStyle())
            .disabled(store.isRequestingPermission)

            Text("선택한 사진만 허용해도 기능을 사용할 수 있습니다.")
                .font(.system(size: 12))
                .foregroundStyle(MockupStyle.secondaryText)
                .padding(.top, 16)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            LinearGradient(
                colors: [MockupStyle.accentSoft, MockupStyle.background],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.42)
            )
            .ignoresSafeArea()
        }
    }

    private func onboardingBullet(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(MockupStyle.accent)
                .frame(width: 36, height: 36)
                .background(MockupStyle.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(MockupStyle.text)
                Text(body)
                    .font(.system(size: 13))
                    .foregroundStyle(MockupStyle.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
