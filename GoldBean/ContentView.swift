//
//  ContentView.swift
//  GoldBean
//
//  Created by 尹少军 on 2025/9/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, CoreDataManager.shared.context)
}
