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
                    
                    // 数据源设置模块
                    SettingsCard(
                        icon: "cloud.fill",
                        title: "数据源设置",
                        iconColor: .purple
                    ) {
                        Toggle("使用真实金价数据", isOn: $useRealData)
                            .onChange(of: useRealData) { newValue in
                                // 当用户切换数据源时，清除缓存并重新加载
                                goldPriceService.clearHistoryCache()
                                print(newValue ? "✅ 已切换到真实数据源" : "⚠️ 已切换到模拟数据源")
                            }
                        
                        Button("重新生成历史数据") {
                            goldPriceService.clearHistoryCache()
                            // 触发重新生成数据（通过刷新当前选中的时间范围）
                        }
                        .foregroundColor(.orange)
                        .font(.caption)
                        
                                                    VStack(alignment: .leading, spacing: 8) {
                                if useRealData {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                        Text("真实数据源：中国黄金集团官网")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text("直接从中国黄金集团官网实时抓取基础金价（www.chnau99999.com），数据100%真实")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.caption2)
                                        Text("无需API Key，每3分钟自动更新")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.top, 4)
                                } else {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                        Text("模拟数据源：仅供演示")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text("使用算法生成的模拟历史价格数据，仅供功能演示")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 8)
                    }
                    
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
}

#Preview {
    SettingsView()
        .environmentObject(GoldPriceService.shared)
} 