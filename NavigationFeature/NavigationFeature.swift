import ComposableArchitecture
import SwiftUI

public struct NavigationFeature: Reducer {
    public struct State: Equatable {
        public var path = StackState<Path.State>()
        
        public init(path: StackState<NavigationFeature.Path.State> = StackState<Path.State>()) {
            self.path = path
        }
    }
    
    public enum Action: Equatable {
        case itemListButtonTapped
        case path(StackAction<Path.State, Path.Action>)
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
            }
        }
        .forEach(\.path, action: /Action.path) {
            Path()
        }
    }
    
    // Root navigation path.
    // Handles path state and reducer composition.
    public struct Path: Reducer {
        public enum State: Equatable {
            case itemList(ItemListFeature.State)
        }
        
        public enum Action: Equatable {
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
            }
        }
    }
}

#Preview {
    NavigationView(store: Store(initialState: .init()) { NavigationFeature()._printChanges() })
}
