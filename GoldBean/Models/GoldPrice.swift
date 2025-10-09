import Foundation

// 历史价格数据模型
struct GoldPriceHistory: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let price: Double
    let source: String
    
    init(date: Date, price: Double, source: String = "API") {
        self.date = date
        self.price = price
        self.source = source
    }
}

// 时间范围枚举
enum ChartTimeRange: String, CaseIterable {
    case sixMonths = "6M"
    case oneYear = "1Y"
    case threeYears = "3Y"
    case fiveYears = "5Y"
    case tenYears = "10Y"
    
    var displayName: String {
        switch self {
        case .sixMonths: return "6个月"
        case .oneYear: return "1年"
        case .threeYears: return "3年"
        case .fiveYears: return "5年"
        case .tenYears: return "10年"
        }
    }
    
    var days: Int {
        switch self {
        case .sixMonths: return 180
        case .oneYear: return 365
        case .threeYears: return 365 * 3
        case .fiveYears: return 365 * 5
        case .tenYears: return 365 * 10
        }
    }
}

// 趋势指标
struct TrendIndicators {
    let highestPrice: Double
    let lowestPrice: Double
    let priceChange: Double
    let priceChangePercentage: Double
    let averagePrice: Double
    let currentPrice: Double
    
    static let empty = TrendIndicators(
        highestPrice: 0,
        lowestPrice: 0,
        priceChange: 0,
        priceChangePercentage: 0,
        averagePrice: 0,
        currentPrice: 0
    )
}

struct GoldPrice: Codable {
    let success: Bool
    let timestamp: Int
    let base: String
    let date: String
    let rates: [String: Double]
    
    // 获取人民币每克价格
    var cnyPerGram: Double {
        // 通常API返回的是每盎司价格，需要转换为每克
        // 1盎司 = 31.1035克
        if let xauCny = rates["CNY"] {
            return xauCny / 31.1035
        }
        return 0
    }
    
    // 获取美元每盎司价格
    var usdPerOunce: Double {
        return rates["USD"] ?? 0
    }
}

struct SimpleGoldPrice: Codable {
    let price: Double
    let currency: String
    let unit: String
    let timestamp: Date
    
    init(price: Double, currency: String = "CNY", unit: String = "gram") {
        self.price = price
        self.currency = currency
        self.unit = unit
        self.timestamp = Date()
    }
} 