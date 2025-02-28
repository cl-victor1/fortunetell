//
//  ContentView.swift
//  fortunetell
//
//  Created by Victo_cl on 2025/2/26.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var divinationViewModel = DivinationViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 梅花易数占卜标签页
            DivinationTabView(viewModel: divinationViewModel)
                .tabItem {
                    Label("梅花易数", systemImage: "hexagon")
                }
                .tag(0)
            
            // 生辰八字标签页
            BaziView()
                .tabItem {
                    Label("生辰八字", systemImage: "calendar")
                }
                .tag(1)
        }
        .accentColor(Color(red: 0.7, green: 0.2, blue: 0.1))
    }
}

// 梅花易数占卜标签页视图
struct DivinationTabView: View {
    @ObservedObject var viewModel: DivinationViewModel
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景色 - 淡黄色背景，类似古纸
                Color(red: 0.98, green: 0.95, blue: 0.85)
                    .edgesIgnoringSafeArea(.all)
                
                // 将整个内容放入ScrollView中
                ScrollView {
                    VStack(spacing: 20) {
                        // 顶部标题
                        Text("梅花易数")
                            .font(.system(size: 36, weight: .bold, design: .serif))
                            .foregroundColor(Color(red: 0.6, green: 0.1, blue: 0.1)) // 暗红色，传统中国色
                            .padding(.top)
                        
                        // 副标题
                        Text("传统中华占卜术")
                            .font(.system(size: 16, design: .serif))
                            .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.1))
                            .padding(.bottom, 10)
                        
                        // 占卜方法选择
                        VStack(alignment: .leading) {
                            Text("选择起卦方式:")
                                .font(.headline)
                                .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.1))
                            
                            Picker("占卜方法", selection: $viewModel.divinationModel.selectedMethod) {
                                ForEach(DivinationModel.DivinationMethod.allCases) { method in
                                    Text(method.rawValue).tag(method)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.vertical, 5)
                        }
                        .padding(.horizontal)
                        
                        // 问题输入区域
                        VStack(alignment: .leading) {
                            Text("请输入您的问题:")
                                .font(.headline)
                                .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.1))
                            
                            TextEditor(text: $viewModel.divinationModel.userQuestion)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color(white: 1, opacity: 0.7))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(red: 0.6, green: 0.3, blue: 0.1), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                        
                        // 占卜按钮
                        Button(action: {
                            // 先设置isLoading为true
                            viewModel.divinationModel.isLoading = true
                            
                            // 强制UI更新
                            DispatchQueue.main.async {
                                // 再次确认isLoading状态，强制UI刷新
                                viewModel.divinationModel.isLoading = true
                                
                                // 直接执行占卜，不需要延迟
                                Task {
                                    await viewModel.performDivination()
                                }
                            }
                        }) {
                            Text("开始占卜")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(red: 0.7, green: 0.2, blue: 0.1))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .disabled(viewModel.divinationModel.isLoading)
                        .id("divination_button_\(viewModel.divinationModel.isLoading)") // 添加动态ID确保状态变化时按钮刷新
                        
                        // 加载指示器
                        if viewModel.divinationModel.isLoading {
                            ProgressView("正在占卜...")
                                .padding()
                                .id(UUID()) // 添加唯一ID确保每次状态变化时视图都会刷新
                        }
                        
                        // 结果区域
                        VStack(alignment: .leading, spacing: 15) {
                            if !viewModel.divinationModel.hexagramResult.isEmpty {
                                ResultSectionView(title: "卦象", content: viewModel.divinationModel.hexagramResult)
                            }
                            
                            if !viewModel.divinationModel.interpretation.isEmpty {
                                ResultSectionView(title: "解读", content: viewModel.divinationModel.interpretation)
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.bottom, 20)
                    .id("divination_content_\(viewModel.divinationModel.isLoading)_\(viewModel.divinationModel.hexagramResult.isEmpty)_\(viewModel.divinationModel.interpretation.isEmpty)") // 添加动态ID确保状态变化时内容刷新
                }
                .navigationBarItems(trailing: Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gear")
                        .foregroundColor(Color(red: 0.6, green: 0.1, blue: 0.1))
                })
                .sheet(isPresented: $showSettings) {
                    SettingsView(viewModel: viewModel)
                }
                .alert("设置API Key", isPresented: $viewModel.showingAPIKeyAlert) {
                    TextField("请输入DeepSeek API Key", text: $viewModel.apiKeyInput)
                    Button("保存") {
                        viewModel.saveAPIKey()
                        Task {
                            await viewModel.performDivination()
                        }
                    }
                    Button("取消", role: .cancel) { }
                } message: {
                    Text("请输入您的DeepSeek API Key以继续使用占卜功能")
                }
            }
        }
    }
}

