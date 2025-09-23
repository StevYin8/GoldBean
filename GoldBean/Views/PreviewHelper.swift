import Foundation
import CoreData

struct PreviewHelper {
    static func createSampleData(context: NSManagedObjectContext) {
        // 创建示例数据用于预览
        let sampleRecords = [
            ("黄金手镯", 15.5, 8500.0, Calendar.current.date(byAdding: .day, value: -30, to: Date())!, "生日礼物"),
            ("黄金项链", 8.2, 4900.0, Calendar.current.date(byAdding: .day, value: -15, to: Date())!, "结婚纪念日"),
            ("黄金戒指", 3.1, 1850.0, Calendar.current.date(byAdding: .day, value: -5, to: Date())!, "订婚戒指"),
            ("黄金耳环", 2.8, 1680.0, Calendar.current.date(byAdding: .day, value: -2, to: Date())!, nil)
        ]
        
        for (name, weight, price, date, notes) in sampleRecords {
            let record = GoldRecord(context: context)
            record.id = UUID()
            record.name = name
            record.weight = weight
            record.purchasePrice = price
            record.purchaseDate = date
            record.notes = notes
            record.createdAt = date
            record.updatedAt = date
        }
        
        try? context.save()
    }
    
    static func clearAllData(context: NSManagedObjectContext) {
        let request: NSFetchRequest<GoldRecord> = GoldRecord.fetchRequest()
        let records = try? context.fetch(request)
        records?.forEach { context.delete($0) }
        try? context.save()
    }
} 