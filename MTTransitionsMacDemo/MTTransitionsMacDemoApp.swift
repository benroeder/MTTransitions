//
//  MTTransitionsMacDemoApp.swift
//  MTTransitionsMacDemo
//
//  macOS demo app for MTTransitions
//

import SwiftUI

@main
struct MTTransitionsMacDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 700)
    }
}
