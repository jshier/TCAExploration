import ComposableArchitecture
import SwiftUI

public struct ItemListFeature: Reducer, Sendable {
  public struct State: Equatable, Sendable {
    var items: [Item]
    @PresentationState var addItem: NewItemFeature.State?

    public init(items: [Item] = [], addItem: NewItemFeature.State? = nil) {
      self.items = items
      self.addItem = addItem
    }
  }

  public enum Action: Equatable, Sendable {
    case addButtonTapped
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
        state.addItem = nil

        return .none
      case .addItem:
        return .none
      case .doneButtonTapped:
        return .run { _ in
          await dismiss()
        }
      }
    }
    .ifLet(\.$addItem, action: /Action.addItem) {
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

  let store: StoreOf<ItemListFeature>

  var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      contentView(for: viewStore.items)
        .navigationTitle("Items")
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button("Done") {
              viewStore.send(.doneButtonTapped)
            }
          }

          ToolbarItem(placement: .topBarTrailing) {
            Button("Add") {
              viewStore.send(.addButtonTapped)
            }
          }
        }
        .sheet(store: store.scope(state: \.$addItem, action: { .addItem($0) })) { store in
          NewItemView(store: store)
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
    Text("You have no items, tap Add to create one!")
  }
}

public struct Item: Sendable, Equatable, Identifiable {
  public var id: UUID
  public var title: String

  public init(id: UUID, title: String) {
    self.id = id
    self.title = title
  }
}

#Preview {
  NavigationStack {
    ItemList(store: Store(initialState: .init()) { ItemListFeature()._printChanges() })
  }
}
