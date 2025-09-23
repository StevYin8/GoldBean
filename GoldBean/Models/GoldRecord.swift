import Foundation
import CoreData

@objc(GoldRecord)
public class GoldRecord: NSManagedObject {
    
}

extension GoldRecord {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GoldRecord> {
        return NSFetchRequest<GoldRecord>(entityName: "GoldRecord")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var name: String?
    @NSManaged public var weight: Double // 克重
    @NSManaged public var purchasePrice: Double // 购买总价
    @NSManaged public var purchaseDate: Date
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    // 计算购买时单克价格
    var purchasePricePerGram: Double {
        return weight > 0 ? purchasePrice / weight : 0
    }
    
    // 计算当前价值
    func currentValue(goldPrice: Double) -> Double {
        return weight * goldPrice
    }
    
    // 计算盈亏金额
    func profitLoss(goldPrice: Double) -> Double {
        return currentValue(goldPrice: goldPrice) - purchasePrice
    }
    
    // 计算盈亏百分比
    func profitLossPercentage(goldPrice: Double) -> Double {
        return purchasePrice > 0 ? (profitLoss(goldPrice: goldPrice) / purchasePrice) * 100 : 0
    }
}

extension GoldRecord: Identifiable {
    
}
