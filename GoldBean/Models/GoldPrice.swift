import Foundation

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