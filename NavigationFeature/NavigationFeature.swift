import ComposableArchitecture
import SwiftUI

@Reducer
public struct NavigationFeature: Reducer {
  @ObservableState
  public struct State: Equatable {
    public var path = StackState<Path.State>()

    public init(path: StackState<NavigationFeature.Path.State> = StackState<Path.State>()) {
      self.path = path
    }
  }

  public enum Action: Equatable {
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
      case .path(.element(_, action: .itemList(.backButtonTapped))):
        _ = state.path.popLast()

        return .none
      case .path:
        print(action)
        return .none
      case .poppedToRoot:
        logger.log("poppedToRoot")

        return .none
      }
    }
    .forEach(\.path, action: \.path)
    .onChange(of: \.path.isEmpty) { _, isEmpty in
      isEmpty ? .poppedToRoot : nil
    }
  }

  @Reducer(state: .equatable, action: .equatable)
  public enum Path {
    case itemList(ItemListFeature)
  }
}

public extension Reducer {
  func onChange<Value: Equatable>(
    of toValue: @escaping (State) -> Value,
    send: @escaping (_ oldValue: Value, _ newValue: Value) -> Action?
  ) -> some ReducerOf<Self> where Value: Equatable {
    onChange(of: toValue) { oldValue, newValue in
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
  @Perception.Bindable
  public private(set) var store: StoreOf<NavigationFeature>

  public init(store: StoreOf<NavigationFeature>) {
    self.store = store
  }

  public var body: some View {
    WithPerceptionTracking {
      NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
        VStack {
          Button("Item List") {
            store.send(.itemListButtonTapped)
          }
        }
        .navigationTitle("Navigation Features")
      } destination: { store in
        WithPerceptionTracking {
          switch store.case {
          case let .itemList(store):
            ItemList(store: store)
          }
        }
      }
    }
  }
}

#Preview {
  NavigationView(store: Store(initialState: .init()) { NavigationFeature()._printChanges() })
}
