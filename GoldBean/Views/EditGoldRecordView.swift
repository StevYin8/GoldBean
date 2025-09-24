import SwiftUI

struct EditGoldRecordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let record: GoldRecord
    
    @State private var name: String = ""
    @State private var weight: String = ""
    @State private var purchasePrice: String = ""
    @State private var purchaseDate: Date = Date()
    @State private var notes: String = ""
    @State private var isPricePerGram: Bool = false
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("名称（可选）", text: $name)
                    
                    HStack {
                        TextField("克重", text: $weight)
                            .keyboardType(.decimalPad)
                        Text("克")
                            .foregroundColor(.secondary)
                    }
                    
                    DatePicker("购买日期", selection: $purchaseDate, displayedComponents: .date)
                }
                
                Section(header: Text("价格信息")) {
                    Toggle("按单克价格输入", isOn: $isPricePerGram)
                    
                    HStack {
                        TextField(isPricePerGram ? "单克价格" : "总价", text: $purchasePrice)
                            .keyboardType(.decimalPad)
                        Text(isPricePerGram ? "元/克" : "元")
                            .foregroundColor(.secondary)
                    }
                    
                    if isPricePerGram && !weight.isEmpty && !purchasePrice.isEmpty {
                        if let weightValue = Double(weight), let priceValue = Double(purchasePrice) {
                            HStack {
                                Text("总价")
                                Spacer()
                                Text(String(format: "¥%.2f", weightValue * priceValue))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section(header: Text("备注")) {
                    TextField("备注（可选）", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
                
                Section {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("删除记录")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveRecord()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .alert("删除记录", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    deleteRecord()
                }
            } message: {
                Text("确定要删除这条记录吗？此操作无法撤销。")
            }
        }
        .onAppear {
            loadRecordData()
        }
    }
    
    private func loadRecordData() {
        name = record.name ?? ""
        weight = String(record.weight)
        purchasePrice = String(record.purchasePrice)
        purchaseDate = record.purchaseDate
        notes = record.notes ?? ""
        isPricePerGram = false // 默认显示总价
    }
    
    private func saveRecord() {
        // 验证输入
        guard let weightValue = Double(weight), weightValue > 0 else {
            alertMessage = "请输入有效的克重"
            showingAlert = true
            return
        }
        
        guard let priceValue = Double(purchasePrice), priceValue > 0 else {
            alertMessage = "请输入有效的价格"
            showingAlert = true
            return
        }
        
        // 计算总价
        let totalPrice = isPricePerGram ? weightValue * priceValue : priceValue
        
        // 更新记录
        record.name = name.isEmpty ? nil : name
        record.weight = weightValue
        record.purchasePrice = totalPrice
        record.purchaseDate = purchaseDate
        record.notes = notes.isEmpty ? nil : notes
        record.updatedAt = Date() // 确保updatedAt被更新，触发SwiftUI刷新
        
        CoreDataManager.shared.updateGoldRecord(record)
        
        dismiss()
    }
    
    private func deleteRecord() {
        CoreDataManager.shared.deleteGoldRecord(record)
        dismiss()
    }
} 