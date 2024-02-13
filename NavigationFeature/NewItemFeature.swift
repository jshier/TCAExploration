import ComposableArchitecture
import SwiftUI

@Reducer
public struct NewItemFeature {
  @ObservableState
  public struct State: Equatable, Sendable {
    var title: String
    var description: String
    var focus: Field?

    var isValid: Bool { !title.isEmpty && !description.isEmpty }
    var newItem: Item? {
      if isValid {
        @Dependency(\.uuid) var uuid

        return Item(id: uuid(), title: title, description: description)
      } else {
        return nil
      }
    }

    public init(title: String = "", description: String = "", focus: Field? = nil) {
      self.title = title
      self.description = description
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
    case title, description
  }

  @Dependency(\.dismiss) var dismiss

  public var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        guard let item = state.newItem else { return .none }

        return .run { [dismiss] send in
          await send(.delegate(.addItem(item)))
          await dismiss()
        }
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
  @Perception.Bindable var store: StoreOf<NewItemFeature>

  @FocusState private var focus: NewItemFeature.Field?

  var body: some View {
    WithPerceptionTracking {
      VStack {
        TextField("Title", text: $store.title)
          .focused($focus, equals: .title)
        TextField("Description", text: $store.description)
          .focused($focus, equals: .description)

        Button("Add") {
          store.send(.addButtonTapped)
        }
        .disabled(!store.isValid)

        Spacer()
      }
      .padding()
      .bind($store.focus, to: $focus)
    }
  }
}

#Preview {
  NewItemView(store: Store(initialState: .init(focus: .title)) {
    NewItemFeature()._printChanges()
  })
}
