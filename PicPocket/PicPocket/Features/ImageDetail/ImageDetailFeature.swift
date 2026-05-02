import ComposableArchitecture
import Foundation

struct ImageDetailFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var image: CapturedImage
        var isSavingCategory = false
        var errorMessage: String?

        init(image: CapturedImage) {
            self.image = image
        }
    }

    enum Action: Equatable {
        case categoryChanged(CaptureCategory)
        case categorySaved(Result<CaptureCategory, EquatableError>)
    }

    @Dependency(\.capturedImageRepository) var repository

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .categoryChanged(category):
            state.image.category = category
            state.image.isSensitive = category.isSensitive
            state.image.reviewStatus = .changedByUser
            state.isSavingCategory = true
            let id = state.image.assetLocalIdentifier
            return .run { send in
                do {
                    try await repository.updateCategory(id, category)
                    await send(.categorySaved(.success(category)))
                } catch {
                    await send(.categorySaved(.failure(EquatableError(error.localizedDescription))))
                }
            }

        case .categorySaved(.success):
            state.isSavingCategory = false
            return .none

        case let .categorySaved(.failure(error)):
            state.isSavingCategory = false
            state.errorMessage = error.message
            return .none
        }
    }
}
