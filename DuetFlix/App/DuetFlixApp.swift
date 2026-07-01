//
//  DuetFlixApp.swift
//  DuetFlix
//
//  Created by Batu on 30.06.2026.
//

import SwiftUI

@main // uygulama burdan başlar 
struct DuetFlixApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.dark) // varsayılan mod koyu
        }
    }
}
