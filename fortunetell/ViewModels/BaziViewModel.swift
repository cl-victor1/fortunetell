import Foundation
import SwiftUI

class BaziViewModel: ObservableObject {
    @Published var baziModel = BaziModel()
    
    init() {
        loadAPIKey()
        
        // 监听API Key更新通知
        NotificationCenter.default.addObserver(self, selector: #selector(apiKeyUpdated), name: Notification.Name("APIKeyUpdated"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // API Key更新通知处理
    @objc func apiKeyUpdated() {
        if let apiKey = UserDefaults.standard.string(forKey: "deepseekAPIKey") {
            baziModel.setAPIKey(apiKey)
        }
    }
    
    // 保存API Key
    func saveAPIKey() {
        // 直接使用硬编码的API key
        let hardcodedAPIKey = "sk-2a7152b00d6a48ec9b03fe044a938491" // 您的API key
        UserDefaults.standard.set(hardcodedAPIKey, forKey: "deepseekAPIKey")
        baziModel.setAPIKey(hardcodedAPIKey)
        
        // 通知其他ViewModel API Key已更新
        NotificationCenter.default.post(name: Notification.Name("APIKeyUpdated"), object: nil)
    }
    
    // 加载API Key
    func loadAPIKey() {
        // 直接设置硬编码的API key
        let hardcodedAPIKey = "sk-2a7152b00d6a48ec9b03fe044a938491" // 您的API key
        baziModel.setAPIKey(hardcodedAPIKey)
        UserDefaults.standard.set(hardcodedAPIKey, forKey: "deepseekAPIKey")
    }
    
    // 执行八字解读
    func performBaziAnalysis() async {
        // 检查API Key是否已设置
        if UserDefaults.standard.string(forKey: "deepseekAPIKey") == nil {
            // 如果没有设置，使用硬编码的API key
            saveAPIKey()
        }
        
        // isLoading状态已在视图中设置，这里不再修改它
        // await直接调用model层的方法
        await baziModel.calculateBazi()
    }
} 