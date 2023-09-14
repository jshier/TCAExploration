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
  
  func testThatAddButtonAddsItem() async throws {
    // Given
    let store = TestStore(initialState: .init()) {
      ItemListFeature()
    } withDependencies: { dependencies in
      dependencies.uuid = .incrementing
      dependencies.withRandomNumberGenerator = WithRandomNumberGenerator(LCRNG(seed: 0))
    }
    
    // When, Then
    await store.send(.addButtonTapped) { state in
      state.items.append(.init(id: UUID(0), title: "1"))
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
    self.seed = 2_862_933_555_777_941_757 &* self.seed &+ 3_037_000_493
    return self.seed
  }
}
