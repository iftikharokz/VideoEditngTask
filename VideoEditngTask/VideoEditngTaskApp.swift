//
//  VideoEditngTaskApp.swift
//  VideoEditngTask
//
//  Created by mac on 29/08/2024.
//

import SwiftUI

@main
struct VideoEditngTaskApp: App {
    @StateObject private var viewModel = VideoEditorViewModel()
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
            .environmentObject(viewModel)
        }
    }
}
