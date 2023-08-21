//
//  TCAExplorationApp.swift
//  TCAExploration
//
//  Created by Jon Shier on 8/16/23.
//

import ComposableArchitecture
import SwiftUI

@main
struct TCAExplorationApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(store: Store(initialState: .init()) { RootFeature()._printChanges() })
        }
    }
}
