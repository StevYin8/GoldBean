import Foundation
import Supabase

class SupabaseConfig {
    static let shared = SupabaseConfig()
    
    let client: SupabaseClient
    
    private init() {
        // Supabase 项目配置
        let supabaseURL = "https://fqckfusbjabhlmkogesv.supabase.co"
        
        // Supabase Anon Key (公开密钥)
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZxY2tmdXNiamFiaGxta29nZXN2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQwOTMzOTUsImV4cCI6MjA1OTY2OTM5NX0.M8dxBaMgMVT2N7FImizxqjDexicWxKBcFfVYZc9XYzs"
        
        client = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseKey
        )
        
        print("✅ Supabase 客户端初始化完成")
        print("🔗 URL: \(supabaseURL)")
    }
}


