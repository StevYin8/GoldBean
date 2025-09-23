import SwiftUI

struct MainTabView: View {
    @StateObject private var goldPriceService = GoldPriceService.shared
    
    var body: some View {
        TabView {
            OverviewView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("总览")
                }
            
            GoldRecordListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("记录")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("设置")
                }
        }
        .accentColor(.orange)
        .environmentObject(goldPriceService)
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, CoreDataManager.shared.context)
} 