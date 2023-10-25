import ComposableArchitecture
import SwiftUI

public struct RemoteFeature: Reducer {
  public struct State: Equatable, Sendable {
    var currentTemperature: String
    var currentMileage: String
    var commandSummary: String
    var chargingSummary: String
    var isListening: Bool

    var toggleListeningButtonTitle: String {
      isListening ? "Stop Listening" : "Start Listening"
    }

    public init(
      currentTemperature: String = "Loading...",
      currentMileage: String = "Loading...",
      commandSummary: String = "Loading...",
      chargingSummary: String = "Loading...",
      isListening: Bool = false
    ) {
      self.currentTemperature = currentTemperature
      self.currentMileage = currentMileage
      self.commandSummary = commandSummary
      self.chargingSummary = chargingSummary
      self.isListening = isListening
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

  public init() {}

  @Dependency(\.remoteNetworking) var remoteNetworking

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        // Or start listenerEffect.
        return .none
      case .onDisappear:
        state.isListening = false

        return .cancel(id: CancellableAction.statusListeners)
      case let .receiveVehicleStatus(status):
        state.currentMileage = "\(status.odometer) mi"

        return .none
      case let .receiveElectricStatus(status):
        state.chargingSummary = status.plugin == .pluggedIn(isCharging: true) ? "Currently charging!" : "Not charging!"

        return .none
      case let .receiveHVACSettings(settings):
        state.currentTemperature = "\(settings.temperature)°F"

        return .none
      case let .receiveCommandStatus(status):
        state.commandSummary = status == .inFlight ? "Command in flight" : "Command idle"

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
        Text(viewStore.chargingSummary)
        Text(viewStore.commandSummary)
        Button(viewStore.toggleListeningButtonTitle) {
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
  RemoteScreen(store: StoreOf<RemoteFeature>(initialState: RemoteFeature.State()) {
    RemoteFeature()._printChanges()
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
