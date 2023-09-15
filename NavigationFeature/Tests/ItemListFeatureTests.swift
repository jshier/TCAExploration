@testable import NavigationFeature

import ComposableArchitecture
import XCTest

@MainActor
final class ItemListFeatureTests: XCTestCase {
  func testThatDoneButtonDismissesFeature() async throws {
    // Given
    let isDismissCalled = LockIsolated(false)
    let store = TestStore(initialState: .init()) {
      ItemListFeature()
    } withDependencies: { dependencies in
      dependencies.dismiss = DismissEffect {
        isDismissCalled.setValue(true)
      }
    }

    // When
    await store.send(.doneButtonTapped)

    // Then
    XCTAssertTrue(isDismissCalled.value)
  }

  func testThatAddButtonPresentsAddSheet() async throws {
    // Given
    let store = TestStore(initialState: .init()) {
      ItemListFeature()
    } withDependencies: { dependencies in
      dependencies.uuid = .incrementing
    }

    // When, Then
    // When user taps Add button, addItem is populated, focus is .title.
    await store.send(.addButtonTapped) { state in
      state.addItem = .init(focus: .title)
    }
  }
}

/// A linear congruential random number generator.
struct LCRNG: RandomNumberGenerator {
  var seed: UInt64

  init(seed: UInt64 = 0) {
    self.seed = seed
  }

  mutating func next() -> UInt64 {
    seed = 2_862_933_555_777_941_757 &* seed &+ 3_037_000_493
    return seed
  }
}
