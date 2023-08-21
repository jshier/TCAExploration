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
}
