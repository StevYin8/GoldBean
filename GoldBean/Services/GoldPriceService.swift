import Foundation
import Combine

// MARK: - 黄金价格服务
class GoldPriceService: ObservableObject {
    static let shared = GoldPriceService()
    
    @Published var currentPrice: Double = 0.0 // 初始化为0，表示无数据
    @Published var lastUpdated: Date = Date()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var priceSource: String = "" 
    @Published var hasValidData: Bool = false // 新增：标识是否有有效数据
    
    // 趋势图相关数据
    @Published var priceHistory: [GoldPriceHistory] = []
    @Published var isLoadingHistory: Bool = false
    @Published var trendIndicators: TrendIndicators = .empty
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    // Supabase 服务实例
    private let supabaseService = SupabaseGoldService.shared
    
    // 中国金价数据源 - 中国黄金集团官网（无需API Key）
    private let chinaGoldOfficialURL = "https://www.chnau99999.com/page/goldPrice"
    
    init() {
        // 设置默认使用真实数据（仅首次启动）
        if !userDefaults.bool(forKey: "hasLaunchedBefore") {
            userDefaults.set(true, forKey: "useRealData")
            userDefaults.set(true, forKey: "hasLaunchedBefore")
        }
        
        loadCachedPrice()
        loadCachedPriceHistory()
        // 智能更新：只在今日未更新时自动获取
        checkAndAutoUpdatePrice()
        
        // 如果没有历史数据，生成默认的示例数据
        if priceHistory.isEmpty {
            generateInitialMockData()
        }
    }
    
    // 从本地缓存加载价格
    private func loadCachedPrice() {
        if let cachedPrice = userDefaults.object(forKey: "lastGoldPrice") as? Double,
           let cachedDate = userDefaults.object(forKey: "lastGoldPriceDate") as? Date,
           let cachedSource = userDefaults.string(forKey: "lastGoldPriceSource"),
           cachedPrice > 0 { // 确保缓存的价格是有效的
            self.currentPrice = cachedPrice
            self.lastUpdated = cachedDate
            self.priceSource = cachedSource
            self.hasValidData = true
            print("✅ 加载缓存价格: ¥\(String(format: "%.2f", cachedPrice))/克")
        } else {
            self.hasValidData = false
            self.priceSource = "无数据"
            print("⚠️ 无有效缓存数据")
        }
    }
    
    // 缓存价格到本地
    private func cachePrice(_ price: Double, date: Date, source: String) {
        userDefaults.set(price, forKey: "lastGoldPrice")
        userDefaults.set(date, forKey: "lastGoldPriceDate")
        userDefaults.set(source, forKey: "lastGoldPriceSource")
    }
    
    // 检查今日是否已更新
    private func isTodayUpdated() -> Bool {
        let calendar = Calendar.current
        let today = Date()
        return calendar.isDate(lastUpdated, inSameDayAs: today)
    }
    
    // 智能更新检查
    private func checkAndAutoUpdatePrice() {
        if !hasValidData {
            print("❌ 无缓存数据，自动尝试获取金价...")
            fetchGoldPrice(isAutoUpdate: true)
        } else if !isTodayUpdated() {
            print("📅 今日尚未更新金价，但有缓存数据，开始自动更新...")
            fetchGoldPrice(isAutoUpdate: true)
        } else {
            print("✅ 今日金价已更新，使用缓存数据")
        }
    }
    
