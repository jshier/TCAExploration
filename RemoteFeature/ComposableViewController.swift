import Combine
import ComposableArchitecture
import UIKit

class ComposableViewController<Reducer>: UIViewController where Reducer: ComposableArchitecture.Reducer {
  let store: StoreOf<Reducer>
  var cancellables: Set<AnyCancellable> = []

  init(store: StoreOf<Reducer>) {
    self.store = store

    super.init(nibName: nil, bundle: nil)
  }

  func observe(_ observations: AnyCancellable...) {
    for observation in observations {
      observation.store(in: &cancellables)
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

final class RemoteFeatureViewController: ComposableViewController<RemoteFeature> {
  private lazy var currentMileageLabel: UILabel = .init(frame: .zero)
  private lazy var currentTemperatureLabel: UILabel = .init(frame: .zero)
  private lazy var isChargingLabel: UILabel = .init(frame: .zero)
  private lazy var isCommandInProgressLabel: UILabel = .init(frame: .zero)
  private lazy var toggleListeningButton: UIButton = .init(type: .system)

  override func viewDidLoad() {
    super.viewDidLoad()

    let stack = UIStackView(arrangedSubviews: [
      currentMileageLabel,
      currentTemperatureLabel,
      isChargingLabel,
      isCommandInProgressLabel,
      toggleListeningButton
    ])
    stack.axis = .vertical

    view.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
    ])
    stack.translatesAutoresizingMaskIntoConstraints = false

    toggleListeningButton.addAction(.init { _ in self.store.send(.toggleListeningButtonTapped) }, for: .touchUpInside)
  }

  override func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)

    observe(
      store.publisher.currentMileage.map(Optional.some).assign(to: \.text, on: currentMileageLabel),
      store.publisher.currentTemperature.map(Optional.some).assign(to: \.text, on: currentTemperatureLabel),
      store.publisher.isCharging
        .map { $0 ? "Currently charging!" : "Not charging!" }
        .assign(to: \.text, on: isChargingLabel),
      store.publisher.isCommandInProgress
        .map { $0 ? "Command in flight" : "Command idle" }
        .assign(to: \.text, on: isCommandInProgressLabel),
      store.publisher.isListening
        .map { $0 ? "Stop Listening" : "Start Listening" }
        .sink { self.toggleListeningButton.setTitle($0, for: .normal) }
    )
  }
}

#Preview {
  RemoteFeatureViewController(store:
    StoreOf<RemoteFeature>(initialState: RemoteFeature.State(currentTemperature: "Loading...",
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
