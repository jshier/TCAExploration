import ComposableArchitecture
import SwiftUI

public struct NavigationFeature: Reducer {
    public struct State: Equatable {
        public var path = StackState<Path.State>()

        public init(path: StackState<NavigationFeature.Path.State> = StackState<Path.State>()) {
            self.path = path
        }
    }

    public enum Action: Equatable, Sendable {
        case itemListButtonTapped
        case path(StackAction<Path.State, Path.Action>)
        case poppedToRoot
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .itemListButtonTapped:
                state.path.append(.itemList(.init()))

                return .none
            case .path:
                return .none
            case .poppedToRoot:
                print(action)

                return .none
            }
        }
        .forEach(\.path, action: /Action.path) {
            Path()
        }
        .onChange(of: \.path) { _, newValue in
            Reduce { _, _ in
                newValue.isEmpty ? .run { send in await send(.poppedToRoot) } : .none
            }
        }
    }

    // Root navigation path.
    // Handles path state and reducer composition.
    public struct Path: Reducer {
        public enum State: Equatable, Sendable {
            case itemList(ItemListFeature.State)
        }

        public enum Action: Equatable, Sendable {
            case itemList(ItemListFeature.Action)
        }

        public var body: some ReducerOf<Self> {
            Scope(state: /State.itemList, action: /Action.itemList) {
                ItemListFeature()
            }
        }
    }
}

public struct NavigationView: View {
    public let store: StoreOf<NavigationFeature>

    public init(store: StoreOf<NavigationFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStackStore(store.scope(state: \.path, action: { .path($0) })) {
            VStack {
                Button("Item List") {
                    store.send(.itemListButtonTapped)
                }
            }
            .navigationTitle("Navigation Features")
        } destination: { state in
            switch state {
            case .itemList:
                CaseLet(/NavigationFeature.Path.State.itemList,
                        action: NavigationFeature.Path.Action.itemList,
                        then: ItemList.init)
                    .navigationTitle("Item List")
            }
        }
    }
}

#Preview {
    NavigationView(store: Store(initialState: .init()) { NavigationFeature()._printChanges() })
}
