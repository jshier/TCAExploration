@testable import NavigationFeature

import ComposableArchitecture
import XCTest

@MainActor
final class NewItemFeatureTests: XCTestCase {
  func testThatAddButtonTappedCallsDelegateAndDismisses() async throws {
    // Given
    let isDismissCalled = LockIsolated(false)
    // There is valid state.
    let store = TestStore(initialState: NewItemFeature.State(title: "title", description: "description")) {
      NewItemFeature()
    } withDependencies: {
      $0.uuid = .incrementing
      $0.dismiss = DismissEffect {
        isDismissCalled.setValue(true)
      }
    }

    // When
    await store.send(.addButtonTapped)

    // Then
    // Delegate is called with created item.
    await store.receive(.delegate(.addItem(Item(id: UUID(0), title: "title", description: "description"))))
    // Dismiss is called.
    XCTAssertTrue(isDismissCalled.value)
  }

  func testThatAddButtonTappedWithInvalidStateDoesNothing() async throws {
    // Given
    let isDismissCalled = LockIsolated(false)
    let store = TestStore(initialState: NewItemFeature.State()) {
      NewItemFeature()
    } withDependencies: {
      $0.dismiss = DismissEffect {
        isDismissCalled.setValue(true)
      }
    }

    // When
    await store.send(.addButtonTapped)

    // Then
    // Dismiss should not be called.
    XCTAssertFalse(isDismissCalled.value)
    // And test should pass because there are no unhandled effects in flight.
  }
}
