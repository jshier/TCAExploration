@testable import NavigationFeature

import ComposableArchitecture
import XCTest

@MainActor
final class NavigationFeatureTests: XCTestCase {
  func testThatItemListButtonNavigatesToItemList() async throws {
    // Given
    let store = TestStore(initialState: .init()) {
      NavigationFeature()
    }

    // When
    await store.send(.itemListButtonTapped) {
      $0.path.append(.itemList(.init()))
    }
  }

  func testThatItemListDoneButtonDismissesItemList() async throws {
    // Given
    let store = TestStore(
      initialState: NavigationFeature.State(
        path: StackState([
          NavigationFeature.Path.State.itemList(.init())
        ])
      )
    ) {
      NavigationFeature()
    }

    // When
    // User taps Done button.
    await store.send(.path(.element(id: 0, action: .itemList(.doneButtonTapped))))
    // Dismiss implicitly calls .popFrom.
    await store.receive(.path(.popFrom(id: 0))) {
      $0.path[id: 0] = nil
    }
    // Root reducer calls .poppedToRoot.
    await store.receive(.poppedToRoot)
  }

  func testThatBackTapFromItemListPopsToRoot() async throws {
    // Given
    let store = TestStore(
      initialState: NavigationFeature.State(
        path: StackState([
          NavigationFeature.Path.State.itemList(.init())
        ])
      )
    ) {
      NavigationFeature()
    }

    // When
    // User taps back button and TCA calls popFrom.
    await store.send(.path(.popFrom(id: 0))) {
      $0.path[id: 0] = nil
    }
    // Root reducer calls .poppedToRoot.
    await store.receive(.poppedToRoot)
  }
}
