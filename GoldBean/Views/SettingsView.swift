import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var goldPriceService: GoldPriceService
    @StateObject private var notificationManager = NotificationManager.shared
    @AppStorage("currencyUnit") private var currencyUnit: String = "CNY"
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("useRealData") private var useRealData: Bool = true
    
    @State private var showingAPIKeyAlert = false
    @State private var tempAPIKey = ""
    @State private var showingRefreshConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 价格设置模块
                    SettingsCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "价格设置",
                        iconColor: .orange
                    ) {
                        HStack {
                            Text("当前金价")
                            Spacer()
                            Text(goldPriceService.formattedPrice())
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("最后更新")
                            Spacer()
                            Text(goldPriceService.formattedLastUpdated())
                                .foregroundColor(.secondary)
                        }
                        
                        // 今日更新状态
                        HStack {
                            Text("今日状态")
                            Spacer()
                            Text(goldPriceService.getTodayUpdateStatus())
                                .foregroundColor(getStatusColor())
                                .fontWeight(.medium)
                        }
                        
                        Button(goldPriceService.getRefreshButtonText()) {
                            handleRefreshButtonTap()
                        }
                        .disabled(!goldPriceService.canManualRefresh())
                        
                        // 显示错误消息（排除今日已更新提示，因为会显示弹窗）
                        if let errorMessage = goldPriceService.errorMessage,
                           errorMessage != "今日已更新，确认重新获取？" {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                Text(errorMessage)
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    // 通知设置模块
                    SettingsCard(
                        icon: "bell.fill",
                        title: "通知设置",
                        iconColor: .green
                    ) {
                        Toggle("价格更新通知", isOn: $notificationsEnabled)
                            .onChange(of: notificationsEnabled) { newValue in
                                handleNotificationToggle(newValue)
                            }
                        
                        if notificationsEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("每日早上8:00自动获取金价并推送")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: notificationManager.notificationPermissionGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundColor(notificationManager.notificationPermissionGranted ? .green : .orange)
                                        .font(.caption)
                                    
                                    Text(notificationManager.notificationPermissionGranted ? "通知权限已授予" : "需要通知权限")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    if !notificationManager.notificationPermissionGranted {
                                        Button("授权") {
                                            requestNotificationPermission()
                                        }
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    }
                                }
                                
                                // 显示权限请求结果
                                if !notificationManager.permissionRequestResult.isEmpty {
                                    Text(notificationManager.permissionRequestResult)
                                        .font(.caption2)
                                        .foregroundColor(notificationManager.notificationPermissionGranted ? .green : .orange)
                                }
                            }
                        }
                    }
                    
                    // // 数据源设置模块
                    // SettingsCard(
                    //     icon: "cloud.fill",
                    //     title: "数据源设置",
                    //     iconColor: .purple
                    // ) {
                    //     Toggle("使用真实金价数据", isOn: $useRealData)
                    //         .onChange(of: useRealData) { newValue in
                    //             // 当用户切换数据源时，清除缓存并重新加载
                    //             goldPriceService.clearHistoryCache()
                    //             CoreDataManager.shared.clearHistoricalPriceCache()
                    //             print(newValue ? "✅ 已切换到真实数据源" : "⚠️ 已切换到模拟数据源")
                    //         }
                        
                    //     VStack(alignment: .leading, spacing: 8) {
                    //         if useRealData {
                    //             HStack {
                    //                 Image(systemName: "checkmark.circle.fill")
                    //                     .foregroundColor(.green)
                    //                     .font(.caption)
                    //                 Text("当前金价：中国黄金集团官网")
                    //                     .font(.caption)
                    //                     .foregroundColor(.secondary)
                    //             }
                    //             Text("直接从中国黄金集团官网实时抓取基础金价，数据100%真实")
                    //                 .font(.caption2)
                    //                 .foregroundColor(.secondary)
                                
                    //             HStack {
                    //                 Image(systemName: "chart.line.uptrend.xyaxis")
                    //                     .foregroundColor(.blue)
                    //                     .font(.caption)
                    //                 Text("历史趋势：金融模型推算")
                    //                     .font(.caption)
                    //                     .foregroundColor(.secondary)
                    //             }
                    //             Text("基于真实当前金价，使用金融市场规律生成合理的历史趋势")
                    //                 .font(.caption2)
                    //                 .foregroundColor(.secondary)
                                
                    //             HStack(spacing: 4) {
                    //                 Image(systemName: "info.circle.fill")
                    //                     .foregroundColor(.blue)
                    //                     .font(.caption2)
                    //                 Text("历史数据自动缓存，下次查看更快")
                    //                     .font(.caption2)
                    //                     .foregroundColor(.blue)
                    //             }
                    //             .padding(.top, 4)
                    //         } else {
                    //             HStack {
                    //                 Image(systemName: "exclamationmark.triangle.fill")
                    //                     .foregroundColor(.orange)
                    //                     .font(.caption)
                    //                 Text("模拟数据源：仅供演示")
                    //                     .font(.caption)
                    //                     .foregroundColor(.secondary)
                    //             }
                    //             Text("使用算法生成的模拟历史价格数据，仅供功能演示")
                    //                 .font(.caption2)
                    //                 .foregroundColor(.secondary)
                    //         }
                    //     }
                    //     .padding(.top, 8)
                    // }
                    
                    // // Supabase 数据统计模块
                    // SupabaseDataStatsCard()
                    
                    // 关于模块
                    SettingsCard(
                        icon: "info.circle.fill",
                        title: "关于",
                        iconColor: .blue
                    ) {
                        HStack {
                            Text("版本")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("开发者")
                            Spacer()
                            Text("StevYin")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("小红书")
                            Spacer()
                            Button(action: {
                                openXiaohongshu()
                            }) {
                                HStack(spacing: 4) {
                                    Text("@StevYin")
                                        .foregroundColor(.red)
                                    Image(systemName: "arrow.up.right")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color(.systemBackground))
            .navigationTitle("设置")
        }
        .alert("确认重新获取", isPresented: $showingRefreshConfirmation) {
            Button("确认", role: .destructive) {
                goldPriceService.forceRefreshPrice()
            }
            Button("取消", role: .cancel) {
                // 清除错误消息
                goldPriceService.errorMessage = nil
            }
        } message: {
            Text("今日金价已更新过，确认要重新获取最新价格吗？")
        }
    }
    
    // 设置卡片组件
    @ViewBuilder
    private func SettingsCard<Content: View>(
        icon: String,
        title: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏
            HStack(spacing: 12) {
                // 小方块图标
                RoundedRectangle(cornerRadius: 6)
                    .fill(iconColor)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    )
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // 内容区域
            VStack(spacing: 12) {
                content()
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
    
    private func handleRefreshButtonTap() {
        // 先尝试普通刷新
        goldPriceService.fetchGoldPrice()
        
        // 如果触发了"今日已更新"的提示，显示确认对话框
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if goldPriceService.errorMessage == "今日已更新，确认重新获取？" {
                showingRefreshConfirmation = true
            }
        }
    }
    
    private func handleNotificationToggle(_ enabled: Bool) {
        if enabled {
            if notificationManager.notificationPermissionGranted {
                notificationManager.enableDailyNotifications()
                print("✅ 每日通知已启用")
            } else {
                requestNotificationPermission()
            }
        } else {
            notificationManager.disableDailyNotifications()
            print("🔕 每日通知已禁用")
        }
    }
    
    private func requestNotificationPermission() {
        notificationManager.requestNotificationPermission()
    }
    
    private func openXiaohongshu() {
        // 小红书App URL Scheme，如果失败则打开网页版
        let xiaohongshuAppURL = "xhsdiscover://user/profile/5f9d8e7c0000000001004567"
        let xiaohongshuWebURL = "https://www.xiaohongshu.com/user/profile/5f9d8e7c0000000001004567"
        
        if let appURL = URL(string: xiaohongshuAppURL),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let webURL = URL(string: xiaohongshuWebURL) {
            UIApplication.shared.open(webURL)
        }
    }
    
    // 获取状态颜色
    private func getStatusColor() -> Color {
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
    
    // 获取历史数据缓存状态
    private func getHistoricalCacheStatus() -> String {
        let count = CoreDataManager.shared.getHistoricalPriceCount()
        if count == 0 {
            return "无缓存"
        } else if count < 100 {
            return "部分缓存"
        } else {
            return "已缓存"
        }
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Supabase 数据统计卡片
struct SupabaseDataStatsCard: View {
    @State private var isLoading = false
    @State private var totalRecords = 0
    @State private var earliestDate: String?
    @State private var latestDate: String?
    @State private var connectionStatus = "未测试"
    @State private var statusColor: Color = .gray
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.cyan)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "cloud.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    )
                
                Text("Supabase 数据统计")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // 内容区域
            VStack(spacing: 12) {
                // 连接状态
                HStack {
                    Text("连接状态")
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        Text(connectionStatus)
                            .foregroundColor(statusColor)
                            .fontWeight(.medium)
                    }
                }
                
                if totalRecords > 0 {
                    Divider()
                    
                    // 总记录数
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.cyan)
                        Text("总记录数")
                        Spacer()
                        Text("~\(totalRecords) 天")
                            .foregroundColor(.secondary)
                    }
                    
                    // 最早日期
                    if let earliest = earliestDate {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.cyan)
                            Text("最早日期")
                            Spacer()
                            Text(earliest)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 最新日期
                    if let latest = latestDate {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.cyan)
                            Text("最新日期")
                            Spacer()
                            Text(latest)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 数据跨度
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.cyan)
                        Text("数据跨度")
                        Spacer()
                        Text("\(String(format: "%.1f", Double(totalRecords) / 365.0)) 年")
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // 操作按钮
                HStack(spacing: 12) {
                    Button(action: {
                        checkDataAvailability()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("刷新统计")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.cyan.opacity(0.1))
                        .foregroundColor(.cyan)
                        .cornerRadius(8)
                    }
                    .disabled(isLoading)
                    
                    Button(action: {
                        testConnection()
                    }) {
                        HStack {
                            Image(systemName: "network")
                            Text("测试连接")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                    .disabled(isLoading)
                }
                
                // 提示信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.cyan)
                            .font(.caption2)
                        Text("历史价格数据由 Supabase 云端提供")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption2)
                        Text("包含真实 USD/CNY 汇率和黄金价格")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
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
        .onAppear {
            // 初始化时自动检查一次
            checkDataAvailability()
        }
    }
    
    private func checkDataAvailability() {
        isLoading = true
        
        Task {
            let stats = await SupabaseGoldService.shared.checkDataAvailability()
            
            await MainActor.run {
                totalRecords = stats.totalRecords
                earliestDate = stats.earliestDate
                latestDate = stats.latestDate
                
                if stats.totalRecords > 0 {
                    connectionStatus = "已连接"
                    statusColor = .green
                } else {
                    connectionStatus = "无数据"
                    statusColor = .orange
                }
                
                isLoading = false
            }
        }
    }
    
    private func testConnection() {
        isLoading = true
        connectionStatus = "测试中..."
        statusColor = .gray
        
        Task {
            let success = await SupabaseGoldService.shared.testConnection()
            
            await MainActor.run {
                if success {
                    connectionStatus = "连接成功"
                    statusColor = .green
                } else {
                    connectionStatus = "连接失败"
                    statusColor = .red
                }
                isLoading = false
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(GoldPriceService.shared)
} 