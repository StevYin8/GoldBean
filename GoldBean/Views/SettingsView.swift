import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var goldPriceService: GoldPriceService
    @StateObject private var notificationManager = NotificationManager.shared
    @AppStorage("currencyUnit") private var currencyUnit: String = "CNY"
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("apiKey") private var apiKey: String = ""
    
    @State private var showingAPIKeyAlert = false
    @State private var tempAPIKey = ""
    @State private var showingRefreshConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("价格设置")) {
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
                    
                    if goldPriceService.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("正在更新...")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 显示错误消息（包括今日已更新提示）
                    if let errorMessage = goldPriceService.errorMessage {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text(errorMessage)
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                }
                
                // Section(header: Text("显示设置")) {
                //     Picker("货币单位", selection: $currencyUnit) {
                //         Text("人民币 (CNY)").tag("CNY")
                //         Text("美元 (USD)").tag("USD")
                //     }
                //     .pickerStyle(SegmentedPickerStyle())
                // }
                
                Section(header: Text("通知设置")) {
                    Toggle("价格更新通知", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            handleNotificationToggle(newValue)
                        }
                    
                    if notificationsEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("每日早上8:00自动获取金价并推送")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: notificationManager.notificationPermissionGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundColor(notificationManager.notificationPermissionGranted ? .green : .orange)
                                        .font(.caption)
                                    
                                    Text(notificationManager.notificationPermissionGranted ? "通知权限已授予" : "需要通知权限")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
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
                                        .padding(.top, 2)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("关于")) {
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
                    
                    Button("小红书") {
                        // 打开小红书链接
                    }
                    .foregroundColor(.red)
                }
            }
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