import ComposableArchitecture
import Photos

struct OnboardingFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var authorizationStatus: PHAuthorizationStatus = .notDetermined
        var isRequestingPermission = false
    }

    enum Action: Equatable {
        case photoAccessButtonTapped
        case photoAuthorizationResponse(PHAuthorizationStatus)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case completed
        }
    }

    @Dependency(\.photoLibraryClient) var photoLibraryClient

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .photoAccessButtonTapped:
            state.isRequestingPermission = true
            return .run { send in
                await send(.photoAuthorizationResponse(await photoLibraryClient.requestAuthorization()))
            }

        case let .photoAuthorizationResponse(status):
            state.isRequestingPermission = false
            state.authorizationStatus = status
            if status == .authorized || status == .limited {
                return .send(.delegate(.completed))
            }
            return .none

        case .delegate:
            return .none
        }
    }
}
