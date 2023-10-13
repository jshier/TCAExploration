import ComposableArchitecture
import SwiftUI

public struct RemoteFeature: Reducer {
  public struct State: Equatable, Sendable {
    var currentTemperature: String
    var currentMileage: String
    var isCommandInProgress: Bool
    var isCharging: Bool
    var isListening: Bool

    public init(currentTemperature: String, currentMileage: String, isCommandInProgress: Bool, isCharging: Bool) {
      self.currentTemperature = currentTemperature
      self.currentMileage = currentMileage
      self.isCommandInProgress = isCommandInProgress
      self.isCharging = isCharging
      isListening = false
    }
  }

  public enum Action: Equatable, Sendable {
    case onAppear
    case onDisappear
    case receiveVehicleStatus(VehicleStatus)
    case receiveElectricStatus(ElectricalVehicleStatus)
    case receiveHVACSettings(HVACSettings)
    case receiveCommandStatus(CommandStatus)
    case toggleListeningButtonTapped
  }

  private enum CancellableAction {
    case statusListeners
  }

  @Dependency(\.remoteNetworking) var remoteNetworking

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        // Or start listenerEffect.
        return .none
      case .onDisappear:
        return .cancel(id: CancellableAction.statusListeners)
      case let .receiveVehicleStatus(status):
        state.currentMileage = "\(status.odometer) mi"

        return .none
      case let .receiveElectricStatus(status):
        state.isCharging = status.plugin == .pluggedIn(isCharging: true)

        return .none
      case let .receiveHVACSettings(settings):
        state.currentTemperature = "\(settings.temperature)°F"

        return .none
      case let .receiveCommandStatus(status):
        state.isCommandInProgress = status == .inFlight

        return .none
      case .toggleListeningButtonTapped:
        defer { state.isListening.toggle() }

        if state.isListening {
          return .cancel(id: CancellableAction.statusListeners)
        } else {
          return listenerEffect
        }
      }
    }
  }

  private var listenerEffect: Effect<Action> {
    .merge(
      .run { [vehicleStatus = remoteNetworking.vehicleStatus] send in
        for await value in vehicleStatus() {
          await send(.receiveVehicleStatus(value))
        }
//        print("stopped waiting for vehicle status")
      },
      .run { [electricStatus = remoteNetworking.electricStatus] send in
        for await value in electricStatus() {
          await send(.receiveElectricStatus(value))
        }
//        print("stopped waiting for electric status")
      },
      .run { [hvacSettings = remoteNetworking.hvacSettings] send in
        for await value in hvacSettings() {
          await send(.receiveHVACSettings(value))
        }
//        print("stopped waiting for HVAC settings")
      },
      .run { [commandStatus = remoteNetworking.commandStatus] send in
        for await value in commandStatus() {
          await send(.receiveCommandStatus(value))
        }
//        print("stopped waiting for command status")
      }
    )
    .cancellable(id: CancellableAction.statusListeners, cancelInFlight: true)
  }
}

public struct RemoteScreen: View {
  public let store: StoreOf<RemoteFeature>

  public init(store: StoreOf<RemoteFeature>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        Text(viewStore.currentMileage)
        Text(viewStore.currentTemperature)
        Text(viewStore.isCharging ? "Currently charging!" : "Not charging!")
        Text(viewStore.isCommandInProgress ? "Command in flight" : "Command idle")
        Button(viewStore.isListening ? "Stop Listening" : "Start Listening") {
          viewStore.send(.toggleListeningButtonTapped)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .onAppear {
        viewStore.send(.onAppear)
      }
      .onDisappear {
        viewStore.send(.onDisappear)
      }
    }
  }
}

#Preview {
  RemoteScreen(store: StoreOf<RemoteFeature>.init(initialState: RemoteFeature.State(currentTemperature: "Loading...",
                                                                                    currentMileage: "Loading...",
                                                                                    isCommandInProgress: false,
                                                                                    isCharging: false)) {
      RemoteFeature()._printChanges()
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
    }
  )
}

import Algorithms

extension AsyncStream where Element: Sendable {
  enum Event: Sendable {
    case delay(Duration)
    case value(Element)
  }

  init(events: Event...) {
    self = .init { continuation in
      @Dependency(\.continuousClock) var continuousClock

      Task {
        for event in events.cycled() {
          switch event {
          case let .delay(duration):
            try? await continuousClock.sleep(for: duration)
          case let .value(value):
            continuation.yield(value)
          }
        }
      }
    }
  }
}
