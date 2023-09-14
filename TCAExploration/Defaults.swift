import Dependencies
import Foundation

struct Defaults {
  @AddAccessClosures
  var selectedRootTab: RootFeature.Tab?
}

@propertyWrapper
struct AddAccessClosures<Value> {
  var getter: @Sendable () -> Value
  var setter: @Sendable (Value) -> Void

  var wrappedValue: Value {
    get { getter() }
    nonmutating set { setter(newValue) }
  }

  var projectedValue: Self {
    get { self }
    set { self = newValue }
  }

  init(wrappedValue: Value) {
    getter = unimplemented()
    setter = unimplemented()
  }
}

final class LiveDefaults: Sendable {
  var selectedRootTab: RootFeature.Tab? {
    get { userDefaults.string(forKey: #function).flatMap(RootFeature.Tab.init) }
    set { updateOrRemove(newValue?.rawValue, forKey: #function) }
  }

  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  private func updateOrRemove<Value>(_ value: Value?, forKey key: String) {
    if let value {
      userDefaults.set(value, forKey: key)
    } else {
      userDefaults.removeObject(forKey: key)
    }
  }
}

extension UserDefaults: @unchecked Sendable {}

private enum DefaultsKey: DependencyKey {
  static var liveValue = {
    let liveDefaults = LiveDefaults()
    var defaults = Defaults()
    defaults.$selectedRootTab.getter = { liveDefaults.selectedRootTab }
    defaults.$selectedRootTab.setter = { liveDefaults.selectedRootTab = $0 }

    return defaults
  }()

  static var testValue = {
    var defaults = Defaults()

    return defaults
  }()
}

extension DependencyValues {
  var defaults: Defaults {
    get { self[DefaultsKey.self] }
    set { self[DefaultsKey.self] = newValue }
  }
}
