import Foundation

// Supabase 数据库表模型 - 对应 gold_historical_prices 表
struct SupabaseGoldPrice: Codable, Identifiable {
    let id: String?  // UUID 类型，Supabase 返回字符串
    let date: String  // ISO 格式日期字符串 "2024-10-10"
    let priceUsdPerOunce: Double?
    let openPriceUsd: Double?
    let closePriceUsd: Double?
    let highPriceUsd: Double?
    let lowPriceUsd: Double?
    let volume: Int?
    let exchangeRateUsdCny: Double?
    let priceCnyPerGram: Double?  // 数据库自动计算的人民币/克价格
    let dataSource: String?
    let exchangeRateSource: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case priceUsdPerOunce = "price_usd_per_ounce"
        case openPriceUsd = "open_price_usd"
        case closePriceUsd = "close_price_usd"
        case highPriceUsd = "high_price_usd"
        case lowPriceUsd = "low_price_usd"
        case volume
        case exchangeRateUsdCny = "exchange_rate_usd_cny"
        case priceCnyPerGram = "price_cny_per_gram"
        case dataSource = "data_source"
        case exchangeRateSource = "exchange_rate_source"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // 转换为 App 内部使用的数据模型
    func toGoldPriceHistory() -> GoldPriceHistory? {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let parsedDate = dateFormatter.date(from: date) ?? Date()
        
        // 确保有人民币价格数据
        guard let cnyPrice = priceCnyPerGram else {
            print("⚠️ 数据缺失：date=\(date) 没有 priceCnyPerGram")
            return nil
        }
        
        return GoldPriceHistory(
            date: parsedDate,
            price: cnyPrice,  // 使用数据库自动计算的人民币价格（真实汇率）
            source: "Supabase (\(dataSource ?? "Unknown"))"
        )
    }
}

// 汇率历史数据模型（可选）
struct SupabaseExchangeRate: Codable, Identifiable {
    let id: Int?
    let date: String
    let currencyPair: String
    let rate: Double
    let dataSource: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case currencyPair = "currency_pair"
        case rate
        case dataSource = "data_source"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}


