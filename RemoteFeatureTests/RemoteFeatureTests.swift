@testable import RemoteFeature

import ComposableArchitecture
import XCTest

@MainActor
final class RemoteFeatureTests: XCTestCase {
  func testThatListenToggleStartsEffects() async throws {
    // Given
    let clock = TestClock()
    let store = TestStore(initialState: RemoteFeature.State(currentTemperature: "Loading...",
                                                            currentMileage: "Loading...",
                                                            commandSummary: "Loading...",
                                                            chargingSummary: "Loading...")) {
      RemoteFeature()
    } withDependencies: { dependencies in
      dependencies.remoteNetworking = RemoteNetworking {
        AsyncStream(events: .value(.none), .delay(.seconds(1)), .value(.inFlight), .delay(.seconds(1)))
      } vehicleStatus: {
        AsyncStream(events: .value(.init(doors: .open, windows: .closed, odometer: 1234)), .delay(.seconds(1)))
      } electricStatus: {
        AsyncStream(events: .value(.init(plugin: .unplugged)), .delay(.seconds(1)))
      } hvacSettings: {
        AsyncStream(events: .value(.init(temperature: 72, isDefrostOn: false)), .delay(.seconds(1)))
      }
      dependencies.continuousClock = clock
    }
    store.useMainSerialExecutor = true

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

    // Then: store has finished processing all effects.
    await store.finish()
  }
}
