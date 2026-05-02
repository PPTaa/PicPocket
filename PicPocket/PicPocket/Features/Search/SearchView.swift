import ComposableArchitecture
import SwiftUI

struct SearchView: View {
    let store: StoreOf<SearchFeature>
    var onOpenDetail: (CapturedImage) -> Void = { _ in }

    var body: some View {
        MockupScreen(title: "검색") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(MockupStyle.secondaryText)

                    TextField(
                        "내용, 카테고리, 날짜 검색",
                        text: Binding(
                            get: { store.query },
                            set: { store.send(.queryChanged($0)) }
                        )
                    )
                    .font(.system(size: 16))
                    .submitLabel(.search)
                    .onSubmit {
                        store.send(.searchButtonTapped)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(MockupStyle.surfaceMuted)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["영수증", "운송장", "계좌번호", "할인코드", "주소"], id: \.self) { tag in
                            Button {
                                store.send(.queryChanged(tag))
                                store.send(.searchButtonTapped)
                            } label: {
                                Text("#\(tag)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(MockupStyle.text)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(MockupStyle.surface)
                                    .clipShape(Capsule())
                                    .overlay {
                                        Capsule().stroke(MockupStyle.border, lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 4)
                }
            }

            VStack(spacing: 0) {
                if store.results.isEmpty {
                    ForEach(mockResults) { result in
                        mockResultRow(result)
                    }
                } else {
                    ForEach(store.results) { image in
                        Button {
                            onOpenDetail(image)
                        } label: {
                            resultRow(image)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.top, 12)
        }
        .overlay {
            if store.isSearching {
                ProgressView()
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func resultRow(_ image: CapturedImage) -> some View {
        HStack(spacing: 16) {
            MockupPlaceholderThumbnail(height: 80)
                .frame(width: 80)

            VStack(alignment: .leading, spacing: 4) {
                Text(image.category.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(MockupStyle.text)
                Text("분류: \(image.category.title) • \(imageDate(image))")
                    .font(.system(size: 12))
                    .foregroundStyle(MockupStyle.secondaryText)
                Text(image.recognizedText.isEmpty ? "인식된 텍스트 없음" : image.recognizedText)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(MockupStyle.secondaryText)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MockupStyle.border)
                .frame(height: 1)
        }
    }

    private func mockResultRow(_ result: MockSearchResult) -> some View {
        Button {
            onOpenDetail(result.image)
        } label: {
            HStack(spacing: 16) {
                MockupPlaceholderThumbnail(height: 80)
                    .frame(width: 80)

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(MockupStyle.text)
                    Text(result.meta)
                        .font(.system(size: 12))
                        .foregroundStyle(MockupStyle.secondaryText)
                    Text(result.snippet)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(MockupStyle.secondaryText)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.vertical, 16)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(MockupStyle.border)
                    .frame(height: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func imageDate(_ image: CapturedImage) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: image.creationDate ?? image.lastAnalyzedAt)
    }

    private var mockResults: [MockSearchResult] {
        [
            MockSearchResult(title: "스타벅스 기프티콘", meta: "분류: 쿠폰 • 2026.04.30", snippet: "유효기간: 2026-12-31...", category: .coupon),
            MockSearchResult(title: "쿠팡 주문 영수증", meta: "분류: 영수증 • 2026.05.01", snippet: "총 결제금액: 24,500원...", category: .receipt)
        ]
    }
}

private struct MockSearchResult: Identifiable {
    let id = UUID()
    var title: String
    var meta: String
    var snippet: String
    var category: CaptureCategory

    var image: CapturedImage {
        CapturedImage(
            assetLocalIdentifier: "mock-\(id.uuidString)",
            sourceKind: .manualSelection,
            creationDate: Date(),
            addedDate: Date(),
            recognizedText: "[Starbucks]\n아메리카노 Tall (HOT)\n유효기간: 2026.12.31 까지\n사용처: 전국 스타벅스 매장\n바코드번호: 1234 5678 9012",
            detectedCodes: ["1234 5678 9012"],
            category: category,
            confidence: 0.98,
            reviewStatus: .new,
            isSensitive: category.isSensitive,
            lastAnalyzedAt: Date()
        )
    }
}
