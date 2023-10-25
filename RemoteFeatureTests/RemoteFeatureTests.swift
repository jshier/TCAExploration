@testable import RemoteFeature

import ComposableArchitecture
import XCTest

@MainActor
final class RemoteFeatureTests: XCTestCase {
  func testThatListenToggleStartsEffects() async throws {
    // Given
    let clock = TestClock()
    let store = TestStore(initialState: RemoteFeature.State()) {
      RemoteFeature()
    } withDependencies: { dependencies in
      dependencies.remoteNetworking = .infiniteSequence
      dependencies.continuousClock = clock
    }

    // When: the user taps the toggle button.
    await store.send(.toggleListeningButtonTapped) {
      $0.isListening = true
      // As a computed property we must assert manually.
      XCTAssertEqual($0.toggleListeningButtonTitle, "Stop Listening")
    }

    // Then: Initial values are received.
    await store.receive(.receiveCommandStatus(.none)) {
      $0.commandSummary = "Command idle"
    }
    await store.receive(.receiveHVACSettings(.init(temperature: 72, isDefrostOn: false))) { state in
      state.currentTemperature = "72°F"
    }
    await store.receive(.receiveVehicleStatus(.init(doors: .open, windows: .closed, odometer: 1234))) {
      $0.currentMileage = "1234 mi"
    }
    await store.receive(.receiveElectricStatus(.init(plugin: .unplugged))) {
      $0.chargingSummary = "Not charging!"
    }

    // Then: a second elapses
    await clock.advance(by: .seconds(1))

    await store.receive(.receiveCommandStatus(.inFlight)) {
      $0.commandSummary = "Command in flight"
    }
    await store.receive(.receiveHVACSettings(.init(temperature: 72, isDefrostOn: false)))
    await store.receive(.receiveVehicleStatus(.init(doors: .open, windows: .closed, odometer: 1234)))
    await store.receive(.receiveElectricStatus(.init(plugin: .unplugged)))

    // Then: a second elapses.
    await clock.advance(by: .seconds(1))

    // Then: additional values are received.
    await store.receive(.receiveCommandStatus(.none)) {
      $0.commandSummary = "Command idle"
    }
    await store.receive(.receiveHVACSettings(.init(temperature: 72, isDefrostOn: false)))
    await store.receive(.receiveVehicleStatus(.init(doors: .open, windows: .closed, odometer: 1234)))
    await store.receive(.receiveElectricStatus(.init(plugin: .unplugged)))

    // Then: the user taps the toggle button again.
    await store.send(.toggleListeningButtonTapped) {
      $0.isListening = false
      // As a computed property we must assert manually.
      XCTAssertEqual($0.toggleListeningButtonTitle, "Start Listening")
    }
  }

  func testThatListeningIsFalseAfterOnDisappear() async throws {
    // Given
    let store = TestStore(initialState: RemoteFeature.State(isListening: true)) {
      RemoteFeature()
    }

    // When: onDisappear called, no state change should happen because isListening defaults to false.
    await store.send(.onDisappear) {
      $0.isListening = false
    }
  }
}
