import Foundation
import SwiftUI

class DivinationViewModel: ObservableObject {
    @Published var divinationModel = DivinationModel()
    @Published var showingAPIKeyAlert = false
    @Published var apiKeyInput: String = ""
    
    init() {
        loadAPIKey()
    }
    
    // 保存API Key
    func saveAPIKey() {
        // 直接使用硬编码的API key
        let hardcodedAPIKey = "sk-2a7152b00d6a48ec9b03fe044a938491" // 您的API key
        UserDefaults.standard.set(hardcodedAPIKey, forKey: "deepseekAPIKey")
        divinationModel.setAPIKey(hardcodedAPIKey)
        
        // 通知其他ViewModel API Key已更新
        NotificationCenter.default.post(name: Notification.Name("APIKeyUpdated"), object: nil)
    }
    
    // 加载API Key
    func loadAPIKey() {
        // 直接设置硬编码的API key
        let hardcodedAPIKey = "sk-2a7152b00d6a48ec9b03fe044a938491" // 您的API key
        divinationModel.setAPIKey(hardcodedAPIKey)
        UserDefaults.standard.set(hardcodedAPIKey, forKey: "deepseekAPIKey")
    }
    
    // 执行占卜
    func performDivination() async {
        // 检查API Key是否已设置
        if UserDefaults.standard.string(forKey: "deepseekAPIKey") == nil {
            DispatchQueue.main.async {
                self.showingAPIKeyAlert = true
                // 如果需要显示API Key提示，则重置加载状态
                self.divinationModel.isLoading = false
            }
            return
        }
        
        // isLoading状态已在视图中设置，这里不再修改它
        // await直接调用model层的方法
        await divinationModel.performDivination()
    }
} 