    // 获取黄金价格（支持手动和自动更新）
    func fetchGoldPrice(isAutoUpdate: Bool = false) {
        // 如果是手动刷新且今日已更新，询问用户确认
        if !isAutoUpdate && isTodayUpdated() && hasValidData {
            // 这里可以设置一个状态，让UI显示确认对话框
            errorMessage = "今日已更新，确认重新获取？"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        print("🔄 开始获取金价... (自动更新: \(isAutoUpdate))")
        
        // 直接从中国黄金集团官网获取金价
        fetchChineseGoldPrice()
            .catch { [weak self] error -> AnyPublisher<Void, Never> in
                print("⚠️ 中国黄金集团官网获取失败: \(error.localizedDescription)")
                self?.handleAPIFailure()
                return Just(()).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }
    
    // 强制刷新价格（用户确认后）
    func forceRefreshPrice() {
        isLoading = true
        errorMessage = ""
        print("🔄 强制刷新金价...")
        
        // 直接从中国黄金集团官网获取金价
        fetchChineseGoldPrice()
            .catch { [weak self] error -> AnyPublisher<Void, Never> in
                print("⚠️ 中国黄金集团官网获取失败: \(error.localizedDescription)")
                self?.handleAPIFailure()
                return Just(()).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }
    
    // 获取中国金价（中国黄金集团官网 - 真实数据）
    private func fetchChineseGoldPrice() -> AnyPublisher<Void, Error> {
        guard let url = URL(string: chinaGoldOfficialURL) else {
            return Fail(error: NSError(domain: "URLError", code: 0, 
                                      userInfo: [NSLocalizedDescriptionKey: "无效的URL"]))
                .eraseToAnyPublisher()
        }
        
        print("🔄 正在从中国黄金集团官网获取实时金价...")
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 15.0
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15", 
                        forHTTPHeaderField: "User-Agent")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Double in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "ResponseError", code: 0)
                }
                
                print("📡 HTTP状态码: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    throw NSError(domain: "HTTPError", code: httpResponse.statusCode)
                }
                
                guard let html = String(data: data, encoding: .utf8) else {
                    throw NSError(domain: "EncodingError", code: 0)
                }
                
                // 解析HTML，提取金价数据
                // 查找: <i class="num" id="cur">913.30</i>元/克
                let price = try self.parseGoldPriceFromHTML(html)
                
                print("✅ 成功获取中国黄金集团官网金价: ¥\(String(format: "%.2f", price))/克")
                print("📊 数据来源: 中国黄金集团官网")
                
                return price
            }
            .receive(on: DispatchQueue.main)
            .map { [weak self] price -> Void in
                self?.updatePrice(priceCNY: price, source: "中国黄金集团")
            }
            .eraseToAnyPublisher()
    }
    
    // 解析HTML页面中的金价
    private func parseGoldPriceFromHTML(_ html: String) throws -> Double {
        // 方法1: 查找 id="cur" 的元素
        if let range = html.range(of: #"<i class="num" id="cur">([0-9.]+)</i>"#, 
                                  options: .regularExpression) {
            let match = html[range]
            if let priceRange = match.range(of: #"[0-9.]+"#, options: .regularExpression) {
                let priceStr = String(match[priceRange])
                if let price = Double(priceStr) {
                    return price
                }
            }
        }
        
        // 方法2: 查找 "中金实时基础金价：" 后面的数字
        let patterns = [
            #"中金实时基础金价：[^0-9]*([0-9]+\.?[0-9]*)"#,
            #"<i class="num"[^>]*>([0-9]+\.?[0-9]*)</i>"#,
            #"基础金价[：:][^0-9]*([0-9]+\.?[0-9]*)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               match.numberOfRanges > 1 {
                let priceRange = match.range(at: 1)
                if let swiftRange = Range(priceRange, in: html) {
                    let priceStr = String(html[swiftRange])
                    if let price = Double(priceStr), price > 0 {
                        print("📍 使用正则表达式成功提取金价: \(price)")
                        return price
                    }
                }
            }
        }
        
        throw NSError(domain: "ParseError", code: 0, 
                     userInfo: [NSLocalizedDescriptionKey: "无法从HTML中解析金价数据"])
    }
    
    
    // 处理API获取失败的情况
    private func handleAPIFailure() {
        self.isLoading = false
        
        if hasValidData {
            // 有缓存数据，继续使用
            self.errorMessage = "中国黄金集团官网连接超时，显示缓存数据。建议检查网络后重试"
            print("⚠️ 官网获取失败，使用缓存数据: ¥\(String(format: "%.2f", currentPrice))/克")
        } else {
            // 无缓存数据，提示用户
            self.errorMessage = "网络连接失败，无法获取金价。请检查网络设置后重试"
            self.currentPrice = 0.0
            self.priceSource = "网络异常"
            print("❌ 官网获取失败且无缓存数据")
        }
    }
    
    private func updatePrice(priceCNY: Double, source: String) {
        // 传入的priceCNY已经是每克人民币价格，无需再次转换
        self.currentPrice = priceCNY
        self.lastUpdated = Date()
        self.isLoading = false
        self.errorMessage = nil
        self.priceSource = source
        self.hasValidData = true
        
        self.cachePrice(priceCNY, date: Date(), source: source)
        print("✅ 金价更新成功: ¥\(String(format: "%.2f", priceCNY))/克 来源: \(source)")
    }
    
    // 格式化价格显示
    func formattedPrice() -> String {
        if hasValidData && currentPrice > 0 {
            return String(format: "¥%.2f/克", currentPrice)
        } else {
            return "暂无数据"
        }
    }
    
    // 格式化更新时间
    func formattedLastUpdated() -> String {
        if isLoading {
            return "正在获取金价数据..."
        } else if hasValidData {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd HH:mm"
            return formatter.string(from: lastUpdated) + " (\(priceSource))"
        } else {
            return "稍后可手动刷新获取数据"
        }
    }
    
    // 获取今日更新状态
    func getTodayUpdateStatus() -> String {
        if !hasValidData {
            return "无数据"
        } else if isTodayUpdated() {
            return "今日已更新"
        } else {
            return "今日未更新"
        }
    }
    
    // 检查是否可以手动刷新
    func canManualRefresh() -> Bool {
        return !isLoading
    }
    
    // 获取刷新按钮提示文本
    func getRefreshButtonText() -> String {
        if isLoading {
            return "更新中..."
        } else if !hasValidData {
            return "获取金价"
        } else if isTodayUpdated() {
            return "重新获取"
        } else {
            return "刷新价格"
        }
    }
    
    
    // MARK: - 历史价格数据管理
    
    // 加载缓存的历史价格数据
    private func loadCachedPriceHistory() {
        if let data = userDefaults.data(forKey: "cachedPriceHistory"),
           let cachedHistory = try? JSONDecoder().decode([GoldPriceHistory].self, from: data) {
            self.priceHistory = cachedHistory
            print("✅ 加载缓存历史价格数据: \(cachedHistory.count) 条记录")
        } else {
            print("⚠️ 无历史价格缓存数据")
        }
    }
    
    // 获取缓存的历史价格数据（返回数组）
    private func getCachedPriceHistory() -> [GoldPriceHistory] {
        if let data = userDefaults.data(forKey: "cachedPriceHistory"),
           let cachedHistory = try? JSONDecoder().decode([GoldPriceHistory].self, from: data) {
            return cachedHistory
        }
        return []
    }
    
    // 缓存历史价格数据
    private func cachePriceHistory(_ history: [GoldPriceHistory]) {
        if let data = try? JSONEncoder().encode(history) {
            userDefaults.set(data, forKey: "cachedPriceHistory")
            print("✅ 缓存历史价格数据: \(history.count) 条记录")
        }
    }
    
    // 获取指定时间范围的历史价格数据
    func fetchPriceHistory(timeRange: ChartTimeRange) {
        isLoadingHistory = true
        print("🔄 开始获取 \(timeRange.displayName) 历史价格数据...")
        
        // 先使用缓存数据更新UI
        updateTrendIndicators(for: timeRange)
        
        // 尝试获取真实历史数据
        fetchRealHistoryData(timeRange: timeRange)
    }
    
    // 获取真实历史数据（仅从 Supabase 获取）
    private func fetchRealHistoryData(timeRange: ChartTimeRange) {
        
        // 检查用户是否选择使用真实数据
        let useRealData = userDefaults.bool(forKey: "useRealData")
        
        if !useRealData {
            // 用户选择使用模拟数据
            print("📝 用户选择使用模拟数据")
            let mockHistory = generateMockHistory(timeRange: timeRange)
            DispatchQueue.main.async { [weak self] in
                self?.priceHistory = mockHistory
                self?.updateTrendIndicators(for: timeRange)
                self?.cachePriceHistory(mockHistory)
                self?.isLoadingHistory = false
                print("✅ 模拟历史数据生成完成: \(mockHistory.count) 条记录")
            }
            return
        }
        
        // 从 Supabase 获取真实历史数据
        print("📊 从 Supabase 获取真实历史数据...")
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -timeRange.days, to: endDate) ?? endDate
        
        supabaseService.fetchHistoricalPricesPublisher(startDate: startDate, endDate: endDate)
            .timeout(.seconds(30), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoadingHistory = false
                
                switch completion {
                case .finished:
                    print("✅ Supabase 数据获取流程完成")
                case .failure(let error):
                    print("❌ Supabase 获取失败: \(error.localizedDescription)")
                    // 清空数据并提示用户
                    self?.priceHistory = []
                    self?.errorMessage = "暂时无法获取历史数据，请稍后重试"
                }
            } receiveValue: { [weak self] history in
                guard let self = self else { return }
                
                if history.isEmpty {
                    print("⚠️ Supabase 数据库中暂无数据")
                    self.priceHistory = []
                    self.errorMessage = "历史数据暂时不可用，请稍后重试"
                } else {
                    print("✅ 成功获取 \(history.count) 条 Supabase 历史数据")
                    self.priceHistory = history
                    self.updateTrendIndicators(for: timeRange)
                    self.cachePriceHistory(history)
                    self.errorMessage = nil
                }
            }
            .store(in: &cancellables)
    }
    
    
    
    // 生成模拟历史数据
    private func generateMockHistory(timeRange: ChartTimeRange) -> [GoldPriceHistory] {
        let days = timeRange.days
        let basePrice = currentPrice > 0 ? currentPrice : 460.0 // 如果当前价格为0，使用默认基准价格
        var history: [GoldPriceHistory] = []
        
        let calendar = Calendar.current
        let endDate = Date()
        
        // 根据时间范围调整数据密度和波动幅度
        let dataInterval = max(1, days / 365) // 长期数据可以减少采样密度
        let trendAmplitude = getTrendAmplitude(for: timeRange)
        let randomAmplitude = getRandomAmplitude(for: timeRange)
        
        for i in stride(from: 0, to: days, by: dataInterval) {
            guard let date = calendar.date(byAdding: .day, value: -i, to: endDate) else { continue }
            
            // 生成波动价格（基于正弦波加随机波动）
            let dayIndex = Double(days - i)
            let cyclePeriod = getCyclePeriod(for: timeRange)
            let trend = sin(dayIndex * cyclePeriod) * trendAmplitude
            let randomVariation = Double.random(in: -randomAmplitude...randomAmplitude)
            let price = basePrice + trend + randomVariation
            
            history.append(GoldPriceHistory(
                date: date,
                price: max(300, price), // 确保价格不低于300（长期来看可能有更大波动）
                source: "模拟数据"
            ))
        }
        
        return history.sorted { $0.date < $1.date }
    }
    
    // 根据时间范围获取趋势波动幅度
    private func getTrendAmplitude(for timeRange: ChartTimeRange) -> Double {
        switch timeRange {
        case .sixMonths: return 10
        case .oneYear: return 15
        case .threeYears: return 30
        case .fiveYears: return 50
        // case .tenYears: return 80
        }
    }
    
    // 根据时间范围获取随机波动幅度
    private func getRandomAmplitude(for timeRange: ChartTimeRange) -> Double {
        switch timeRange {
        case .sixMonths: return 8
        case .oneYear: return 12
        case .threeYears: return 20
        case .fiveYears: return 25
        // case .tenYears: return 30
        }
    }
    
    // 根据时间范围获取周期参数
    private func getCyclePeriod(for timeRange: ChartTimeRange) -> Double {
        switch timeRange {
        case .sixMonths: return 0.1
        case .oneYear: return 0.05
        case .threeYears: return 0.02
        case .fiveYears: return 0.01
        // case .tenYears: return 0.005
        }
    }
    
    // 获取指定时间范围的数据
    func getPriceHistory(for timeRange: ChartTimeRange) -> [GoldPriceHistory] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -timeRange.days, to: endDate) else {
            return []
        }
        
        return priceHistory.filter { $0.date >= startDate && $0.date <= endDate }
    }
    
    // 计算趋势指标
    private func updateTrendIndicators(for timeRange: ChartTimeRange) {
        let historyData = getPriceHistory(for: timeRange)
        
        guard !historyData.isEmpty else {
            trendIndicators = .empty
            return
        }
        
        let prices = historyData.map { $0.price }
        let highestPrice = prices.max() ?? 0
        let lowestPrice = prices.min() ?? 0
        let averagePrice = prices.reduce(0, +) / Double(prices.count)
        
        let firstPrice = prices.first ?? 0
        let lastPrice = prices.last ?? currentPrice
        let priceChange = lastPrice - firstPrice
        let priceChangePercentage = firstPrice > 0 ? (priceChange / firstPrice) * 100 : 0
        
        trendIndicators = TrendIndicators(
            highestPrice: highestPrice,
            lowestPrice: lowestPrice,
            priceChange: priceChange,
            priceChangePercentage: priceChangePercentage,
            averagePrice: averagePrice,
            currentPrice: currentPrice
        )
    }
    
    // MARK: - 真实API数据获取
    // 注：移除了有问题的Yahoo Finance和Metals.live实现
    // 现在使用更可靠的汇率API获取当前金价基准
    
    // 基于真实当前价格生成历史数据（使用金融市场规律，不是随机波动）
    private func generateRealisticHistory(basePrice: Double, timeRange: ChartTimeRange, source: String) -> [GoldPriceHistory] {
        let days = timeRange.days
        var history: [GoldPriceHistory] = []
        
        let calendar = Calendar.current
        let endDate = Date()
        
        // 使用真实的金价历史走势模式
        let dataInterval = max(1, days / 1000) // 限制数据点数量
        
        // 根据历史数据，金价在不同时期有不同的增长趋势
        // 以当前价格为终点，向前推算合理的历史价格
        
        for i in stride(from: 0, to: days, by: dataInterval) {
            guard let date = calendar.date(byAdding: .day, value: -i, to: endDate) else { continue }
            
            // 计算距离当前的时间进度（0=很久以前，1=现在）
            let progress = 1.0 - (Double(i) / Double(days))
            
            // 基于真实金价趋势：长期上涨 + 周期性波动
            let longTermTrend = calculateLongTermTrend(progress: progress, timeRange: timeRange, currentPrice: basePrice)
            let cyclicalVariation = calculateCyclicalVariation(dayIndex: Double(days - i), timeRange: timeRange)
            
            let price = longTermTrend + cyclicalVariation
            
            history.append(GoldPriceHistory(
                date: date,
                price: max(400, price), // 确保价格合理（最低400元/克）
                source: source
            ))
        }
        
        return history.sorted { $0.date < $1.date }
    }
    
    // 计算长期趋势（基于真实金价的历史增长模式）
    private func calculateLongTermTrend(progress: Double, timeRange: ChartTimeRange, currentPrice: Double) -> Double {
        // 使用指数增长模型，符合金价长期上涨趋势
        let growthRate: Double
        switch timeRange {
        case .sixMonths:
            growthRate = 0.05  // 半年约5%增长
        case .oneYear:
            growthRate = 0.10  // 一年约10%增长
        case .threeYears:
            growthRate = 0.35  // 三年约35%增长
        case .fiveYears:
            growthRate = 0.65  // 五年约65%增长
        // case .tenYears:
        //     growthRate = 1.20  // 十年约120%增长（翻倍多）
        }
        
        // 从历史价格增长到当前价格
        let historicalPrice = currentPrice / (1 + growthRate)
        return historicalPrice + (currentPrice - historicalPrice) * progress
    }
    
    // 计算周期性波动（不是随机的，而是有规律的市场波动）
    private func calculateCyclicalVariation(dayIndex: Double, timeRange: ChartTimeRange) -> Double {
        // 使用多个正弦波叠加，模拟真实的市场周期
        let yearCycle = sin(dayIndex * 0.0172) * getMarketCycleAmplitude(for: timeRange) // 年度周期
        let quarterCycle = sin(dayIndex * 0.0689) * (getMarketCycleAmplitude(for: timeRange) * 0.4) // 季度周期
        let monthCycle = sin(dayIndex * 0.2094) * (getMarketCycleAmplitude(for: timeRange) * 0.2) // 月度波动
        
        return yearCycle + quarterCycle + monthCycle
    }
    
    // 市场周期波动幅度
    private func getMarketCycleAmplitude(for timeRange: ChartTimeRange) -> Double {
        switch timeRange {
        case .sixMonths: return 15  // 短期波动相对小
        case .oneYear: return 25
        case .threeYears: return 40
        case .fiveYears: return 50
        // case .tenYears: return 60  // 长期波动幅度更大
        }
    }
    
    
    // 清除历史数据缓存（用于重新生成更准确的数据）
    func clearHistoryCache() {
        userDefaults.removeObject(forKey: "cachedPriceHistory")
        priceHistory = []
        print("🗑️ 已清除历史数据缓存")
    }
    
    // 生成初始示例数据
    private func generateInitialMockData() {
        let basePrice = currentPrice > 0 ? currentPrice : 825.0 // 使用更合理的基准价格
        var initialHistory: [GoldPriceHistory] = []
        let calendar = Calendar.current
        let endDate = Date()
        
        // 生成最近30天的数据，确保价格合理
        for i in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: endDate) else { continue }
            
            let dayIndex = Double(30 - i)
            let trend = sin(dayIndex * 0.15) * 15 // 增加波动幅度
            let randomVariation = Double.random(in: -20...20) // 增加随机波动
            let price = basePrice + trend + randomVariation
            
            initialHistory.append(GoldPriceHistory(
                date: date,
                price: max(700, price), // 提高最低价格
                source: "示例数据"
            ))
        }
        
        self.priceHistory = initialHistory.sorted { $0.date < $1.date }
        cachePriceHistory(self.priceHistory)
        print("✅ 生成初始示例历史数据: \(self.priceHistory.count) 条记录")
    }
}
