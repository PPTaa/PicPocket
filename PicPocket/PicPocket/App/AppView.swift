import ComposableArchitecture
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppFeature>
    @State private var detailImage: CapturedImage?

    var body: some View {
        Group {
            if store.hasCompletedOnboarding {
                ZStack(alignment: .bottom) {
                    switch store.selectedTab {
                    case .library:
                        LibraryView(
                            store: store.scope(state: \.library, action: \.library),
                            onOpenDetail: { detailImage = $0 }
                        )
                    case .scan:
                        ScanView(store: store.scope(state: \.scan, action: \.scan))
                    case .search:
                        SearchView(
                            store: store.scope(state: \.search, action: \.search),
                            onOpenDetail: { detailImage = $0 }
                        )
                    case .settings:
                        SettingsView(store: store.scope(state: \.settings, action: \.settings))
                    }

                    MockupTabBar(selectedTab: store.selectedTab) { tab in
                        store.send(.tabSelected(tab))
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            } else {
                OnboardingView(store: store.scope(state: \.onboarding, action: \.onboarding))
            }
        }
        .task {
            await store.send(.appStarted).finish()
        }
        .fullScreenCover(item: $detailImage) { image in
            ImageDetailView(
                store: Store(initialState: ImageDetailFeature.State(image: image)) {
                    ImageDetailFeature()
                }
            )
        }
    }
}

private struct MockupTabBar: View {
    let selectedTab: AppFeature.Tab
    let onSelect: (AppFeature.Tab) -> Void

    var body: some View {
        HStack(spacing: 8) {
            tab(.library, "보관함", "square.grid.2x2")
            tab(.scan, "스캔", "viewfinder")
            tab(.search, "검색", "magnifyingglass")
            tab(.settings, "설정", "gearshape")
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(MockupStyle.border.opacity(0.8), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.10), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private func tab(_ tab: AppFeature.Tab, _ title: String, _ icon: String) -> some View {
        Button {
            onSelect(tab)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                Text(title)
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(selectedTab == tab ? MockupStyle.accent : MockupStyle.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if selectedTab == tab {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(MockupStyle.accentSoft.opacity(0.85))
                }
            }
        }
        .buttonStyle(.plain)
    }
}
