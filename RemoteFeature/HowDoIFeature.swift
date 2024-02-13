import ComposableArchitecture
import SwiftUI

@Reducer
struct HowDoIFeature<ID> where ID: FlowID {
  @ObservableState
  struct State {
    let flow: Flow<ID>
    var steps = StackState<HowDoIStepFeature<ID>.State>()
  }

  enum Action {
    case actionTapped(Flow<ID>.Step.Action)
    case steps(StackAction<HowDoIStepFeature<ID>.State, HowDoIStepFeature<ID>.Action>)
  }

  @Dependency(\.dismiss) var dismiss

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .actionTapped(action), let .steps(.element(id: _, action: .actionTapped(action))):
        switch action.kind {
        case .back:
          _ = state.steps.popLast()
        case let .pushTo(id):
          state.steps.append(.init(step: state.flow[id]))

          return .none
        case .done:
          return .run { _ in await dismiss() }
        }

        return .none
      // Any other step actions.
      case .steps:
        return .none
      }
    }
    .forEach(\.steps, action: /Action.steps) {
      HowDoIStepFeature<ID>()
    }
  }
}

@Reducer
struct HowDoIStepFeature<ID> where ID: FlowID {
  @ObservableState
  struct State {
    let step: Flow<ID>.Step
  }

  enum Action {
    case actionTapped(Flow<ID>.Step.Action)
  }
}

protocol FlowID: Hashable, CaseIterable {}

struct Flow<ID> where ID: FlowID {
  struct Start: Equatable {
    let title: String
    let actions: [Step.Action]
  }

  struct Step: Equatable, Identifiable {
    struct Action: Hashable {
      enum Kind: Hashable {
        case back
        case pushTo(ID)
        case done
      }

      let title: String
      let kind: Kind
    }

    struct Init {
      let title: String
      let actions: [Action]
    }

    let id: ID
    let title: String
    let actions: [Action]
  }

  let start: Start
  let steps: [ID: Step]

  subscript(_ id: ID) -> Step {
    steps[id]!
  }

  init(start: Start, steps: [ID: Step.Init]) {
    self.start = start
    self.steps = ID.allCases.reduce(into: [:]) { partialResult, id in
      guard let initState = steps[id] else { fatalError("All IDs must have corresponding Init value.") }

      let step = Step(id: id, title: initState.title, actions: initState.actions)

      partialResult[id] = step
    }
  }
}

enum TestFlowID: FlowID {
  case first, second, third, fourth
}

typealias TestFlow = Flow<TestFlowID>

extension TestFlow {
  init() {
    let start = Start(title: "Start screen!", actions: [.init(title: "Get Started!", kind: .pushTo(.first))])
    self.init(start: start, steps: [
      .first: .init(title: "First Step", actions: [.init(title: "Go to Next", kind: .pushTo(.second))]),
      .second: .init(title: "Second Step", actions: [.init(title: "Go to Third", kind: .pushTo(.third)),
                                                     .init(title: "Go to Fourth", kind: .pushTo(.fourth))]),
      .third: .init(title: "Third", actions: [.init(title: "Go to Fourth", kind: .pushTo(.fourth))]),
      .fourth: .init(title: "Fourth", actions: [.init(title: "Done", kind: .done)])
    ])
    // Ensure each created step has the id for its case.
    // Ensure each ID gets a step (dictionary will crash otherwise, so maybe not).
    // Generalize into something usable by multiple flows.
  }
}

struct HowDoIFlowView<ID>: View where ID: FlowID {
  @Perception.Bindable var store: StoreOf<HowDoIFeature<ID>>

  var body: some View {
    NavigationStack(path: $store.scope(state: \.steps, action: \.steps)) {
      HowDoIStartView<ID>(store: store)
    } destination: { store in
      HowDoIStepView<ID>(store: store)
        .navigationBarTitleDisplayMode(.inline)
    }
  }
}

struct HowDoIStartView<ID>: View where ID: FlowID {
  let store: StoreOf<HowDoIFeature<ID>>

  var body: some View {
    WithPerceptionTracking {
      VStack {
        Text(store.flow.start.title)
        ForEach(store.flow.start.actions, id: \.self) { action in
          Button(action.title) {
            store.send(.actionTapped(action))
          }
        }
      }
      .navigationTitle(store.flow.start.title)
    }
  }
}

struct HowDoIStepView<ID>: View where ID: FlowID {
  struct ViewState: Equatable {
    let title: String
    let actions: [Flow<ID>.Step.Action]

    init(_ state: HowDoIStepFeature<ID>.State) {
      title = state.step.title
      actions = state.step.actions
    }
  }

  let store: StoreOf<HowDoIStepFeature<ID>>

  var body: some View {
    WithPerceptionTracking {
      VStack {
        Text(store.step.title)
        ForEach(store.step.actions, id: \.self) { action in
          Button(action.title) {
            store.send(.actionTapped(action))
          }
        }
      }
      .navigationTitle(store.step.title)
    }
  }
}

#Preview {
  HowDoIFlowView<TestFlowID>(store: .init(initialState: .init(flow: TestFlow())) {
    HowDoIFeature()
  })
}
