import Foundation
import CoreData
import Combine

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    @Published var hasChanges = false
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "GoldBean")
        
        // 打印数据库文件位置
        let storeURL = container.persistentStoreDescriptions.first?.url
        print("📍 Core Data Store URL: \(storeURL?.absoluteString ?? "Unknown")")
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Core Data error: \(error.localizedDescription)")
                fatalError("Core Data error: \(error.localizedDescription)")
            } else {
                print("✅ Core Data loaded successfully")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
                hasChanges = false
                print("✅ Core Data saved successfully")
            } catch {
                print("❌ 保存失败: \(error.localizedDescription)")
            }
        }
    }
    
    func createGoldRecord(name: String?, weight: Double, purchasePrice: Double, purchaseDate: Date, notes: String?) -> GoldRecord {
        // 确保使用正确的entity描述
        guard let entity = NSEntityDescription.entity(forEntityName: "GoldRecord", in: context) else {
            fatalError("Could not find entity description for GoldRecord")
        }
        
        let record = GoldRecord(entity: entity, insertInto: context)
        
        // 设置必需的属性
        record.id = UUID()
        record.createdAt = Date()
        record.updatedAt = Date()
        
        // 设置用户输入的属性
        record.name = name
        record.weight = weight
        record.purchasePrice = purchasePrice
        record.purchaseDate = purchaseDate
        record.notes = notes
        
        print("�� 创建新记录: \(name ?? "未命名") - \(weight)克 - ¥\(purchasePrice)")
        
        save()
        hasChanges = true
        return record
    }
    
    func deleteGoldRecord(_ record: GoldRecord) {
        context.delete(record)
        save()
        hasChanges = true
        print("🗑️ 删除记录: \(record.name ?? "未命名")")
    }
    
    func updateGoldRecord(_ record: GoldRecord) {
        record.updatedAt = Date()
        
        // 确保Core Data检测到变化
        context.refresh(record, mergeChanges: true)
        
        save()
        hasChanges = true
        print("📝 更新记录: \(record.name ?? "未命名")，备注: \(record.notes ?? "无")")
    }
    
    func fetchAllGoldRecords() -> [GoldRecord] {
        let request: NSFetchRequest<GoldRecord> = GoldRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GoldRecord.purchaseDate, ascending: false)]
        
        do {
            let records = try context.fetch(request)
            print("📊 获取到 \(records.count) 条记录")
            return records
        } catch {
            print("❌ 获取记录失败: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - 历史价格数据管理
    
    // 保存历史价格数据（已废弃 - 改用基于真实金价的趋势生成）
    /* 
    func saveHistoricalPrices(_ prices: [InvestingComScraper.HistoricalData]) {
        var savedCount = 0
        var updatedCount = 0
        
        for priceData in prices {
            // 检查是否已存在（避免重复）
            let fetchRequest: NSFetchRequest<HistoricalPrice> = HistoricalPrice.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "date == %@", priceData.date as NSDate)
            
            do {
                let existing = try context.fetch(fetchRequest)
                
                if existing.isEmpty {
                    // 创建新记录
                    guard let entity = NSEntityDescription.entity(forEntityName: "HistoricalPrice", in: context) else {
                        print("❌ 无法创建 HistoricalPrice 实体")
                        continue
                    }
                    
                    let record = HistoricalPrice(entity: entity, insertInto: context)
                    record.id = UUID()
                    record.date = priceData.date
                    record.closePrice = priceData.closePrice
                    record.openPrice = priceData.openPrice
                    record.highPrice = priceData.highPrice
                    record.lowPrice = priceData.lowPrice
                    record.priceChangePercent = priceData.changePercent
                    record.priceChange = priceData.closePrice - priceData.openPrice
                    record.source = "Investing.com"
                    record.createdAt = Date()
                    
                    savedCount += 1
                } else {
                    // 更新现有记录
                    let record = existing[0]
                    record.closePrice = priceData.closePrice
                    record.openPrice = priceData.openPrice
                    record.highPrice = priceData.highPrice
                    record.lowPrice = priceData.lowPrice
                    record.priceChangePercent = priceData.changePercent
                    record.priceChange = priceData.closePrice - priceData.openPrice
                    
                    updatedCount += 1
                }
            } catch {
                print("❌ 保存历史价格失败: \(error.localizedDescription)")
            }
        }
        
        save()
        print("✅ 历史价格数据已保存: 新增 \(savedCount) 条，更新 \(updatedCount) 条")
    }
    */
    
    // MARK: - 历史价格缓存方法（已废弃，现使用 UserDefaults 缓存）
    // 注意：这些方法已不再使用，历史价格数据现在通过 GoldPriceService 的 UserDefaults 缓存
    
    /*
    // 获取指定日期范围的历史价格
    func fetchHistoricalPrices(from startDate: Date, to endDate: Date) -> [HistoricalPrice] {
        let request: NSFetchRequest<HistoricalPrice> = HistoricalPrice.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", 
                                       startDate as NSDate, 
                                       endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            let records = try context.fetch(request)
            print("📊 从数据库获取到 \(records.count) 条历史价格数据")
            return records
        } catch {
            print("❌ 获取历史价格失败: \(error.localizedDescription)")
            return []
        }
    }
    
    // 检查是否有指定日期范围的缓存数据
    func hasHistoricalDataCache(from startDate: Date, to endDate: Date) -> Bool {
        let records = fetchHistoricalPrices(from: startDate, to: endDate)
        
        // 计算应有的数据条数（考虑周末和节假日，使用宽松标准）
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        
        // 假设交易日约占总天数的70%（去除周末和节假日）
        let expectedRecords = Int(Double(days) * 0.7)
        
        // 如果缓存数据超过预期的60%，认为缓存基本有效
        let cacheRatio = expectedRecords > 0 ? Double(records.count) / Double(expectedRecords) : 0
        let hasSufficientCache = cacheRatio >= 0.6
        
        print("📊 缓存数据: \(records.count)/\(expectedRecords) 条 (覆盖率: \(String(format: "%.1f%%", cacheRatio * 100)))")
        
        return hasSufficientCache && records.count > 10 // 至少要有10条数据
    }
    
    // 获取最新的历史价格记录日期
    func getLatestHistoricalPriceDate() -> Date? {
        let request: NSFetchRequest<HistoricalPrice> = HistoricalPrice.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchLimit = 1
        
        do {
            let records = try context.fetch(request)
            return records.first?.date
        } catch {
            print("❌ 获取最新日期失败: \(error.localizedDescription)")
            return nil
        }
    }
    */
    
    // 获取历史价格数据总数（简化版本，返回0）
    func getHistoricalPriceCount() -> Int {
        // 历史价格现在通过 UserDefaults 缓存，不再使用 Core Data
        return 0
    }
    
    // 清除所有历史价格缓存（简化版本，实际清除通过 GoldPriceService）
    func clearHistoricalPriceCache() {
        // 历史价格现在通过 UserDefaults 缓存，实际清除在 GoldPriceService 中
        print("🗑️ 历史价格缓存清除请求（Core Data 不再使用）")
    }
    
    /*
    // 清除指定日期之前的历史数据（用于数据清理）
    func clearHistoricalPricesBefore(date: Date) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = HistoricalPrice.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date < %@", date as NSDate)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("🗑️ 已清除 \(date) 之前的历史数据")
        } catch {
            print("❌ 清除旧数据失败: \(error.localizedDescription)")
        }
    }
    */
}
