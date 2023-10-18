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

    await store.send(.toggleListeningButtonTapped) {
      $0.isListening = true
    }

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

    await clock.advance(by: .seconds(1))

    await store.receive(.receiveCommandStatus(.inFlight)) {
      $0.commandSummary = "Command in flight"
    }
    await store.receive(.receiveHVACSettings(.init(temperature: 72, isDefrostOn: false)))

    await store.receive(.receiveVehicleStatus(.init(doors: .open, windows: .closed, odometer: 1234)))
    await store.receive(.receiveElectricStatus(.init(plugin: .unplugged)))

    await clock.advance(by: .seconds(1))

    await store.receive(.receiveCommandStatus(.none)) {
      $0.commandSummary = "Command idle"
    }
    await store.receive(.receiveHVACSettings(.init(temperature: 72, isDefrostOn: false)))

    await store.receive(.receiveVehicleStatus(.init(doors: .open, windows: .closed, odometer: 1234)))
    await store.receive(.receiveElectricStatus(.init(plugin: .unplugged)))

    await store.send(.toggleListeningButtonTapped) {
      $0.isListening = false
    }

    await store.finish()
  }
}
