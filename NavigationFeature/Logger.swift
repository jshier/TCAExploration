import Dependencies

public struct Logger: Sendable {
  public var _log: @Sendable (_ items: [Any], _ separator: String, _ terminator: String) -> Void

  public func log(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    _log(items, separator, terminator)
  }
}

private enum LoggerKey: DependencyKey {
  static var liveValue = Logger { print($0, separator: $1, terminator: $2) }

  static var testValue = Logger { _, _, _ in }
}

public extension DependencyValues {
  var logger: Logger {
    get { self[LoggerKey.self] }
    set { self[LoggerKey.self] = newValue }
  }
}
