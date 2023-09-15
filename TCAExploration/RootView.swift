//
//  RootView.swift
//  TCAExploration
//
//  Created by Jon Shier on 8/16/23.
//

import ComposableArchitecture
import NavigationFeature
import SwiftUI

struct RootFeature: Reducer {
  struct State: Equatable {
    @BindingState var currentTab: Tab
    var navigationFeature: NavigationFeature.State

    init(currentTab: Tab = .navigation, navigationFeature: NavigationFeature.State = .init()) {
      @Dependency(\.defaults) var defaults
      self.currentTab = defaults.selectedRootTab ?? currentTab
      self.navigationFeature = navigationFeature
    }
  }

  enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case goToNavigationTabButtonTapped
    case goToNewItemButtonTapped
    case navigationFeature(NavigationFeature.Action)
    case saveCurrentTab(Tab)
  }

  enum Tab: String {
    case navigation, second, third
  }

  @Dependency(\.defaults) var defaults

  var body: some ReducerOf<Self> {
    BindingReducer()

    Scope(state: \.navigationFeature, action: /RootFeature.Action.navigationFeature) {
      NavigationFeature()
    }

    Reduce { state, action in
      switch action {
      case .navigationFeature:
        return .none
      case .binding:
        return .none
      case .goToNavigationTabButtonTapped:
        state.currentTab = .navigation

        return .none
      case .goToNewItemButtonTapped:
        state.currentTab = .navigation
        state.navigationFeature = NavigationFeature.State(path: StackState([
          NavigationFeature.Path.State.itemList(
            .init(addItem: .init(focus: .title))
          )
        ]))

        return .none
      case let .saveCurrentTab(tab):
        defaults.selectedRootTab = tab

        return .none
      }
    }
    .onChange(of: \.currentTab, removeDuplicates: ==) { _, newValue in
      .saveCurrentTab(newValue)
    }
  }
}

struct RootView: View {
  struct ViewState: Equatable {
    @BindingViewState var currentTab: RootFeature.Tab

    init(_ store: BindingViewStore<RootFeature.State>) {
      _currentTab = store.$currentTab
    }
  }

  let store: StoreOf<RootFeature>

  var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      TabView(selection: viewStore.$currentTab) {
        NavigationView(store: store.scope(state: \.navigationFeature, action: RootFeature.Action.navigationFeature))
          .tabItem { Label(
            title: { Text("Navigation") },
            icon: { Image(systemName: "square.on.square.intersection.dashed") }
          ) }
          .tag(RootFeature.Tab.navigation)

        VStack {
          Text("Second Tab")
          Button("Go To Navigation Tab") {
            viewStore.send(.goToNavigationTabButtonTapped)
          }
          Button("Got To New Item") {
            viewStore.send(.goToNewItemButtonTapped)
          }
        }
        .tabItem { Text("Second") }
        .tag(RootFeature.Tab.second)

        Text("Third Tab")
          .tabItem { Text("Third") }
          .tag(RootFeature.Tab.third)
      }
    }
  }
}

#Preview {
  RootView(store: Store(initialState: .init()) { RootFeature()._printChanges() })
}
