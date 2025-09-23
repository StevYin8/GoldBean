//
//  GoldBeanApp.swift
//  GoldBean
//
//  Created by 尹少军 on 2025/9/23.
//

import SwiftUI

@main
struct GoldBeanApp: App {
    let persistenceController = CoreDataManager.shared
    let notificationManager = NotificationManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.context)
                .onAppear {
                    // 应用启动时初始化通知管理器
                    setupNotifications()
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
}
