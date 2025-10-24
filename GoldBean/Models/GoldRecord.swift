import Foundation
import CoreData
import UIKit

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
    @NSManaged public var imageData: Data? // 图片数据
    
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
    
    // MARK: - 图片相关方法
    
    // 获取UIImage对象
    var image: UIImage? {
        get {
            guard let data = imageData else { return nil }
            return UIImage(data: data)
        }
        set {
            if let image = newValue {
                // 压缩图片以节省存储空间
                imageData = image.jpegData(compressionQuality: 0.8)
            } else {
                imageData = nil
            }
        }
    }
    
    // 检查是否有图片
    var hasImage: Bool {
        return imageData != nil
    }
}

extension GoldRecord: Identifiable {
    
}
