import ComposableArchitecture
import Foundation

struct SearchFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var query = ""
        var results: [CapturedImage] = []
        var isSearching = false
        var errorMessage: String?
    }

    enum Action: Equatable {
        case queryChanged(String)
        case searchButtonTapped
        case searchResponse(Result<[CapturedImage], EquatableError>)
    }

    @Dependency(\.capturedImageRepository) var repository

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
            case let .queryChanged(query):
                state.query = query
                return .none

            case .searchButtonTapped:
                state.isSearching = true
                state.errorMessage = nil
                let query = state.query
                return .run { send in
                    do {
                        await send(.searchResponse(.success(try await repository.search(query))))
                    } catch {
                        await send(.searchResponse(.failure(EquatableError(error.localizedDescription))))
                    }
                }

            case let .searchResponse(.success(results)):
                state.isSearching = false
                state.results = results
                return .none

            case let .searchResponse(.failure(error)):
                state.isSearching = false
                state.errorMessage = error.message
                return .none
        }
    }
}
