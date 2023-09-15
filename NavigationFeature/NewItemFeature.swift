import ComposableArchitecture
import SwiftUI

public struct NewItemFeature: Reducer {
  public struct State: Equatable, Sendable {
    @BindingState var title: String
    @BindingState var focus: Field?

    var isValid: Bool { !title.isEmpty }
    var newItem: Item? {
      if isValid {
        @Dependency(\.uuid) var uuid

        return Item(id: uuid(), title: title)
      } else {
        return nil
      }
    }

    public init(title: String = "", focus: Field? = nil) {
      self.title = title
      self.focus = focus
    }
  }

  public enum Action: Equatable, BindableAction, Sendable {
    public enum Delegate: Equatable, Sendable {
      case addItem(Item)
    }

    case addButtonTapped
    case binding(BindingAction<State>)
    case bodyTapped
    case delegate(Delegate)
  }

  public enum Field: Equatable, Sendable {
    case title
  }

  public var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        guard let item = state.newItem else { return .none }

        return .send(.delegate(.addItem(item)))
      case .binding:
        return .none
      case .bodyTapped:
        state.focus = nil

        return .none
      case .delegate:
        return .none
      }
    }
  }
}

struct NewItemView: View {
  let store: StoreOf<NewItemFeature>

  @FocusState private var focus: NewItemFeature.Field?

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        Form {
          TextField("Title", text: viewStore.$title)
            .focused($focus, equals: .title)
        }

        Button("Add") {
          viewStore.send(.addButtonTapped)
        }
        .disabled(!viewStore.isValid)
      }
      .gesture(TapGesture().onEnded {
        viewStore.send(.bodyTapped)
      })
      .bind(viewStore.$focus, to: $focus)
    }
  }
}

#Preview {
  NewItemView(store: Store(initialState: .init(focus: .title)) {
    NewItemFeature()._printChanges()
  })
}
