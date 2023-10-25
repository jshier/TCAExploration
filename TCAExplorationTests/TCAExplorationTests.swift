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
    let defaults = Defaults.inMemory(selectedTab: .second)
    let store = TestStore(initialState: .init(currentTab: .second)) {
      RootFeature()
    } withDependencies: { dependencies in
      dependencies.defaults = defaults
    }

    // When: user taps the Go To New Item button.
    await store.send(.goToNewItemButtonTapped) { state in
      // Navigates to the Navigation tab.
      state.currentTab = .navigation
      // Sets the navigation state to the addItem screen with .description focused.
      state.navigationFeature = NavigationFeature.State(path: StackState([
        NavigationFeature.Path.State.itemList(
          .init(addItem: .init(focus: .description))
        )
      ]))
    }
    // Then: store saves the current tab to Defaults.
    await store.receive(.saveCurrentTab(.navigation))

    XCTAssertEqual(defaults.selectedRootTab, .navigation)
  }

  func testGoToNewItemButtonPreservesExistingList() async throws {
    // Given
    let defaults = Defaults.inMemory(selectedTab: .second)
    let store = TestStore(initialState:
      .init(currentTab: .second, navigationFeature: NavigationFeature.State(path: StackState([
        NavigationFeature.Path.State.itemList(
          .init(items: [.init(id: UUID(0), title: "", description: "")])
        )
      ])))
    ) {
      RootFeature()
    } withDependencies: { dependencies in
      dependencies.defaults = defaults
    }

    // When: user taps the Go To New Item button.
    await store.send(.goToNewItemButtonTapped) { state in
      // Navigates to the Navigation tab.
      state.currentTab = .navigation
      // Sets the navigation state to the addItem screen with .description focused while keeping existing list intact.
      state.navigationFeature.path[id: 0, case: /NavigationFeature.Path.State.itemList]?.addItem = .init(focus: .description)
    }
    // Then: store saves the current tab to Defaults.
    await store.receive(.saveCurrentTab(.navigation))

    XCTAssertEqual(defaults.selectedRootTab, .navigation)
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
