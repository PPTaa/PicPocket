import ComposableArchitecture
import XCTest
@testable import PicPocket

@MainActor
final class LibraryFeatureTests: XCTestCase {
    func testLoadBuildsCategoryCounts() async {
        let images = [
            CapturedImage.fixture(category: .coupon, id: "1"),
            CapturedImage.fixture(category: .coupon, id: "2"),
            CapturedImage.fixture(category: .payment, id: "3")
        ]

        let store = TestStore(initialState: LibraryFeature.State()) {
            LibraryFeature()
        } withDependencies: {
            $0.capturedImageRepository.all = { images }
        }

        await store.send(.load) {
            $0.isLoading = true
        }
        await store.receive(.loadResponse(.success(images))) {
            $0.isLoading = false
            $0.categoryCounts = [.coupon: 2, .payment: 1]
            $0.recentImages = [.coupon: Array(images.prefix(2)), .payment: [images[2]]]
        }
    }
}

extension CapturedImage {
    static func fixture(category: CaptureCategory = .unknown, id: String = UUID().uuidString) -> CapturedImage {
        CapturedImage(
            assetLocalIdentifier: id,
            sourceKind: .screenshot,
            creationDate: Date(timeIntervalSince1970: 10),
            addedDate: Date(timeIntervalSince1970: 11),
            recognizedText: "테스트 텍스트",
            detectedCodes: [],
            category: category,
            confidence: 0.8,
            reviewStatus: .new,
            isSensitive: category.isSensitive,
            lastAnalyzedAt: Date(timeIntervalSince1970: 12)
        )
    }
}
