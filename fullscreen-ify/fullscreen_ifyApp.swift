//
//  fullscreen_ifyApp.swift
//  fullscreen-ify
//
//  Created by Shivansh Agarwal on 15/04/26.
//

import SwiftUI

@main
struct fullscreen_ifyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 480, minHeight: 400)
        }
        .defaultSize(width: 560, height: 680)
    }
}
