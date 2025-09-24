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
}
