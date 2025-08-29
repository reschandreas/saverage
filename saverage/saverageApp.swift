//
//  saverageApp.swift
//  saverage
//
//  Created by Andreas Resch on 20.07.25.
//

import SwiftUI
import SwiftData

@main
struct saverageApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(startDate: Date().addingTimeInterval(-86400 * 7), endDate: Date())
        }
    }
}
