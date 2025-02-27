//
//  fortunetellApp.swift
//  fortunetell
//
//  Created by Victo_cl on 2025/2/26.
//

import SwiftUI

@main
struct fortunetellApp: App {
    // 设置中文本地化
    init() {
        // 设置首选语言为中文
        UserDefaults.standard.set(["zh-Hans"], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
