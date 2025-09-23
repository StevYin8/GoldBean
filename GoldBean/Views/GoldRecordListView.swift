import SwiftUI
import CoreData

struct GoldRecordListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var goldPriceService: GoldPriceService
    @FetchRequest(
        entity: GoldRecord.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \GoldRecord.purchaseDate, ascending: false)]
    ) private var goldRecords: FetchedResults<GoldRecord>
    
    @State private var showingAddRecord = false
    @State private var searchText = ""
    @State private var selectedRecord: GoldRecord?
    
    var filteredRecords: [GoldRecord] {
        if searchText.isEmpty {
            return Array(goldRecords)
        } else {
            return goldRecords.filter { record in
                (record.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (record.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if goldRecords.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredRecords, id: \.id) { record in
                                GoldRecordCard(record: record)
                                    .onTapGesture {
                                        selectedRecord = record
                                    }
                                    .contextMenu {
                                        Button(action: {
                                            selectedRecord = record
                                        }) {
                                            Label("编辑", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive, action: {
                                            deleteRecord(record)
                                        }) {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .background(Color(.systemBackground))
                    .searchable(text: $searchText, prompt: "搜索记录...")
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("黄金记录")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddRecord = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddRecord) {
                AddGoldRecordView()
            }
            .sheet(item: $selectedRecord) { record in
                EditGoldRecordView(record: record)
            }
        }
    }
    
    @ViewBuilder
    private func EmptyStateView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("还没有黄金记录")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("点击右上角 + 号添加您的第一条记录")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingAddRecord = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("添加记录")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.orange)
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    @ViewBuilder
    private func GoldRecordCard(record: GoldRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部标题行
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.name ?? "黄金首饰")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(String(format: "%.2f", record.weight))克")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    let profitLoss = record.profitLoss(goldPrice: goldPriceService.currentPrice)
                    let percentage = record.profitLossPercentage(goldPrice: goldPriceService.currentPrice)
                    
                    Text(String(format: "¥%.2f", profitLoss))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(profitLoss >= 0 ? .green : .red)
                    
                    Text(String(format: "%.2f%%", percentage))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(profitLoss >= 0 ? .green : .red)
                }
            }
            
            // 价格信息网格
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("购买价")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "¥%.2f", record.purchasePrice))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text("单克价")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "¥%.2f", record.purchasePricePerGram))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("当前价值")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "¥%.2f", record.currentValue(goldPrice: goldPriceService.currentPrice)))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            
            // 备注信息
            if let notes = record.notes, !notes.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
    
    private func deleteRecord(_ record: GoldRecord) {
        withAnimation {
            viewContext.delete(record)
            
            do {
                try viewContext.save()
            } catch {
                print("删除失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteRecords(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredRecords[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("删除失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
} 