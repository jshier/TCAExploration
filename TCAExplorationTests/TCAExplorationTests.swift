//
//  TCAExplorationTests.swift
//  TCAExplorationTests
//
//  Created by Jon Shier on 8/16/23.
//

@testable import TCAExploration

import ComposableArchitecture
import NavigationFeature
import XCTest

@MainActor
final class TCAExplorationTests: XCTestCase {
  func testSecondTabGoToNewItemButton() async throws {
    // Given
    let store = TestStore(initialState: .init(currentTab: .second)) {
      RootFeature()
    } withDependencies: { dependencies in
      dependencies.defaults = .inMemory(selectedTab: .second)
    }

    // When: user taps the Go To New Item button.
    await store.send(.goToNewItemButtonTapped) { state in
      // Navigates to the Navigation tab.
      state.currentTab = .navigation
      // Sets the navigation state to the addItem screen with .title focused.
      state.navigationFeature = NavigationFeature.State(path: StackState([
        NavigationFeature.Path.State.itemList(
          .init(addItem: .init(focus: .title))
        )
      ]))
    }
    // Then: store saves the current tab to Defaults.
    await store.receive(.saveCurrentTab(.navigation))
  }
}

extension Defaults {
  static func inMemory(selectedTab: RootFeature.Tab? = .navigation) -> Defaults {
    var defaults = Defaults()
    let selectedTab: LockIsolated<RootFeature.Tab?> = LockIsolated(selectedTab)
    defaults.$selectedRootTab.getter = { selectedTab.value }
    defaults.$selectedRootTab.setter = { newValue in selectedTab.withValue { $0 = newValue } }

    return defaults
  }
}
