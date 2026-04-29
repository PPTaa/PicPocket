//
//  PicPocketApp.swift
//  PicPocket
//
//  Created by Jung chul Lee on 4/29/26.
//

import SwiftUI
import ComposableArchitecture

@main
struct PicPocketApp: App {
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }
    
    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}
