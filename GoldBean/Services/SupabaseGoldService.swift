import Foundation
import Supabase
import Combine

// Supabase 黄金数据服务
class SupabaseGoldService {
    static let shared = SupabaseGoldService()
    
    private let client: SupabaseClient
    
    private init() {
        self.client = SupabaseConfig.shared.client
        print("✅ SupabaseGoldService 初始化完成")
    }
    
    // MARK: - 异步方法（async/await）
    
    /// 获取指定时间范围的历史数据
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期（默认为今天）
    /// - Returns: 历史价格数据数组
    func fetchHistoricalPrices(
        startDate: Date,
        endDate: Date = Date()
    ) async throws -> [GoldPriceHistory] {
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        print("📊 从 Supabase 获取历史数据: \(startDateString) 到 \(endDateString)")
        
        do {
            // 查询数据库 - 直接获取并解析数据
            print("📋 开始查询并解析 JSON 数据...")
            let response: [SupabaseGoldPrice]
            
            do {
                response = try await client
                    .from("gold_historical_prices")
                    .select()
                    .gte("date", value: startDateString)
                    .lte("date", value: endDateString)
                    .order("date", ascending: true)
                    .execute()
                    .value
                
                print("✅ 成功解析 \(response.count) 条数据")
                
                // 打印第一条数据的详细信息
                if let first = response.first {
                    print("📋 第一条数据:")
                    print("   - id: \(first.id ?? "nil")")
                    print("   - date: \(first.date)")
                    print("   - priceUsdPerOunce: \(first.priceUsdPerOunce ?? 0)")
                    print("   - exchangeRateUsdCny: \(first.exchangeRateUsdCny ?? 0)")
                    print("   - priceCnyPerGram: \(first.priceCnyPerGram ?? 0)")
                }
                
            } catch let decodingError {
                print("❌ JSON 解码错误: \(decodingError)")
                if let decodingError = decodingError as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("   缺少字段: \(key.stringValue)")
                        print("   位置: \(context.codingPath)")
                    case .typeMismatch(let type, let context):
                        print("   类型不匹配: 期望 \(type)")
                        print("   位置: \(context.codingPath)")
                        print("   描述: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("   值缺失: 期望 \(type)")
                        print("   位置: \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("   数据损坏")
                        print("   描述: \(context.debugDescription)")
                    @unknown default:
                        print("   未知错误")
                    }
                }
                throw decodingError
            }
            
            if response.isEmpty {
                print("⚠️ 数据库中没有符合条件的数据")
                print("💡 请检查：")
                print("   1. Supabase 表 'gold_historical_prices' 是否存在")
                print("   2. 表中是否有数据")
                print("   3. RLS 策略是否正确配置")
            }
            
            // 转换为 App 数据模型（过滤掉无效数据）
            let history = response.compactMap { $0.toGoldPriceHistory() }
            
            if history.count < response.count {
                print("⚠️ \(response.count - history.count) 条数据因缺少必要字段被过滤")
            }
            
            return history
            
        } catch {
            print("❌ Supabase 查询失败: \(error.localizedDescription)")
            print("💡 可能的原因：")
            print("   1. 网络连接问题")
            print("   2. Supabase 项目不可访问")
            print("   3. API Key 配置错误")
            print("   4. 数据库表不存在或无权限访问")
            throw error
        }
    }
    
    /// 获取最新的一条数据（用于当前价格）
    /// - Returns: 最新的金价记录，如果没有数据则返回 nil
    func fetchLatestPrice() async throws -> GoldPriceHistory? {
        print("📊 从 Supabase 获取最新金价...")
        
        do {
            let response: [SupabaseGoldPrice] = try await client
                .from("gold_historical_prices")
                .select()
                .order("date", ascending: false)
                .limit(1)
                .execute()
                .value
            
            guard let latest = response.first else {
                print("⚠️ Supabase 中没有数据")
                return nil
            }
            
            if let price = latest.priceCnyPerGram {
                print("✅ 获取到最新金价: ¥\(String(format: "%.2f", price))/克 (日期: \(latest.date))")
            } else {
                print("⚠️ 最新数据缺少价格信息")
            }
            
            return latest.toGoldPriceHistory()
            
        } catch {
            print("❌ 获取最新价格失败: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 获取最近N天的历史数据
    /// - Parameter days: 天数
    /// - Returns: 历史价格数据数组
    func fetchRecentDays(days: Int) async throws -> [GoldPriceHistory] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        return try await fetchHistoricalPrices(startDate: startDate, endDate: endDate)
    }
    
    // MARK: - Combine 版本（与现有代码风格一致）
    
    /// 获取历史价格数据（Combine Publisher）
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: Publisher
    func fetchHistoricalPricesPublisher(
        startDate: Date,
        endDate: Date = Date()
    ) -> AnyPublisher<[GoldPriceHistory], Error> {
        Future { promise in
            Task {
                do {
                    let history = try await self.fetchHistoricalPrices(
                        startDate: startDate,
                        endDate: endDate
                    )
                    promise(.success(history))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 获取最新价格（Combine Publisher）
    /// - Returns: Publisher
    func fetchLatestPricePublisher() -> AnyPublisher<GoldPriceHistory?, Error> {
        Future { promise in
            Task {
                do {
                    let latest = try await self.fetchLatestPrice()
                    promise(.success(latest))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 数据可用性检查
    
    /// 检查数据库中有多少数据
    /// - Returns: (总记录数估算, 最早日期, 最新日期)
    func checkDataAvailability() async -> (totalRecords: Int, earliestDate: String?, latestDate: String?) {
        do {
            // 获取最新日期
            let latestResponse: [SupabaseGoldPrice] = try await client
                .from("gold_historical_prices")
                .select()
                .order("date", ascending: false)
                .limit(1)
                .execute()
                .value
            
            let latestDate = latestResponse.first?.date
            
            // 获取最早日期
            let oldestResponse: [SupabaseGoldPrice] = try await client
                .from("gold_historical_prices")
                .select()
                .order("date", ascending: true)
                .limit(1)
                .execute()
                .value
            
            let earliestDate = oldestResponse.first?.date
            
            // 计算记录数（按天数估算）
            var totalDays = 0
            if let earliest = earliestDate, let latest = latestDate {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withFullDate]
                
                if let start = formatter.date(from: earliest),
                   let end = formatter.date(from: latest) {
                    totalDays = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
                }
            }
            
            print("📊 Supabase 数据统计:")
            print("   估计记录: ~\(totalDays) 天")
            print("   最早日期: \(earliestDate ?? "未知")")
            print("   最新日期: \(latestDate ?? "未知")")
            
            return (totalDays, earliestDate, latestDate)
            
        } catch {
            print("❌ 检查数据可用性失败: \(error.localizedDescription)")
            return (0, nil, nil)
        }
    }
    
    /// 验证 Supabase 连接
    /// - Returns: 是否连接成功
    func testConnection() async -> Bool {
        do {
            // 尝试获取一条数据来测试连接
            let _: [SupabaseGoldPrice] = try await client
                .from("gold_historical_prices")
                .select()
                .limit(1)
                .execute()
                .value
            
            print("✅ Supabase 连接测试成功")
            return true
            
        } catch {
            print("❌ Supabase 连接测试失败: \(error.localizedDescription)")
            return false
        }
    }
}


