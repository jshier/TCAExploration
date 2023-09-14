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

  @Dependency(\.logger) var logger

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .itemListButtonTapped:
        state.path.append(.itemList(.init()))

        return .none
      case .path:
        return .none
      case .poppedToRoot:
        logger.log("poppedToRoot")

        return .none
      }
    }
    .forEach(\.path, action: /Action.path) {
      Path()
    }
    .onChange(of: \.path.isEmpty, removeDuplicates: ==) { _, isEmpty in
      isEmpty ? .poppedToRoot : nil
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

extension Reducer {
  func onChange<Value>(
    of toValue: @escaping (State) -> Value,
    removeDuplicates isDuplicate: @escaping (Value, Value) -> Bool,
    send: @escaping (_ oldValue: Value, _ newValue: Value) -> Action?
  ) -> some ReducerOf<Self> where Value: Equatable {
    onChange(of: toValue, removeDuplicates: isDuplicate) { oldValue, newValue in
      Reduce { _, _ in
        if let action = send(oldValue, newValue) {
          .send(action)
        } else {
          .none
        }
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
