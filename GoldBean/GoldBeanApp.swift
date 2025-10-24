//
//  GoldBeanApp.swift
//  GoldBean
//
//  Created by 尹少军 on 2025/9/23.
//

import SwiftUI
import UIKit

// AppDelegate 用于控制屏幕方向
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // 强制锁定为竖屏方向
        return .portrait
    }
}

@main
struct GoldBeanApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let persistenceController = CoreDataManager.shared
    let notificationManager = NotificationManager.shared
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.context)
                .onAppear {
                    // 应用启动时初始化通知管理器
                    setupNotifications()
                    // 清除角标
                    clearBadge()
                }
                .onChange(of: scenePhase) { newPhase in
                    // 当应用进入前台（active）时清除角标
                    if newPhase == .active {
                        clearBadge()
                    }
                }
        }
    }
    
    private func setupNotifications() {
        // 检查通知权限
        notificationManager.checkNotificationPermission()
        
        // 如果用户之前开启了通知且有权限，重新安排每日通知
        if UserDefaults.standard.bool(forKey: "notificationsEnabled") && 
           notificationManager.notificationPermissionGranted {
            notificationManager.scheduleDaily8AMNotification()
        }
    }
    
    private func clearBadge() {
        // 清除 App 图标上的角标（小红点）
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
            print("🔵 已清除应用角标")
        }
    }
}
