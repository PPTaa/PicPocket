import ComposableArchitecture
import Photos

struct SettingsFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var authorizationStatus: PHAuthorizationStatus = .notDetermined
        var didRequestLimitedPicker = false
        var shouldStartAllTimeScan = false
    }

    enum Action: Equatable {
        case load
        case manageSelectedPhotosButtonTapped
        case fullScanButtonTapped
    }

    @Dependency(\.photoLibraryClient) var photoLibraryClient

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
            case .load:
                state.authorizationStatus = photoLibraryClient.authorizationStatus()
                return .none

            case .manageSelectedPhotosButtonTapped:
                state.didRequestLimitedPicker = true
                return .run { _ in
                    await photoLibraryClient.presentLimitedLibraryPicker()
                }

            case .fullScanButtonTapped:
                state.shouldStartAllTimeScan = true
                return .none
        }
    }
}
