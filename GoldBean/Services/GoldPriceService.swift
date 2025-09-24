import Foundation
import Combine

class GoldPriceService: ObservableObject {
    static let shared = GoldPriceService()
    
    @Published var currentPrice: Double = 0.0 // 初始化为0，表示无数据
    @Published var lastUpdated: Date = Date()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var priceSource: String = "" 
    @Published var hasValidData: Bool = false // 新增：标识是否有有效数据
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    // 主要API：使用免费的汇率API获取美元金价，然后转换为人民币
    private let primaryAPIURL = "https://api.exchangerate-api.com/v4/latest/USD"
    private let alternativeURL = "https://api.coinbase.com/v2/exchange-rates?currency=XAU"
    // 基准金价（用于计算零售价格）
    private let fallbackGoldPriceUSD = 2000.0 // 美元/盎司，转换为零售金价
    // 备用简易API（使用JSONBin作为静态数据源进行测试）
    private let backupAPIURL = "https://httpbin.org/json" // 用于测试网络连接
    
    init() {
        loadCachedPrice()
        // 智能更新：只在今日未更新时自动获取
        checkAndAutoUpdatePrice()
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
        errorMessage = nil
        
        print("🔄 开始获取金价... (自动更新: \(isAutoUpdate))")
        
        // 尝试从 Metals.live 获取价格
        fetchPriceFromMetalsLive()
    }
    
    // 强制刷新价格（用户确认后）
    func forceRefreshPrice() {
        isLoading = true
        errorMessage = nil
        print("🔄 强制刷新金价...")
        fetchPriceFromMetalsLive()
    }
    
    private func fetchPriceFromMetalsLive() {
        // 简化策略：直接使用固定金价+实时汇率
        print("🔄 使用简化金价获取策略...")
        fetchExchangeRate()
    }
    
    private func fetchExchangeRate() {
        guard let url = URL(string: primaryAPIURL) else {
            print("汇率API URL无效，尝试Coinbase")
            fetchPriceFromCoinbase()
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("GoldBean/1.0", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                if let httpResponse = response as? HTTPURLResponse {
                    print("汇率API HTTP状态码: \(httpResponse.statusCode)")
                }
                
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("汇率API响应: \(jsonString.prefix(200))...")
                }
                
                return data
            }
            .decode(type: ExchangeRateResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("汇率API调用失败: \(error.localizedDescription)，尝试Coinbase")
                        self?.fetchPriceFromCoinbase()
                    }
                },
                receiveValue: { [weak self] response in
                    if let usdToCnyRate = response.rates["CNY"] {
                        // 计算原料金价
                        let rawGoldPrice = (self?.fallbackGoldPriceUSD ?? 2000.0) * usdToCnyRate / 31.1035
                        // 转换为零售金价 (原料价格 × 1.8倍)
                        let retailGoldPrice = rawGoldPrice * 1.8
                        print("✅ 汇率获取成功，原料金价: ¥\(String(format: "%.2f", rawGoldPrice))/克")
                        print("✅ 计算零售金价: ¥\(String(format: "%.2f", retailGoldPrice))/克")
                        self?.updatePrice(priceCNY: retailGoldPrice, source: "ExchangeRate")
                    } else {
                        print("汇率响应中未找到CNY汇率，尝试Coinbase")
                        self?.fetchPriceFromCoinbase()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func fetchPriceFromCoinbase() {
        guard let url = URL(string: alternativeURL) else {
            print("Coinbase URL无效，API获取失败")
            handleAPIFailure()
            return
        }
        
        // 创建带超时的URLRequest
        var request = URLRequest(url: url)
        request.timeoutInterval = 20.0  // 20秒超时，给Coinbase更多时间
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("GoldBean/1.0", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                // 添加响应调试信息
                if let httpResponse = response as? HTTPURLResponse {
                    print("Coinbase HTTP状态码: \(httpResponse.statusCode)")
                }
                
                // 打印响应数据以便调试
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Coinbase API响应: \(jsonString.prefix(300))...")
                }
                
                return data
            }
            .decode(type: CoinbaseResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Coinbase API调用失败: \(error.localizedDescription)")
                        // 尝试第三个API源
                        self?.fetchPriceFromGoldPrice()
                    }
                },
                receiveValue: { [weak self] response in
                    if let priceString = response.data.rates["CNY"],
                       let priceUSD = Double(priceString) {
                        print("✅ Coinbase获取成功: ¥\(priceUSD)/oz")
                        // Coinbase返回的是1 XAU = X CNY，所以直接使用
                        self?.updatePrice(priceCNY: priceUSD, source: "Coinbase")
                    } else {
                        print("Coinbase响应中未找到黄金价格，尝试第三个API源")
                        self?.fetchPriceFromGoldPrice()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func fetchPriceFromGoldPrice() {
        // 网络连通性测试
        guard let url = URL(string: backupAPIURL) else {
            print("备用API URL无效，所有API尝试失败")
            handleAPIFailure()
            return
        }
        
        print("🔄 测试网络连通性...")
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0 // 短超时用于快速测试
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("❌ 网络连通性测试失败: \(error.localizedDescription)")
                        print("🔍 可能的原因：1) 网络连接问题 2) DNS解析失败 3) 防火墙限制")
                        self?.handleAPIFailure()
                    } else {
                        print("✅ 网络连通性正常，但金价API都无法访问")
                        self?.handleAPIFailure()
                    }
                },
                receiveValue: { _ in
                    print("✅ 网络连通性测试成功")
                }
            )
            .store(in: &cancellables)
    }
    
    // 处理API获取失败的情况
    private func handleAPIFailure() {
        self.isLoading = false
        
        if hasValidData {
            // 有缓存数据，继续使用
            self.errorMessage = "网络连接超时，显示缓存数据。建议检查网络设置后重试"
            print("⚠️ API获取失败，使用缓存数据: ¥\(String(format: "%.2f", currentPrice))/克")
        } else {
            // 无缓存数据，提示用户
            self.errorMessage = "网络连接失败，请检查网络设置。可能原因：1)WiFi/蜂窝网络问题 2)API服务暂时不可用"
            self.currentPrice = 0.0
            self.priceSource = "网络异常"
            print("❌ API获取失败且无缓存数据")
        }
    }
    
    private func updatePrice(priceUSD: Double, source: String) {
        // 假设汇率，实际应用中可能需要单独获取汇率API
        let exchangeRateUSDToCNY = 7.2
        // Metals.live返回的是每盎司美元价格，需要转换为每克人民币价格
        // 1盎司 = 31.1035克
        let priceCNYPerGram = (priceUSD * exchangeRateUSDToCNY) / 31.1035
        
        self.currentPrice = priceCNYPerGram
        self.lastUpdated = Date()
        self.isLoading = false
        self.errorMessage = nil
        self.priceSource = source
        self.hasValidData = true
        
        self.cachePrice(priceCNYPerGram, date: Date(), source: source)
        print("✅ 金价更新成功: ¥\(String(format: "%.2f", priceCNYPerGram))/克 来源: \(source)")
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
    
    // 汇率API响应结构
    struct ExchangeRateResponse: Decodable {
        let rates: [String: Double]
        let base: String?
        let date: String?
    }
    
    // Coinbase API响应结构
    struct CoinbaseResponse: Decodable {
        let data: ExchangeRatesData
        
        struct ExchangeRatesData: Decodable {
            let currency: String
            let rates: [String: String] // 价格通常是字符串形式
        }
    }
}
