import ComposableArchitecture
import SwiftUI

struct LibraryView: View {
    let store: StoreOf<LibraryFeature>
    var onOpenDetail: (CapturedImage) -> Void = { _ in }

    var body: some View {
        MockupScreen(
            title: "PicPocket",
            trailing: AnyView(
                HStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                    Image(systemName: "gearshape")
                }
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(MockupStyle.text)
            )
        ) {
            statBanner

            MockupSectionTitle(title: "분류된 카테고리")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(displayCategories) { category in
                    categoryCard(category)
                }
            }

            MockupSectionTitle(title: "검토가 필요한 이미지", trailing: "모두 보기")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        MockupPlaceholderThumbnail(height: 160)
                            .frame(width: 120)
                            .overlay(alignment: .bottom) {
                                Text("검토 필요")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                                    .background(.black.opacity(0.60))
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                    .padding(8)
                            }
                    }
                }
                .padding(4)
            }
        }
        .overlay {
            if store.isLoading {
                ProgressView()
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .task {
            await store.send(.load).finish()
        }
    }

    private var displayCategories: [CaptureCategory] {
        [.coupon, .receipt, .ticketReservation, .delivery]
    }

    private var statBanner: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 4) {
                Text("오늘 정리된 이미지")
                    .font(.system(size: 14))
                    .opacity(0.9)
                Text("\(totalCount)개")
                    .font(.system(size: 32, weight: .heavy))
                    .monospacedDigit()
                Text(summaryText)
                    .font(.system(size: 13))
                    .opacity(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)

            Circle()
                .fill(.white.opacity(0.10))
                .frame(width: 120, height: 120)
                .offset(x: 28, y: -28)
        }
        .foregroundStyle(.white)
        .background(MockupStyle.accent)
        .clipShape(RoundedRectangle(cornerRadius: MockupStyle.largeRadius, style: .continuous))
        .padding(.bottom, 0)
    }

    private var totalCount: Int {
        store.categoryCounts.values.reduce(0, +)
    }

    private var summaryText: String {
        let couponCount = store.categoryCounts[.coupon, default: 0]
        return couponCount == 0 ? "새로운 정보가 발견되면 여기에 표시됩니다." : "새로운 쿠폰 \(couponCount)개가 발견되었습니다."
    }

    private func categoryCard(_ category: CaptureCategory) -> some View {
        Button {
            onOpenDetail(sampleImage(category: category))
        } label: {
            MockupCard {
                ZStack(alignment: .topTrailing) {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: category.iconName)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(category.tint)
                            .frame(height: 34, alignment: .leading)

                        Text(category.mockupTitle)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(MockupStyle.text)
                            .lineLimit(1)

                        if category.isSensitive {
                            Label("민감 정보", systemImage: "lock.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(MockupStyle.danger)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 98, alignment: .leading)

                    Text("\(store.categoryCounts[category, default: 0])")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(MockupStyle.secondaryText)
                        .monospacedDigit()
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func sampleImage(category: CaptureCategory) -> CapturedImage {
        CapturedImage(
            assetLocalIdentifier: "mock-\(category.rawValue)",
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

private extension CaptureCategory {
    var mockupTitle: String {
        switch self {
        case .coupon: "쿠폰/할인"
        case .delivery: "배송정보"
        default: title
        }
    }

    var iconName: String {
        switch self {
        case .coupon: "ticket"
        case .receipt: "dollarsign"
        case .delivery: "shippingbox"
        case .ticketReservation: "wallet.pass"
        case .addressMap: "map"
        case .payment: "creditcard"
        case .unknown: "questionmark.square"
        }
    }

    var tint: Color {
        switch self {
        case .coupon: MockupStyle.warning
        case .receipt: MockupStyle.success
        case .delivery: Color(red: 0.545, green: 0.361, blue: 0.965)
        case .ticketReservation: MockupStyle.accent
        case .addressMap: Color(red: 0.055, green: 0.647, blue: 0.914)
        case .payment: MockupStyle.danger
        case .unknown: MockupStyle.secondaryText
        }
    }
}
