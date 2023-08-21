import ComposableArchitecture
import SwiftUI

public struct ItemListFeature: Reducer, Sendable {
    public struct State: Equatable, Sendable {}

    public enum Action: Equatable, Sendable {
        case doneButtonTapped
    }

    @Dependency(\.dismiss) var dismiss

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .doneButtonTapped:
                .run { _ in
                    await dismiss()
                }
            }
        }
    }
}

struct ItemList: View {
    let store: StoreOf<ItemListFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                Text("Item List")
                Button("Done") {
                    viewStore.send(.doneButtonTapped)
                }
            }
        }
    }
}
