//
//  RootView.swift
//  TCAExploration
//
//  Created by Jon Shier on 8/16/23.
//

import ComposableArchitecture
import NavigationFeature
import RemoteFeature
import SwiftUI

@Reducer
struct RootFeature: Reducer {
  @ObservableState
  struct State: Equatable {
    var currentTab: Tab
    var navigationFeature: NavigationFeature.State
    var remoteFeature: RemoteControlFeature.State

    init(
      currentTab: Tab = .navigation,
      navigationFeature: NavigationFeature.State = .init(),
      remoteFeature: RemoteControlFeature.State = .init()
    ) {
      @Dependency(\.defaults) var defaults
      self.currentTab = defaults.selectedRootTab ?? currentTab
      self.navigationFeature = navigationFeature
      self.remoteFeature = remoteFeature
    }
  }

  enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case goToNavigationTabButtonTapped
    case goToNewItemButtonTapped
    case navigationFeature(NavigationFeature.Action)
    case remoteFeature(RemoteControlFeature.Action)
    case saveCurrentTab(Tab)
  }

  enum Tab: String {
    case navigation, second, remote
  }

  @Dependency(\.defaults) var defaults
  @Dependency(\.logger) var logger

  var body: some ReducerOf<Self> {
    BindingReducer()

    Scope(state: \.navigationFeature, action: \.navigationFeature) {
      NavigationFeature()
    }

    Scope(state: \.remoteFeature, action: \.remoteFeature) {
      RemoteControlFeature()
    }

    Reduce { state, action in
      switch action {
      case .navigationFeature:
        return .none
      case .remoteFeature:
        return .none
      case .binding:
        return .none
      case .goToNavigationTabButtonTapped:
        state.currentTab = .navigation

        return .none
      case .goToNewItemButtonTapped:
        state.currentTab = .navigation

        if let id = state.navigationFeature.path.ids.first,
           var itemsListState = state.navigationFeature.path[id: id, case: \.itemList] {
          itemsListState.addItem = .init(focus: .description)
          state.navigationFeature.path[id: id, case: \.itemList] = itemsListState
        } else {
          state.navigationFeature = NavigationFeature.State(path: StackState([
            NavigationFeature.Path.State.itemList(
              .init(addItem: .init(focus: .description))
            )
          ]))
        }

        return .none
      case let .saveCurrentTab(tab):
        defaults.selectedRootTab = tab

        return .none
      }
    }
    .onChange(of: \.currentTab) { _, newValue in
      .saveCurrentTab(newValue)
    }
  }
}

struct RootView: View {
  @Perception.Bindable var store: StoreOf<RootFeature>

  var body: some View {
    WithPerceptionTracking {
      TabView(selection: $store.currentTab) {
        NavigationView(store: store.scope(state: \.navigationFeature, action: \.navigationFeature))
          .tabItem {
            Label(title: { Text("Navigation") },
                  icon: { Image(systemName: "square.on.square.intersection.dashed") })
          }
          .tag(RootFeature.Tab.navigation)

        VStack {
          Text("Second Tab")
          Button("Go To Navigation Tab") {
            store.send(.goToNavigationTabButtonTapped)
          }
          Button("Got To New Item") {
            store.send(.goToNewItemButtonTapped)
          }
        }
        .tabItem { Text("Second") }
        .tag(RootFeature.Tab.second)

        RemoteScreen(store: store.scope(state: \.remoteFeature, action: \.remoteFeature))
          .tabItem {
            Label(
              title: { Text("Remote") },
              icon: { Image(systemName: "av.remote") }
            )
          }
          .tag(RootFeature.Tab.remote)
      }
    }
  }
}

#Preview {
  RootView(store: Store(initialState: .init()) { RootFeature()._printChanges() })
}
