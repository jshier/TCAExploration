import ComposableArchitecture
import SwiftUI

@Reducer
public struct ItemListFeature: Sendable {
  @ObservableState
  public struct State: Equatable, Sendable {
    public var items: [Item]
    @Presents public var addItem: NewItemFeature.State?

    public init(items: [Item] = [], addItem: NewItemFeature.State? = nil) {
      self.items = items
      self.addItem = addItem
    }
  }

  public enum Action: Equatable, Sendable {
    case addButtonTapped
    case backButtonTapped
    case doneButtonTapped
    case addItem(PresentationAction<NewItemFeature.Action>)
  }

  @Dependency(\.dismiss) var dismiss

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        state.addItem = .init(focus: .title)

        return .none
      case let .addItem(.presented(.delegate(.addItem(item)))):
        state.items.append(item)

        return .none
      case .addItem:
        return .none
      case .backButtonTapped:
        return .none
      case .doneButtonTapped:
        return .run { _ in
          await dismiss()
        }
      }
    }
    .ifLet(\.$addItem, action: \.addItem) {
      NewItemFeature()
    }
  }
}

@MainActor
struct ItemList: View {
  struct ViewState: Equatable {
    var items: [Item]

    init(state: ItemListFeature.State) {
      items = state.items
    }
  }

  @Perception.Bindable var store: StoreOf<ItemListFeature>

  var body: some View {
    WithPerceptionTracking {
      contentView(for: store.items)
        .navigationTitle("Items")
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button("Done") {
              store.send(.doneButtonTapped)
            }
          }

          ToolbarItem(placement: .topBarTrailing) {
            Button("Add") {
              store.send(.addButtonTapped)
            }
          }
        }
        .sheet(item: $store.scope(state: \.addItem, action: \.addItem)) { store in
          NavigationStack {
            NewItemView(store: store)
              .navigationTitle("Add Item")
              .navigationBarTitleDisplayMode(.inline)
          }
        }
    }
  }

  @ViewBuilder
  func contentView(for items: [Item]) -> some View {
    if items.isEmpty {
      emptyView
    } else {
      List {
        ForEach(items) { item in
          Text(item.title)
        }
      }
    }
  }

  @ViewBuilder
  var emptyView: some View {
    VStack {
      Text("You have no items, tap Add to create one!")
      Button("Back") {
        store.send(.backButtonTapped)
      }
    }
  }
}

public struct Item: Sendable, Equatable, Identifiable {
  public var id: UUID
  public var title: String
  public var description: String

  public init(id: UUID, title: String, description: String) {
    self.id = id
    self.title = title
    self.description = description
  }
}

#Preview {
  NavigationStack {
    ItemList(store: Store(initialState: .init()) { ItemListFeature()._printChanges() })
  }
}
