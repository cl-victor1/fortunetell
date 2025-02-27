import SwiftUI

struct BaziView: View {
    @StateObject private var viewModel = BaziViewModel()
    @State private var showDatePicker = false
    
    var body: some View {
        ZStack {
            // 背景色 - 淡黄色背景，类似古纸
            Color(red: 0.98, green: 0.95, blue: 0.85)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // 顶部标题
                Text("生辰八字")
                    .font(.system(size: 36, weight: .bold, design: .serif))
                    .foregroundColor(Color(red: 0.6, green: 0.1, blue: 0.1)) // 暗红色，传统中国色
                    .padding(.top)
                
                // 副标题
                Text("传统中华命理学")
                    .font(.system(size: 16, design: .serif))
                    .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.1))
                    .padding(.bottom, 10)
                
                // 出生日期选择
                VStack(alignment: .leading) {
                    Text("选择出生日期和时间:")
                        .font(.headline)
                        .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.1))
                    
                    Button(action: {
                        showDatePicker = true
                    }) {
                        HStack {
                            Text(formatDate(viewModel.baziModel.birthDate))
                                .foregroundColor(.black)
                            Spacer()
                            Image(systemName: "calendar")
                                .foregroundColor(Color(red: 0.6, green: 0.3, blue: 0.1))
                        }
                        .padding()
                        .background(Color(white: 1, opacity: 0.7))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 0.6, green: 0.3, blue: 0.1), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)
                
                // 性别选择
                VStack(alignment: .leading) {
                    Text("选择性别:")
                        .font(.headline)
                        .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.1))
                    
                    Picker("性别", selection: $viewModel.baziModel.gender) {
                        ForEach(BaziModel.Gender.allCases) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.vertical, 5)
                }
                .padding(.horizontal)
                
                // 解读按钮
                Button(action: {
                    // 先设置isLoading为true
                    viewModel.baziModel.isLoading = true
                    
                    // 使用主线程延迟启动异步任务，确保UI先更新
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        Task {
                            await viewModel.performBaziAnalysis()
                        }
                    }
                }) {
                    Text("开始解读")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.7, green: 0.2, blue: 0.1))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(viewModel.baziModel.isLoading)
                
                // 加载指示器
                if viewModel.baziModel.isLoading {
                    ProgressView("正在解读八字...")
                        .padding()
                }
                
                // 结果区域
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        if !viewModel.baziModel.fullBazi.isEmpty {
                            // 八字结果
                            BaziResultView(
                                yearPillar: viewModel.baziModel.yearPillar,
                                monthPillar: viewModel.baziModel.monthPillar,
                                dayPillar: viewModel.baziModel.dayPillar,
                                hourPillar: viewModel.baziModel.hourPillar
                            )
                        }
                        
                        if !viewModel.baziModel.interpretation.isEmpty {
                            ResultSectionView(title: "八字解读", content: viewModel.baziModel.interpretation)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerView(selectedDate: $viewModel.baziModel.birthDate, isPresented: $showDatePicker)
            }
        }
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}

// 八字结果视图
struct BaziResultView: View {
    let yearPillar: String
    let monthPillar: String
    let dayPillar: String
    let hourPillar: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("您的八字")
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundColor(Color(red: 0.6, green: 0.1, blue: 0.1))
            
            HStack(spacing: 20) {
                PillarView(title: "年柱", content: yearPillar)
                PillarView(title: "月柱", content: monthPillar)
                PillarView(title: "日柱", content: dayPillar)
                PillarView(title: "时柱", content: hourPillar)
            }
            .padding(.vertical, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 1, opacity: 0.7))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 0.6, green: 0.3, blue: 0.1), lineWidth: 1)
        )
    }
}

// 单个天干地支柱视图
struct PillarView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.system(size: 14, design: .serif))
                .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.1))
            
            Text(content)
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundColor(Color(red: 0.7, green: 0.2, blue: 0.1))
        }
        .frame(minWidth: 60)
    }
}

