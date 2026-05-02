import ComposableArchitecture
import XCTest
@testable import PicPocket

@MainActor
final class SearchFeatureTests: XCTestCase {
    func testSearchLoadsResults() async {
        let image = CapturedImage.fixture(category: .delivery, id: "delivery")

        let store = TestStore(initialState: SearchFeature.State(query: "배송")) {
            SearchFeature()
        } withDependencies: {
            $0.capturedImageRepository.search = { query in
                XCTAssertEqual(query, "배송")
                return [image]
            }
        }

        await store.send(.searchButtonTapped) {
            $0.isSearching = true
        }
        await store.receive(.searchResponse(.success([image]))) {
            $0.isSearching = false
            $0.results = [image]
        }
    }
}
