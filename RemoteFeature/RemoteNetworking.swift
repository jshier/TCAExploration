import Dependencies

public struct VehicleStatus: Equatable, Sendable {
  public enum Doors: Equatable, Sendable { case open, closed }
  public enum Windows: Equatable, Sendable { case open, closed }

  public let doors: Doors
  public let windows: Windows
  public let odometer: Int
}

public struct ElectricalVehicleStatus: Equatable, Sendable {
  public enum PluginStatus: Equatable, Sendable { case unplugged, pluggedIn(isCharging: Bool) }

  public let plugin: PluginStatus
}

public struct HVACSettings: Equatable, Sendable {
  public let temperature: Int
  public let isDefrostOn: Bool
}

public enum CommandStatus: Equatable, Sendable {
  case none, inFlight
}

struct RemoteNetworking: Sendable {
  var commandStatus: @Sendable () -> AsyncStream<CommandStatus>
  var vehicleStatus: @Sendable () -> AsyncStream<VehicleStatus>
  var electricStatus: @Sendable () -> AsyncStream<ElectricalVehicleStatus>
  var hvacSettings: @Sendable () -> AsyncStream<HVACSettings>
}

private enum RemoteNetworkingKey: DependencyKey {
  @Dependency(\.continuousClock) private static var continuousClock

  static var liveValue = RemoteNetworking {
    AsyncStream { _ in
    }
  } vehicleStatus: {
    AsyncStream { _ in
    }
  } electricStatus: {
    AsyncStream { _ in
    }
  } hvacSettings: {
    AsyncStream { _ in
    }
  }
}

extension DependencyValues {
  var remoteNetworking: RemoteNetworking {
    get { self[RemoteNetworkingKey.self] }
    set { self[RemoteNetworkingKey.self] = newValue }
  }
}
