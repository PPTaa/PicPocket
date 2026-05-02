import ComposableArchitecture
import SwiftUI

struct ImageDetailView: View {
    let store: StoreOf<ImageDetailFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 22, weight: .semibold))
                }
                .buttonStyle(.plain)
                Spacer()
                Text("상세 정보")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Image(systemName: "bookmark")
                    .font(.system(size: 22, weight: .semibold))
            }
            .foregroundStyle(MockupStyle.text)
            .padding(.horizontal, 24)
            .padding(.top, 42)
            .padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    MockupPlaceholderThumbnail(height: 560)
                        .clipShape(RoundedRectangle(cornerRadius: MockupStyle.largeRadius, style: .continuous))

                    MockupSectionTitle(title: "분류 수정")
                    HStack(spacing: 6) {
                        ForEach([CaptureCategory.coupon, .receipt, .unknown]) { category in
                            Button {
                                store.send(.categoryChanged(category))
                            } label: {
                                Text(category == .unknown ? "기타" : category.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(store.image.category == category ? MockupStyle.text : MockupStyle.secondaryText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background {
                                        if store.image.category == category {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(MockupStyle.surface)
                                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(MockupStyle.surfaceMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    HStack(spacing: 12) {
                        metaItem(title: "분석 신뢰도", value: "\(Int(store.image.confidence * 100))%", color: MockupStyle.success)
                        metaItem(title: "민감 정보", value: store.image.isSensitive ? "있음" : "없음", color: MockupStyle.text)
                    }
                    .padding(.top, 16)

                    MockupSectionTitle(title: "인식된 텍스트")
                    MockupCard {
                        ZStack(alignment: .topTrailing) {
                            Text(store.image.recognizedText.isEmpty ? "인식된 텍스트 없음" : store.image.recognizedText)
                                .font(.system(size: 14))
                                .lineSpacing(5)
                                .foregroundStyle(MockupStyle.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.trailing, 52)

                            Text("복사")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MockupStyle.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(MockupStyle.surfaceMuted)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .background(MockupStyle.background)
        .navigationBarBackButtonHidden(true)
    }

    private func metaItem(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(MockupStyle.secondaryText)
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(MockupStyle.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
