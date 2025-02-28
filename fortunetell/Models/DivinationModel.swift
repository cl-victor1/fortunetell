import Foundation

// 梅花易数占卜模型
class DivinationModel: ObservableObject {
    // 用户输入
    @Published var userQuestion: String = ""
    @Published var selectedMethod: DivinationMethod = .automatic
    
    // 占卜结果
    @Published var hexagramResult: String = ""
    @Published var interpretation: String = ""
    @Published var isLoading: Bool = false
    
    // DeepSeek API Key
    private var apiKey: String = ""
    
    // 设置API Key
    func setAPIKey(_ key: String) {
        self.apiKey = key
    }
    
    // 占卜方法
    enum DivinationMethod: String, CaseIterable, Identifiable {
        case automatic = "自动选择"
        case timeMethod = "时间起卦"
        case numberMethod = "数字起卦"
        case nameMethod = "姓名起卦"
        
        var id: String { self.rawValue }
    }
    
    // 根据用户输入自动选择占卜方法
    func determineMethod(for input: String) -> DivinationMethod {
        if input.isEmpty {
            return .timeMethod // 默认使用时间起卦
        }
        
        // 检查输入是否为纯数字
        if input.allSatisfy({ $0.isNumber }) {
            return .numberMethod
        }
        
        // 检查输入是否包含姓名相关词汇
        let nameKeywords = ["我叫", "名字", "姓名", "我是"]
        if nameKeywords.contains(where: { input.contains($0) }) {
            return .nameMethod
        }
        
        // 其他情况使用时间起卦
        return .timeMethod
    }
    
    // 执行占卜
    func performDivination() async {
        // 确保isLoading为true并强制UI更新
        DispatchQueue.main.async {
            // 清空结果
            self.hexagramResult = ""
            self.interpretation = ""
            
            // 设置加载状态并强制UI刷新
            self.isLoading = true
            
            // 再次设置以确保UI更新
            DispatchQueue.main.async {
                self.isLoading = true
            }
        }
        
        // 等待一小段时间确保UI已更新
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        // 如果选择自动，则根据输入确定方法
        let method = selectedMethod == .automatic ? 
            determineMethod(for: userQuestion) : selectedMethod
        
        // 根据不同方法生成卦象
        var hexagram = ""
        switch method {
        case .timeMethod:
            hexagram = generateTimeHexagram()
        case .numberMethod:
            hexagram = generateNumberHexagram(from: userQuestion)
        case .nameMethod:
            hexagram = generateNameHexagram(from: userQuestion)
        case .automatic:
            // 已在上面处理
            break
        }
        
        // 更新UI显示卦象
        DispatchQueue.main.async {
            self.hexagramResult = hexagram
        }
        
        // 调用DeepSeek API获取解释
        await getInterpretation(for: hexagram, question: userQuestion)
        
        // 注意：isLoading状态已在getInterpretation方法中设置为false
    }
    
    // 时间起卦法
    private func generateTimeHexagram() -> String {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let second = calendar.component(.second, from: now)
        
        // 使用时间数据生成卦象
        // 这里使用简化算法，实际应用中可能需要更复杂的梅花易数算法
        let upperTrigram = (hour % 8)
        let lowerTrigram = (minute % 8)
        let changingLine = (second % 6) + 1
        
        return formatHexagram(upper: upperTrigram, lower: lowerTrigram, changing: changingLine)
    }
    
    // 数字起卦法
    private func generateNumberHexagram(from input: String) -> String {
        // 将输入的数字转换为卦象
        let numbers = input.compactMap { Int(String($0)) }
        let sum = numbers.reduce(0, +)
        
        let upperTrigram = (sum % 8)
        let lowerTrigram = ((sum / 8) % 8)
        let changingLine = ((sum / 64) % 6) + 1
        
        return formatHexagram(upper: upperTrigram, lower: lowerTrigram, changing: changingLine)
    }
    
    // 姓名起卦法
    private func generateNameHexagram(from input: String) -> String {
        // 将姓名转换为数值并生成卦象
        var nameValue = 0
        for char in input {
            nameValue += Int(char.unicodeScalars.first?.value ?? 0)
        }
        
        let upperTrigram = (nameValue % 8)
        let lowerTrigram = ((nameValue / 8) % 8)
        let changingLine = ((nameValue / 64) % 6) + 1
        
        return formatHexagram(upper: upperTrigram, lower: lowerTrigram, changing: changingLine)
    }
    
    // 格式化卦象
    private func formatHexagram(upper: Int, lower: Int, changing: Int) -> String {
        let trigrams = ["坤", "震", "坎", "兑", "艮", "离", "巽", "乾"]
        let upperName = trigrams[upper]
        let lowerName = trigrams[lower]
        
        // 计算卦象编号 (1-64)
        let hexagramNumber = upper * 8 + lower + 1
        
        return "第\(hexagramNumber)卦 \(upperName)\(lowerName)卦 变爻: 第\(changing)爻"
    }
    
    // 调用DeepSeek API获取解释
    private func getInterpretation(for hexagram: String, question: String) async {
        guard !apiKey.isEmpty else {
            DispatchQueue.main.async {
                self.interpretation = "请先设置DeepSeek API Key"
                self.isLoading = false
            }
            return
        }
        
        // 确保用户看到加载状态
        DispatchQueue.main.async {
            self.isLoading = true
            
            // 再次设置以确保UI更新
            DispatchQueue.main.async {
                self.isLoading = true
            }
        }
        
        // 等待一小段时间确保UI已更新
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        let prompt = """
        作为一位精通梅花易数的专业占卜师，请对以下卦象进行详细解读：
        
        卦象：\(hexagram)
        问题：\(question)
        
        请提供：
        1. 卦象的基本含义
        2. 对问题的具体解答
        3. 吉凶指示和建议
        
        请用中文回答，语言要专业但通俗易懂。请使用Markdown格式来组织你的回答，包括：
        - 使用 # ## ### 等标题层级
        - 使用 - 或 * 创建无序列表
        - 使用 1. 2. 3. 创建有序列表
        - 使用 **文字** 或 *文字* 进行强调
        - 每个段落之间空一行
        
        请确保Markdown格式正确，以便于阅读和排版。
        """
        
        // 构建API请求
        let url = URL(string: "https://api.deepseek.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 1000
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                
                // 处理返回的Markdown内容
                let markdownContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                
                DispatchQueue.main.async {
                    self.interpretation = markdownContent
                    self.isLoading = false
                    
                    // 确保UI立即更新，不使用延迟
                    NotificationCenter.default.post(name: Notification.Name("DivinationCompleted"), object: nil)
                }
            } else {
                throw NSError(domain: "API解析错误", code: 0)
            }
        } catch {
            DispatchQueue.main.async {
                self.interpretation = "获取解释失败: \(error.localizedDescription)"
                self.isLoading = false
                
                // 确保UI立即更新，不使用延迟
                NotificationCenter.default.post(name: Notification.Name("DivinationCompleted"), object: nil)
            }
        }
    }
} 