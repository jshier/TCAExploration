import Combine
import ComposableArchitecture
import UIKit

class ComposableViewController<Reducer>: UIViewController where Reducer: ComposableArchitecture.Reducer {
  let store: StoreOf<Reducer>

  init(store: StoreOf<Reducer>) {
    self.store = store

    super.init(nibName: nil, bundle: nil)
  }

  override func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)

    observe { [weak self] in
      guard let self else { return }

      onStateUpdate()
    }
  }

  /// Override with actions to be performed when `Store` state updates.
  func onStateUpdate() {}

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

final class RemoteFeatureViewController: ComposableViewController<RemoteControlFeature> {
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

    stack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
    ])

    toggleListeningButton.addAction(.init { [unowned self] _ in store.send(.toggleListeningButtonTapped) },
                                    for: .touchUpInside)
  }

  override func onStateUpdate() {
    currentMileageLabel.text = store.currentMileage
    currentTemperatureLabel.text = store.currentTemperature
    isChargingLabel.text = store.chargingSummary
    isCommandInProgressLabel.text = store.commandSummary
    toggleListeningButton.setTitle(store.toggleListeningButtonTitle, for: .normal)
  }
}

@available(iOS 17, *)
#Preview {
  RemoteFeatureViewController(store:
    StoreOf<RemoteControlFeature>(initialState: RemoteControlFeature.State()) {
      RemoteControlFeature()._printChanges()
    }
  )
}
