import Foundation
import UserNotifications
import Combine
import UIKit

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notificationPermissionGranted = false
    @Published var permissionRequestResult: String = "" // 用于显示权限请求结果
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        checkNotificationPermission()
    }
    
    // MARK: - 权限管理
    
    func requestNotificationPermission() {
        // 清除之前的结果消息
        permissionRequestResult = ""
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.notificationPermissionGranted = granted
                if granted {
                    print("✅ 通知权限已获得")
                    self?.permissionRequestResult = "通知权限已开启，每日8点将推送金价"
                    self?.scheduleDaily8AMNotification()
                } else {
                    print("❌ 通知权限被拒绝")
                    self?.permissionRequestResult = "通知权限被拒绝，无法推送每日金价"
                }
                
                if let error = error {
                    print("通知权限请求错误: \(error.localizedDescription)")
                    self?.permissionRequestResult = "权限请求出错：\(error.localizedDescription)"
                }
                
                // 3秒后清除结果消息
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self?.permissionRequestResult = ""
                }
            }
        }
    }
    
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - 每日定时通知
    
    func scheduleDaily8AMNotification() {
        // 首先移除之前的通知
        removeDailyNotification()
        
        guard notificationPermissionGranted else {
            print("❌ 无通知权限，无法安排定时通知")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "📈 今日金价更新"
        content.body = "正在为您获取最新金价..."
        content.sound = .default
        content.badge = 1
        
        // 设置为每天早上8点
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyGoldPrice", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 安排每日通知失败: \(error.localizedDescription)")
            } else {
                print("✅ 每日8点金价通知已安排")
            }
        }
        
        // 设置通知中心代理
        UNUserNotificationCenter.current().delegate = self
    }
    
    func removeDailyNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyGoldPrice"])
        print("🗑️ 已移除旧的每日通知")
    }
    
    // MARK: - 即时金价通知
    
    func sendGoldPriceNotification(price: Double, source: String) {
        guard notificationPermissionGranted else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "💰 今日金价"
        content.body = "当前金价：¥\(String(format: "%.2f", price))/克\n数据来源：\(source)"
        content.sound = .default
        content.badge = 1
        
        // 立即发送
        let request = UNNotificationRequest(identifier: "goldPriceUpdate_\(Date().timeIntervalSince1970)", content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 发送金价通知失败: \(error.localizedDescription)")
            } else {
                print("✅ 金价通知已发送: ¥\(String(format: "%.2f", price))/克")
            }
        }
    }
    
    // MARK: - 通知设置管理
    
    func enableDailyNotifications() {
        if notificationPermissionGranted {
            scheduleDaily8AMNotification()
            userDefaults.set(true, forKey: "dailyNotificationsEnabled")
        } else {
            requestNotificationPermission()
        }
    }
    
    func disableDailyNotifications() {
        removeDailyNotification()
        userDefaults.set(false, forKey: "dailyNotificationsEnabled")
        print("🔕 每日通知已关闭")
    }
    
    func isDailyNotificationsEnabled() -> Bool {
        return userDefaults.bool(forKey: "dailyNotificationsEnabled") && notificationPermissionGranted
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    
    // 应用在前台时接收到通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // 如果是每日金价通知，触发获取最新金价
        if notification.request.identifier == "dailyGoldPrice" {
            fetchLatestGoldPriceForNotification()
        }
        
        // 在前台显示通知
        completionHandler([.banner, .sound, .badge])
    }
    
    // 用户点击通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("📱 用户点击了通知: \(response.notification.request.identifier)")
        
        // 清除角标
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        completionHandler()
    }
    
    // MARK: - 私有方法
    
    private func fetchLatestGoldPriceForNotification() {
        print("🔄 触发每日8点金价获取...")
        
        // 获取最新金价
        GoldPriceService.shared.fetchGoldPrice(isAutoUpdate: true)
        
        // 监听价格更新
        GoldPriceService.shared.$currentPrice
            .combineLatest(GoldPriceService.shared.$isLoading, GoldPriceService.shared.$hasValidData)
            .sink { [weak self] price, isLoading, hasValidData in
                // 当加载完成且有有效数据时发送通知
                if !isLoading && hasValidData && price > 0 {
                    let source = GoldPriceService.shared.priceSource
                    self?.sendGoldPriceNotification(price: price, source: source)
                }
            }
            .store(in: &cancellables)
    }
} 