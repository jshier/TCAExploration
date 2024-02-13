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

public struct RemoteNetworking: Sendable {
  var commandStatus: @Sendable () -> AsyncStream<CommandStatus>
  var vehicleStatus: @Sendable () -> AsyncStream<VehicleStatus>
  var electricStatus: @Sendable () -> AsyncStream<ElectricalVehicleStatus>
  var hvacSettings: @Sendable () -> AsyncStream<HVACSettings>
}

extension RemoteNetworking {
  static var infiniteSequence: RemoteNetworking {
    RemoteNetworking {
      AsyncStream(events: .value(.none), .delay(.seconds(1)), .value(.inFlight), .delay(.seconds(1)))
    } vehicleStatus: {
      AsyncStream(events: .value(.init(doors: .open, windows: .closed, odometer: 1234)), .delay(.seconds(1)))
    } electricStatus: {
      AsyncStream(events: .value(.init(plugin: .unplugged)), .delay(.seconds(1)))
    } hvacSettings: {
      AsyncStream(events: .value(.init(temperature: 72, isDefrostOn: false)), .delay(.seconds(1)))
    }
  }
}

private enum RemoteNetworkingKey: DependencyKey {
  static let liveValue: RemoteNetworking = .infiniteSequence
  static let previewValue: RemoteNetworking = .infiniteSequence
  static let testValue: RemoteNetworking = RemoteNetworking(commandStatus: { unimplemented() },
                                                            vehicleStatus: { unimplemented() },
                                                            electricStatus: { unimplemented() },
                                                            hvacSettings: { unimplemented() })
}

public extension DependencyValues {
  var remoteNetworking: RemoteNetworking {
    get { self[RemoteNetworkingKey.self] }
    set { self[RemoteNetworkingKey.self] = newValue }
  }
}
