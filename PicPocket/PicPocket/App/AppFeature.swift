import ComposableArchitecture
import Foundation

struct AppFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var hasCompletedOnboarding = false
        var selectedTab: Tab = .library
        var onboarding = OnboardingFeature.State()
        var library = LibraryFeature.State()
        var scan = ScanFeature.State()
        var search = SearchFeature.State()
        var settings = SettingsFeature.State()
    }

    enum Tab: String, CaseIterable, Equatable {
        case library
        case scan
        case search
        case settings
    }

    @CasePathable
    enum Action: Equatable {
        case appStarted
        case tabSelected(Tab)
        case onboarding(OnboardingFeature.Action)
        case library(LibraryFeature.Action)
        case scan(ScanFeature.Action)
        case search(SearchFeature.Action)
        case settings(SettingsFeature.Action)
    }

    @Dependency(\.userDefaultsClient) var userDefaultsClient

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .appStarted:
            state.hasCompletedOnboarding = userDefaultsClient.bool("hasCompletedOnboarding")
            return state.hasCompletedOnboarding ? .send(.library(.load)) : .none

        case let .tabSelected(tab):
            state.selectedTab = tab
            switch tab {
            case .library:
                return .send(.library(.load))
            case .settings:
                return .send(.settings(.load))
            case .scan, .search:
                return .none
            }

        case .onboarding(.delegate(.completed)):
            state.hasCompletedOnboarding = true
            userDefaultsClient.setBool(true, "hasCompletedOnboarding")
            return .send(.library(.load))

        case let .onboarding(action):
            return OnboardingFeature()
                .reduce(into: &state.onboarding, action: action)
                .map(Action.onboarding)

        case let .library(action):
            return LibraryFeature()
                .reduce(into: &state.library, action: action)
                .map(Action.library)

        case let .scan(action):
            let effect = ScanFeature()
                .reduce(into: &state.scan, action: action)
                .map(Action.scan)
            if case .scanCompleted = action {
                return .merge(effect, .send(.library(.load)))
            }
            return effect

        case let .search(action):
            return SearchFeature()
                .reduce(into: &state.search, action: action)
                .map(Action.search)

        case let .settings(action):
            return SettingsFeature()
                .reduce(into: &state.settings, action: action)
                .map(Action.settings)
        }
    }
}

struct UserDefaultsClient: Sendable {
    var bool: @Sendable (_ key: String) -> Bool
    var setBool: @Sendable (_ value: Bool, _ key: String) -> Void
}

extension UserDefaultsClient: DependencyKey {
    static let liveValue = UserDefaultsClient(
        bool: { UserDefaults.standard.bool(forKey: $0) },
        setBool: { value, key in UserDefaults.standard.set(value, forKey: key) }
    )
    static let testValue = UserDefaultsClient(bool: { _ in false }, setBool: { _, _ in })
}

extension DependencyValues {
    var userDefaultsClient: UserDefaultsClient {
        get { self[UserDefaultsClient.self] }
        set { self[UserDefaultsClient.self] = newValue }
    }
}