// 结果部分视图
struct ResultSectionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(Color(red: 0.6, green: 0.1, blue: 0.1))
                
                Spacer()
                
                // 添加复制按钮
                Button(action: {
                    UIPasteboard.general.string = content
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(Color(red: 0.6, green: 0.1, blue: 0.1))
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.bottom, 6)
            
            MarkdownText(content)
                .padding(.horizontal, 2)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 1, opacity: 0.7))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 0.6, green: 0.3, blue: 0.1), lineWidth: 1)
        )
    }
}

// Markdown文本渲染视图
struct MarkdownText: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            VStack(alignment: .leading, spacing: 0) {
                ForEach(splitIntoBlocks(text), id: \.self) { block in
                    renderBlock(block)
                        .padding(.bottom, 8)
                }
            }
        }
        .textSelection(.enabled) // 允许用户选择文本
    }
    
    // 将文本分割成块
    private func splitIntoBlocks(_ text: String) -> [String] {
        let lines = text.components(separatedBy: "\n")
        var blocks: [String] = []
        var currentBlock = ""
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 如果是空行，结束当前块并开始新块
            if trimmedLine.isEmpty {
                if !currentBlock.isEmpty {
                    blocks.append(currentBlock)
                    currentBlock = ""
                }
            } else {
                // 如果是标题行，结束当前块并将标题作为单独的块
                if trimmedLine.hasPrefix("#") {
                    if !currentBlock.isEmpty {
                        blocks.append(currentBlock)
                        currentBlock = ""
                    }
                    blocks.append(trimmedLine)
                }
                // 如果是列表项，结束当前块并将列表项作为单独的块
                else if trimmedLine.hasPrefix("-") || trimmedLine.hasPrefix("*") || trimmedLine.match(pattern: "^\\d+\\.\\s") {
                    if !currentBlock.isEmpty && !currentBlock.contains("\n- ") && !currentBlock.contains("\n* ") && !currentBlock.match(pattern: "\n\\d+\\.\\s") {
                        blocks.append(currentBlock)
                        currentBlock = ""
                    }
                    
                    if currentBlock.isEmpty {
                        currentBlock = trimmedLine
                    } else {
                        currentBlock += "\n" + trimmedLine
                    }
                }
                // 否则，将行添加到当前块
                else {
                    if currentBlock.isEmpty {
                        currentBlock = trimmedLine
                    } else {
                        currentBlock += "\n" + trimmedLine
                    }
                }
            }
        }
        
        // 添加最后一个块
        if !currentBlock.isEmpty {
            blocks.append(currentBlock)
        }
        
        return blocks
    }
    
    // 渲染块
    private func renderBlock(_ block: String) -> some View {
        let trimmedBlock = block.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 渲染标题
        if trimmedBlock.hasPrefix("# ") {
            return AnyView(renderHeading(trimmedBlock, level: 1))
        } else if trimmedBlock.hasPrefix("## ") {
            return AnyView(renderHeading(trimmedBlock, level: 2))
        } else if trimmedBlock.hasPrefix("### ") {
            return AnyView(renderHeading(trimmedBlock, level: 3))
        } else if trimmedBlock.hasPrefix("#### ") {
            return AnyView(renderHeading(trimmedBlock, level: 4))
        } else if trimmedBlock.hasPrefix("##### ") {
            return AnyView(renderHeading(trimmedBlock, level: 5))
        }
        // 渲染列表
        else if trimmedBlock.hasPrefix("- ") || trimmedBlock.hasPrefix("* ") {
            return AnyView(renderUnorderedList(trimmedBlock))
        } else if trimmedBlock.match(pattern: "^\\d+\\.\\s") {
            return AnyView(renderOrderedList(trimmedBlock))
        }
        // 渲染普通段落
        else {
            return AnyView(renderParagraph(trimmedBlock))
        }
    }
    
    // 渲染标题
    private func renderHeading(_ text: String, level: Int) -> some View {
        let headingText = text.replacingOccurrences(of: "^#{1,5}\\s+", with: "", options: .regularExpression)
        let processedText = processInlineMarkdown(headingText)
        
        let fontSize: CGFloat
        let fontWeight: Font.Weight
        let paddingBottom: CGFloat
        
        switch level {
        case 1:
            fontSize = 24
            fontWeight = .bold
            paddingBottom = 12
        case 2:
            fontSize = 22
            fontWeight = .bold
            paddingBottom = 10
        case 3:
            fontSize = 20
            fontWeight = .semibold
            paddingBottom = 8
        case 4:
            fontSize = 18
            fontWeight = .semibold
            paddingBottom = 6
        case 5:
            fontSize = 16
            fontWeight = .medium
            paddingBottom = 4
        default:
            fontSize = 16
            fontWeight = .regular
            paddingBottom = 4
        }
        
        return Text(processedText)
            .font(.system(size: fontSize, weight: fontWeight, design: .serif))
            .foregroundColor(Color(red: 0.5, green: 0.1, blue: 0.1))
            .padding(.bottom, paddingBottom)
            .padding(.top, level == 1 ? 8 : 4)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    // 渲染无序列表
    private func renderUnorderedList(_ text: String) -> some View {
        let items = text.components(separatedBy: "\n")
        
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(items, id: \.self) { item in
                if item.hasPrefix("- ") || item.hasPrefix("* ") {
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.5, green: 0.2, blue: 0.1))
                        
                        let itemText = item.replacingOccurrences(of: "^[\\-\\*]\\s+", with: "", options: .regularExpression)
                        Text(processInlineMarkdown(itemText))
                            .font(.system(size: 16, design: .serif))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    // 渲染有序列表
    private func renderOrderedList(_ text: String) -> some View {
        let items = text.components(separatedBy: "\n")
        
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.element) { index, item in
                if item.match(pattern: "^\\d+\\.\\s") {
                    HStack(alignment: .top, spacing: 8) {
                        // 提取列表项的编号
                        let numberMatch = item.matchGroups(pattern: "^(\\d+)\\.")
                        let number = numberMatch.count > 1 ? numberMatch[1] : "\(index + 1)"
                        
                        Text("\(number).")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.5, green: 0.2, blue: 0.1))
                            .frame(width: 20, alignment: .trailing)
                        
                        let itemText = item.replacingOccurrences(of: "^\\d+\\.\\s+", with: "", options: .regularExpression)
                        Text(processInlineMarkdown(itemText))
                            .font(.system(size: 16, design: .serif))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    // 渲染段落
    private func renderParagraph(_ text: String) -> some View {
        Text(processInlineMarkdown(text))
            .font(.system(size: 16, design: .serif))
            .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    // 处理行内Markdown格式
    private func processInlineMarkdown(_ text: String) -> AttributedString {
        do {
            var options = AttributedString.MarkdownParsingOptions()
            options.interpretedSyntax = .inlineOnlyPreservingWhitespace
            
            let attributedString = try AttributedString(markdown: text, options: options)
            return attributedString
        } catch {
            return AttributedString(text)
        }
    }
}

// 字符串扩展，用于正则表达式匹配
extension String {
    func match(pattern: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: self.utf16.count)
            return regex.firstMatch(in: self, options: [], range: range) != nil
        } catch {
            return false
        }
    }
    
    func matchGroups(pattern: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: self.utf16.count)
            if let match = regex.firstMatch(in: self, options: [], range: range) {
                var results: [String] = []
                for i in 0..<match.numberOfRanges {
                    if let range = Range(match.range(at: i), in: self) {
                        results.append(String(self[range]))
                    } else {
                        results.append("")
                    }
                }
                return results
            }
        } catch {
            // 忽略错误
        }
        return []
    }
}

