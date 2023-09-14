import ComposableArchitecture
import SwiftUI

public struct ItemListFeature: Reducer, Sendable {
  public struct State: Equatable, Sendable {
    var items: [Item]

    public init(items: [Item] = []) {
      self.items = items
    }
  }

  public enum Action: Equatable, Sendable {
    case addButtonTapped
    case doneButtonTapped
  }

  @Dependency(\.dismiss) var dismiss
  @Dependency(\.uuid) var uuid
  @Dependency(\.withRandomNumberGenerator) var randomly

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        state.items.append(Item(id: uuid(), title: "\( randomly { (1...100).randomElement(using: &$0)! })"))
        
        return .none
      case .doneButtonTapped:
        return .run { _ in
          await dismiss()
        }
      }
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
}

#Preview {
  NavigationStack {
    ItemList(store: Store(initialState: .init()) { ItemListFeature()._printChanges() })
  }
}
