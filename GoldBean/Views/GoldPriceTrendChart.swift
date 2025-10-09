import SwiftUI

struct GoldPriceTrendChart: View {
    @EnvironmentObject var goldPriceService: GoldPriceService
    @State private var selectedTimeRange: ChartTimeRange = .sixMonths
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题和时间范围选择器
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(.orange)
                Text("金价趋势")
                    .font(.headline)
                Spacer()
                
                if goldPriceService.isLoadingHistory {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // 时间范围选择器
            TimeRangeSelector(selectedRange: $selectedTimeRange)
                .onChange(of: selectedTimeRange) { newRange in
                    goldPriceService.fetchPriceHistory(timeRange: newRange)
                }
            
            // 趋势指标
            if goldPriceService.trendIndicators.currentPrice > 0 {
                TrendIndicatorsView(indicators: goldPriceService.trendIndicators)
            }
            
            // 数据源指示器
            DataSourceIndicatorView(priceHistory: goldPriceService.getPriceHistory(for: selectedTimeRange))
            
            // 趋势图表
            let historyData = goldPriceService.getPriceHistory(for: selectedTimeRange)
            
            if historyData.isEmpty && !goldPriceService.isLoadingHistory {
                EmptyChartView()
            } else if !historyData.isEmpty {
                PriceChart(priceHistory: historyData, timeRange: selectedTimeRange)
                    .frame(height: 200)
            } else {
                LoadingChartView()
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            // 首次加载默认时间范围的数据
            goldPriceService.fetchPriceHistory(timeRange: selectedTimeRange)
        }
    }
}

