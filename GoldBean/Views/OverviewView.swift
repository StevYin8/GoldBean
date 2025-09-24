import SwiftUI
import CoreData

struct OverviewView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var goldPriceService: GoldPriceService
    @FetchRequest(
        entity: GoldRecord.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \GoldRecord.purchaseDate, ascending: false)]
    ) private var goldRecords: FetchedResults<GoldRecord>
    
    var totalWeight: Double {
        goldRecords.reduce(0) { $0 + $1.weight }
    }
    
    var totalInvestment: Double {
        goldRecords.reduce(0) { $0 + $1.purchasePrice }
    }
    
    var currentTotalValue: Double {
        goldRecords.reduce(0) { $0 + $1.currentValue(goldPrice: goldPriceService.currentPrice) }
    }
    
    var totalProfitLoss: Double {
        currentTotalValue - totalInvestment
    }
    
    var totalProfitLossPercentage: Double {
        totalInvestment > 0 ? (totalProfitLoss / totalInvestment) * 100 : 0
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 当前金价卡片
                    CurrentPriceCard()
                    
                    // 投资概览卡片
                    InvestmentOverviewCard()
                    
                    // 最近记录
                    RecentRecordsCard()
                }
                .padding()
            }
            .navigationTitle("攒金豆")
            .refreshable {
                // 下拉刷新时强制更新
                goldPriceService.forceRefreshPrice()
            }
        }
    }
    
    @ViewBuilder
    private func CurrentPriceCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.orange)
                Text("当前金价")
                    .font(.headline)
                Spacer()
                
                // 今日更新状态标签
                Text(goldPriceService.getTodayUpdateStatus())
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(getStatusBackgroundColor())
                    .foregroundColor(getStatusTextColor())
                    .cornerRadius(4)
                
                if goldPriceService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            Text(goldPriceService.formattedPrice())
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(goldPriceService.hasValidData ? .orange : .secondary)
            
            HStack {
                Text(goldPriceService.formattedLastUpdated())
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if goldPriceService.isLoading {
                    Text("正在获取金价数据...")
                        .font(.caption2)
                        .foregroundColor(.blue.opacity(0.8))
                } else if goldPriceService.hasValidData {
                    Text("下拉刷新价格")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                } else {
                    Text("获取失败，请下拉重试")
                        .font(.caption2)
                        .foregroundColor(.orange.opacity(0.8))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // 获取状态背景颜色
    private func getStatusBackgroundColor() -> Color {
        let status = goldPriceService.getTodayUpdateStatus()
        switch status {
        case "今日已更新":
            return Color.green.opacity(0.2)
        case "无数据":
            return Color.red.opacity(0.2)
        default:
            return Color.orange.opacity(0.2)
        }
    }
    
    // 获取状态文字颜色
    private func getStatusTextColor() -> Color {
        let status = goldPriceService.getTodayUpdateStatus()
        switch status {
        case "今日已更新":
            return .green
        case "无数据":
            return .red
        default:
            return .orange
        }
    }
    
    @ViewBuilder
    private func InvestmentOverviewCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bitcoinsign.circle")
                    .foregroundColor(.orange)
                Text("投资概览")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                StatRow(title: "总克重", value: String(format: "%.2f 克", totalWeight))
                StatRow(title: "总投入", value: String(format: "¥%.2f", totalInvestment))
                StatRow(title: "当前价值", value: String(format: "¥%.2f", currentTotalValue))
                
                Divider()
                
                HStack {
                    Text("盈亏")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(String(format: "¥%.2f", totalProfitLoss))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(totalProfitLoss >= 0 ? .green : .red)
                        Text(String(format: "%.2f%%", totalProfitLossPercentage))
                            .font(.caption)
                            .foregroundColor(totalProfitLoss >= 0 ? .green : .red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private func RecentRecordsCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.orange)
                Text("最近记录")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: GoldRecordListView()) {
                    Text("查看全部")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            if goldRecords.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("暂无记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            } else {
                ForEach(Array(goldRecords.prefix(3).enumerated()), id: \.element.id) { index, record in
                    VStack(spacing: 0) {
                        RecentRecordRow(record: record)
                        
                        // 添加分割线，但不在最后一条记录后面添加
                        if index < goldRecords.prefix(3).count - 1 {
                            Divider()
                                .background(Color(.systemGray5))
                                .padding(.horizontal, 0)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private func StatRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    @ViewBuilder
    private func RecentRecordRow(record: GoldRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.name ?? "黄金首饰")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(String(format: "%.2f", record.weight))克")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                let profitLoss = record.profitLoss(goldPrice: goldPriceService.currentPrice)
                Text(String(format: "¥%.2f", profitLoss))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(profitLoss >= 0 ? .green : .red)
                Text(String(format: "%.1f%%", record.profitLossPercentage(goldPrice: goldPriceService.currentPrice)))
                    .font(.caption)
                    .foregroundColor(profitLoss >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 12)
    }
} 
