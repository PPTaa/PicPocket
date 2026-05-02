import ComposableArchitecture
import Foundation

struct LibraryFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var categoryCounts: [CaptureCategory: Int] = [:]
        var recentImages: [CaptureCategory: [CapturedImage]] = [:]
        var isLoading = false
        var errorMessage: String?
    }

    enum Action: Equatable {
        case load
        case loadResponse(Result<[CapturedImage], EquatableError>)
    }

    @Dependency(\.capturedImageRepository) var repository

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .load:
            state.isLoading = true
            state.errorMessage = nil
            return .run { send in
                do {
                    await send(.loadResponse(.success(try await repository.all())))
                } catch {
                    await send(.loadResponse(.failure(EquatableError(error.localizedDescription))))
                }
            }

        case let .loadResponse(.success(images)):
            state.isLoading = false
            state.categoryCounts = Dictionary(grouping: images, by: \.category)
                .mapValues(\.count)
            state.recentImages = Dictionary(grouping: images, by: \.category)
                .mapValues { Array($0.prefix(3)) }
            return .none

        case let .loadResponse(.failure(error)):
            state.isLoading = false
            state.errorMessage = error.message
            return .none
        }
    }
}

struct EquatableError: Error, Equatable {
    var message: String

    init(_ message: String) {
        self.message = message
    }
}