// 时间范围选择器
struct TimeRangeSelector: View {
    @Binding var selectedRange: ChartTimeRange
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(ChartTimeRange.allCases, id: \.self) { range in
                Button(action: {
                    selectedRange = range
                }) {
                    Text(range.displayName)
                        .font(.caption)
                        .fontWeight(selectedRange == range ? .semibold : .regular)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            selectedRange == range ? 
                            Color.orange.opacity(0.2) : 
                            Color(.systemGray6)
                        )
                        .foregroundColor(
                            selectedRange == range ? .orange : .secondary
                        )
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// 趋势指标显示
struct TrendIndicatorsView: View {
    let indicators: TrendIndicators
    
    var body: some View {
        HStack(spacing: 16) {
            IndicatorItem(
                title: "最高", 
                value: indicators.highestPrice, 
                format: "%.2f", 
                unit: "¥"
            )
            
            IndicatorItem(
                title: "最低", 
                value: indicators.lowestPrice, 
                format: "%.2f", 
                unit: "¥"
            )
            
            IndicatorItem(
                title: "涨跌", 
                value: indicators.priceChangePercentage, 
                format: "%.2f", 
                unit: "%",
                color: indicators.priceChange >= 0 ? .green : .red
            )
        }
    }
}

// 指标项组件
struct IndicatorItem: View {
    let title: String
    let value: Double
    let format: String
    let unit: String
    let color: Color
    
    init(title: String, value: Double, format: String, unit: String = "", color: Color = .primary) {
        self.title = title
        self.value = value
        self.format = format
        self.unit = unit
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            HStack(spacing: 2) {
                if unit == "¥" {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(color)
                }
                
                Text(String(format: format, value))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
                
                if unit == "%" {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(color)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// 价格图表（简化版本，不依赖Charts框架）
struct PriceChart: View {
    let priceHistory: [GoldPriceHistory]
    let timeRange: ChartTimeRange
    
    var body: some View {
        GeometryReader { geometry in
            let chartArea = CGRect(
                x: 40, // 左边距为Y轴标签留空间
                y: 10, // 上边距
                width: geometry.size.width - 90, // 减去左右边距，为当前价格标签留空间
                height: geometry.size.height - 40 // 减去上下边距，为X轴标签留空间
            )
            
            ZStack {
                // 背景
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                
                if !priceHistory.isEmpty {
                    // 网格线
                    GridLinesView(priceHistory: priceHistory, chartArea: chartArea, timeRange: timeRange)
                    
                    // Y轴标签
                    YAxisLabelsView(priceHistory: priceHistory, chartArea: chartArea)
                    
                    // X轴标签
                    XAxisLabelsView(priceHistory: priceHistory, chartArea: chartArea, timeRange: timeRange)
                    
                    // 当前价格参考线（暂时禁用）
                    // CurrentPriceReferenceLineView(...)
                    
                    // 绘制价格线（使用新的绘制区域）
                    PriceLineShape(priceHistory: priceHistory, chartArea: chartArea)
                        .stroke(Color.orange, lineWidth: 2)
                        .background(
                            PriceAreaShape(priceHistory: priceHistory, chartArea: chartArea)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                    
                    // 价格数据点
                    PricePointsView(priceHistory: priceHistory, chartArea: chartArea)
                }
                
                // 如果没有数据显示占位符
                if priceHistory.isEmpty {
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("暂无图表数据")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(8)
    }
}

// 网格线视图
struct GridLinesView: View {
    let priceHistory: [GoldPriceHistory]
    let chartArea: CGRect
    let timeRange: ChartTimeRange
    
    var body: some View {
        ZStack {
            // 水平网格线（Y轴）
            ForEach(0..<5, id: \.self) { i in
                let y = chartArea.minY + CGFloat(i) * chartArea.height / 4
                Path { path in
                    path.move(to: CGPoint(x: chartArea.minX, y: y))
                    path.addLine(to: CGPoint(x: chartArea.maxX, y: y))
                }
                .stroke(Color(.systemGray5), lineWidth: 0.5)
            }
            
            // 垂直网格线（X轴）- 根据时间范围调整
            let verticalLines = getVerticalLineCount()
            ForEach(0..<verticalLines, id: \.self) { i in
                let x = chartArea.minX + CGFloat(i) * chartArea.width / CGFloat(verticalLines - 1)
                Path { path in
                    path.move(to: CGPoint(x: x, y: chartArea.minY))
                    path.addLine(to: CGPoint(x: x, y: chartArea.maxY))
                }
                .stroke(Color(.systemGray5), lineWidth: 0.5)
            }
        }
    }
    
    private func getVerticalLineCount() -> Int {
        switch timeRange {
        case .sixMonths: return 7
        case .oneYear: return 6
        case .threeYears: return 4
        case .fiveYears: return 6
        case .tenYears: return 6
        }
    }
}

// Y轴标签视图
struct YAxisLabelsView: View {
    let priceHistory: [GoldPriceHistory]
    let chartArea: CGRect
    
    var body: some View {
        let prices = priceHistory.map { $0.price }
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 0
        let priceRange = maxPrice - minPrice
        
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                let price = maxPrice - (Double(i) * priceRange / 4)
                let y = chartArea.minY + CGFloat(i) * chartArea.height / 4
                
                HStack(spacing: 2) {
                    Text("¥")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                    Text(String(format: "%.0f", price))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
                .position(x: 25, y: y)
            }
            
            // Y轴线
            Path { path in
                path.move(to: CGPoint(x: chartArea.minX, y: chartArea.minY))
                path.addLine(to: CGPoint(x: chartArea.minX, y: chartArea.maxY))
            }
            .stroke(Color(.systemGray4), lineWidth: 1)
        }
    }
}

// X轴标签视图
struct XAxisLabelsView: View {
    let priceHistory: [GoldPriceHistory]
    let chartArea: CGRect
    let timeRange: ChartTimeRange
    
    var body: some View {
        let labelCount = getVerticalLineCount()
        let dateFormatter = getDateFormatter()
        
        ZStack {
            ForEach(0..<labelCount, id: \.self) { i in
                let dataIndex = Int(Double(i) * Double(priceHistory.count - 1) / Double(labelCount - 1))
                let x = chartArea.minX + CGFloat(i) * chartArea.width / CGFloat(labelCount - 1)
                
                if dataIndex < priceHistory.count {
                    let date = priceHistory[dataIndex].date
                    Text(dateFormatter.string(from: date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                        .position(x: x, y: chartArea.maxY + 20)
                }
            }
            
            // X轴线
            Path { path in
                path.move(to: CGPoint(x: chartArea.minX, y: chartArea.maxY))
                path.addLine(to: CGPoint(x: chartArea.maxX, y: chartArea.maxY))
            }
            .stroke(Color(.systemGray4), lineWidth: 1)
        }
    }
    
    private func getVerticalLineCount() -> Int {
        switch timeRange {
        case .sixMonths: return 7
        case .oneYear: return 6
        case .threeYears: return 4
        case .fiveYears: return 6
        case .tenYears: return 6
        }
    }
    
    private func getDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        switch timeRange {
        case .sixMonths:
            formatter.dateFormat = "M月"
        case .oneYear:
            formatter.dateFormat = "M月"
        case .threeYears:
            formatter.dateFormat = "yyyy"
        case .fiveYears:
            formatter.dateFormat = "yyyy"
        case .tenYears:
            formatter.dateFormat = "yyyy"
        }
        return formatter
    }
}

// 价格线形状
struct PriceLineShape: Shape {
    let priceHistory: [GoldPriceHistory]
    let chartArea: CGRect
    
    func path(in rect: CGRect) -> Path {
        guard !priceHistory.isEmpty else { return Path() }
        
        let prices = priceHistory.map { $0.price }
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 0
        let priceRange = maxPrice - minPrice
        
        guard priceRange > 0 else { return Path() }
        
        var path = Path()
        let stepX = chartArea.width / CGFloat(priceHistory.count - 1)
        
        for (index, item) in priceHistory.enumerated() {
            let x = chartArea.minX + CGFloat(index) * stepX
            let normalizedPrice = (item.price - minPrice) / priceRange
            let y = chartArea.maxY - normalizedPrice * chartArea.height
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
}

// 价格区域形状（用于渐变背景）
struct PriceAreaShape: Shape {
    let priceHistory: [GoldPriceHistory]
    let chartArea: CGRect
    
    func path(in rect: CGRect) -> Path {
        guard !priceHistory.isEmpty else { return Path() }
        
        let prices = priceHistory.map { $0.price }
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 0
        let priceRange = maxPrice - minPrice
        
        guard priceRange > 0 else { return Path() }
        
        var path = Path()
        let stepX = chartArea.width / CGFloat(priceHistory.count - 1)
        
        // 开始从底部左侧
        path.move(to: CGPoint(x: chartArea.minX, y: chartArea.maxY))
        
        // 绘制价格线
        for (index, item) in priceHistory.enumerated() {
            let x = chartArea.minX + CGFloat(index) * stepX
            let normalizedPrice = (item.price - minPrice) / priceRange
            let y = chartArea.maxY - normalizedPrice * chartArea.height
            
            if index == 0 {
                path.addLine(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        // 回到底部右侧，闭合路径
        let lastX = chartArea.minX + CGFloat(priceHistory.count - 1) * stepX
        path.addLine(to: CGPoint(x: lastX, y: chartArea.maxY))
        path.closeSubpath()
        
        return path
    }
}

// 当前价格参考线视图
struct CurrentPriceReferenceLineView: View {
    let priceHistory: [GoldPriceHistory]
    let chartArea: CGRect
    let currentPrice: Double
    
    var body: some View {
        let prices = priceHistory.map { $0.price }
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 0
        let priceRange = maxPrice - minPrice
        
        if priceRange > 0 && currentPrice > 0 && 
           currentPrice >= minPrice && currentPrice <= maxPrice {
            
            let normalizedPrice = (currentPrice - minPrice) / priceRange
            let y = chartArea.maxY - normalizedPrice * chartArea.height
            
            ZStack {
                // 虚线参考线
                Path { path in
                    path.move(to: CGPoint(x: chartArea.minX, y: y))
                    path.addLine(to: CGPoint(x: chartArea.maxX, y: y))
                }
                .stroke(Color.blue.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                
                // 当前价格标签
                HStack(spacing: 2) {
                    Text("当前")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("¥\(String(format: "%.0f", currentPrice))")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
                .position(x: chartArea.maxX + 25, y: y)
            }
        }
    }
}

// 价格数据点视图
struct PricePointsView: View {
    let priceHistory: [GoldPriceHistory]
    let chartArea: CGRect
    
    var body: some View {
        let prices = priceHistory.map { $0.price }
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 0
        let priceRange = maxPrice - minPrice
        
        if priceRange > 0 {
            let stepX = chartArea.width / CGFloat(priceHistory.count - 1)
            
            ZStack {
                // 只在数据点较少时显示圆点
                if priceHistory.count <= 30 {
                    ForEach(Array(priceHistory.enumerated()), id: \.offset) { index, item in
                        let x = chartArea.minX + CGFloat(index) * stepX
                        let normalizedPrice = (item.price - minPrice) / priceRange
                        let y = chartArea.maxY - normalizedPrice * chartArea.height
                        
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 4, height: 4)
                            .position(x: x, y: y)
                    }
                }
            }
        }
    }
}



// 数据源指示器
struct DataSourceIndicatorView: View {
    let priceHistory: [GoldPriceHistory]
    
    var body: some View {
        if let firstRecord = priceHistory.first {
            HStack(spacing: 4) {
                Circle()
                    .fill(getSourceColor(for: firstRecord.source))
                    .frame(width: 6, height: 6)
                Text("数据来源: \(firstRecord.source)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }
    
    private func getSourceColor(for source: String) -> Color {
        switch source {
        case "基于真实金价的历史数据":
            return .green
        case "ExchangeRate", "Coinbase":
            return .blue
        case "模拟数据", "示例数据":
            return .orange
        default:
            return .gray
        }
    }
}

// 空状态视图
struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("暂无历史数据")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 加载状态视图
struct LoadingChartView: View {
    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text("正在加载趋势数据...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    GoldPriceTrendChart()
        .environmentObject(GoldPriceService.shared)
        .padding()
} 