// 设置视图
struct SettingsView: View {
    @ObservedObject var viewModel: DivinationViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景色 - 淡黄色背景，类似古纸
                Color(red: 0.98, green: 0.95, blue: 0.85)
                    .edgesIgnoringSafeArea(.all)
                
                Form {
                    // Section(header: Text("API设置").foregroundColor(Color(red: 0.6, green: 0.1, blue: 0.1))) {
                    //     SecureField("DeepSeek API Key", text: $viewModel.apiKeyInput)
                    //     Button("保存") {
                    //         viewModel.saveAPIKey()
                    //         presentationMode.wrappedValue.dismiss()
                    //     }
                    //     .foregroundColor(Color(red: 0.7, green: 0.2, blue: 0.1))
                    //     .disabled(viewModel.apiKeyInput.isEmpty)
                    // }
                    
                    Section(header: Text("关于").foregroundColor(Color(red: 0.6, green: 0.1, blue: 0.1))) {
                        Text("梅花易数是中国传统的占卜方法之一，通过卦象解读来回答问题。八字是根据出生日期和时间推算的命理学方法，用于分析个人性格、事业、财运等。")
                            .font(.system(size: 14, design: .serif))
                        Text("本应用使用DeepSeek AI进行卦象解读。")
                            .font(.system(size: 14, design: .serif))
                    }
                    Section(header: Text("专业服务").foregroundColor(Color(red: 0.6, green: 0.1, blue: 0.1))) {
                        Text("如需更专业的八字命理分析服务，请联系:")
                            .font(.system(size: 14, design: .serif))
                        Text("victor.long.cheng@gmail.com")
                            .font(.system(size: 14, design: .serif))
                            .foregroundColor(.blue)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color(red: 0.7, green: 0.2, blue: 0.1))
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