// 日期选择器视图
struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
    // 年、月、日、时、分的状态
    @State private var year: Int
    @State private var month: Int
    @State private var day: Int
    @State private var hour: Int
    @State private var minute: Int
    
    // 可选择的年份范围
    let years = Array(1900...2100)
    let months = Array(1...12)
    let hours = Array(0...23)
    let minutes = [0, 15, 30, 45]
    
    // 初始化器
    init(selectedDate: Binding<Date>, isPresented: Binding<Bool>) {
        self._selectedDate = selectedDate
        self._isPresented = isPresented
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: selectedDate.wrappedValue)
        
        self._year = State(initialValue: components.year ?? 2000)
        self._month = State(initialValue: components.month ?? 1)
        self._day = State(initialValue: components.day ?? 1)
        self._hour = State(initialValue: components.hour ?? 12)
        self._minute = State(initialValue: 0) // 总是默认为0分钟
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景色
                Color(red: 0.98, green: 0.95, blue: 0.85)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // 年份选择器
                    HStack {
                        Text("年份:")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.1))
                            .frame(width: 60, alignment: .leading)
                        
                        Picker("年份", selection: $year) {
                            ForEach(years, id: \.self) { year in
                                Text("\(year)年").tag(year)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 100)
                        .clipped()
                    }
                    .padding(.horizontal)
                    
                    // 月份选择器
                    HStack {
                        Text("月份:")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.1))
                            .frame(width: 60, alignment: .leading)
                        
                        Picker("月份", selection: $month) {
                            ForEach(months, id: \.self) { month in
                                Text("\(month)月").tag(month)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 100)
                        .clipped()
                        .onChange(of: month) { _ in
                            validateDay()
                        }
                        .onChange(of: year) { _ in
                            validateDay()
                        }
                    }
                    .padding(.horizontal)
                    
                    // 日期选择器
                    HStack {
                        Text("日期:")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.1))
                            .frame(width: 60, alignment: .leading)
                        
                        Picker("日期", selection: $day) {
                            ForEach(1...daysInMonth(year: year, month: month), id: \.self) { day in
                                Text("\(day)日").tag(day)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 100)
                        .clipped()
                    }
                    .padding(.horizontal)
                    
                    // 时间选择器
                    HStack {
                        Text("时间:")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.1))
                            .frame(width: 60, alignment: .leading)
                        
                        Picker("小时", selection: $hour) {
                            ForEach(hours, id: \.self) { hour in
                                Text("\(hour)时").tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 100)
                        .clipped()
                        
                        VStack {
                            Picker("分钟", selection: $minute) {
                                ForEach(minutes, id: \.self) { minute in
                                    Text(minute == 0 ? "\(minute)分（默认）" : "\(minute)分").tag(minute)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(height: 80)
                            .clipped()
                            
                            Button(action: {
                                minute = 0
                            }) {
                                Text("重置为0分")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 0.7, green: 0.2, blue: 0.1))
                            }
                            .padding(.top, 2)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 确认按钮
                    Button(action: {
                        updateSelectedDate()
                        isPresented = false
                    }) {
                        Text("确认")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 0.7, green: 0.2, blue: 0.1))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
                .padding(.vertical)
            }
            .navigationBarTitle("选择出生日期和时间", displayMode: .inline)
            .navigationBarItems(trailing: Button("取消") {
                isPresented = false
            })
        }
    }
    
    // 验证日期是否有效
    private func validateDay() {
        let maxDay = daysInMonth(year: year, month: month)
        if day > maxDay {
            day = maxDay
        }
    }
    
    // 计算指定年月的天数
    private func daysInMonth(year: Int, month: Int) -> Int {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        
        // 获取下个月的第一天，然后减去一天，就是当月的最后一天
        components.day = 1
        if let date = calendar.date(from: components) {
            if let nextMonth = calendar.date(byAdding: .month, value: 1, to: date) {
                if let lastDay = calendar.date(byAdding: .day, value: -1, to: nextMonth) {
                    return calendar.component(.day, from: lastDay)
                }
            }
        }
        
        // 默认返回31天
        return 31
    }
    
    // 更新选中的日期
    private func updateSelectedDate() {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        
        if let date = Calendar.current.date(from: components) {
            selectedDate = date
        }
    }
}

#Preview {
    BaziView()
} 