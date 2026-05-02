import ComposableArchitecture
import Photos
import XCTest
@testable import PicPocket

@MainActor
final class OnboardingFeatureTests: XCTestCase {
    func testAuthorizedCompletesOnboarding() async {
        let store = TestStore(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        } withDependencies: {
            $0.photoLibraryClient.requestAuthorization = { .authorized }
        }

        await store.send(.photoAccessButtonTapped) {
            $0.isRequestingPermission = true
        }
        await store.receive(.photoAuthorizationResponse(.authorized)) {
            $0.isRequestingPermission = false
            $0.authorizationStatus = .authorized
        }
        await store.receive(.delegate(.completed))
    }
}
