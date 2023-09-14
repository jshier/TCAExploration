//
//  TCAExplorationApp.swift
//  TCAExploration
//
//  Created by Jon Shier on 8/16/23.
//

import ComposableArchitecture
import SwiftUI
import XCTestDynamicOverlay

@main
struct TCAExplorationApp: App {
  var body: some Scene {
    WindowGroup {
      if _XCTIsTesting {
        Text("Testing...")
      } else {
        RootView(store: Store(initialState: .init()) { RootFeature()._printChanges() })
      }
    }
  }
}
