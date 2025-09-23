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
                    List {
                        ForEach(filteredRecords, id: \.id) { record in
                            GoldRecordRow(record: record)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedRecord = record
                                }
                        }
                        .onDelete(perform: deleteRecords)
                    }
                    .searchable(text: $searchText, prompt: "搜索记录...")
                }
            }
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
    private func GoldRecordRow(record: GoldRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.name ?? "黄金首饰")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("\(String(format: "%.2f", record.weight))克")
                        Text("•")
                        Text(formatDate(record.purchaseDate))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    let profitLoss = record.profitLoss(goldPrice: goldPriceService.currentPrice)
                    let percentage = record.profitLossPercentage(goldPrice: goldPriceService.currentPrice)
                    
                    Text(String(format: "¥%.2f", profitLoss))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(profitLoss >= 0 ? .green : .red)
                    
                    Text(String(format: "%.2f%%", percentage))
                        .font(.caption)
                        .foregroundColor(profitLoss >= 0 ? .green : .red)
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("购买价")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "¥%.2f", record.purchasePrice))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 2) {
                    Text("单克价")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "¥%.2f", record.purchasePricePerGram))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("当前价值")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "¥%.2f", record.currentValue(goldPrice: goldPriceService.currentPrice)))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
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