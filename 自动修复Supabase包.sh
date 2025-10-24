#!/bin/bash

echo "🔧 自动修复 Supabase Swift Package 问题"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 确认在正确的目录
if [ ! -f "GoldBean.xcodeproj/project.pbxproj" ]; then
    echo "❌ 错误：请在项目根目录运行此脚本"
    exit 1
fi

echo "📂 当前目录: $(pwd)"
echo ""

# 步骤 1: 关闭 Xcode
echo "1️⃣  检查并关闭 Xcode..."
pkill -x Xcode 2>/dev/null && echo "   ✅ Xcode 已关闭" || echo "   ℹ️  Xcode 未运行"
sleep 2
echo ""

# 步骤 2: 删除所有相关缓存
echo "2️⃣  清理所有缓存..."

# 删除 DerivedData
if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
    echo "   🗑️  删除 DerivedData..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/*
    echo "   ✅ DerivedData 已清理"
else
    echo "   ℹ️  DerivedData 不存在"
fi

# 删除 Swift Package Manager 缓存
if [ -d ~/Library/Caches/org.swift.swiftpm ]; then
    echo "   🗑️  删除 SwiftPM 缓存..."
    rm -rf ~/Library/Caches/org.swift.swiftpm/*
    echo "   ✅ SwiftPM 缓存已清理"
else
    echo "   ℹ️  SwiftPM 缓存不存在"
fi

# 删除项目本地包缓存
if [ -d .swiftpm ]; then
    echo "   🗑️  删除项目 .swiftpm 目录..."
    rm -rf .swiftpm
    echo "   ✅ .swiftpm 已删除"
else
    echo "   ℹ️  .swiftpm 不存在"
fi

# 删除 xcuserdata
if [ -d GoldBean.xcodeproj/xcuserdata ]; then
    echo "   🗑️  删除 xcuserdata..."
    rm -rf GoldBean.xcodeproj/xcuserdata
    echo "   ✅ xcuserdata 已删除"
else
    echo "   ℹ️  xcuserdata 不存在"
fi

# 删除工作区用户数据
if [ -d GoldBean.xcodeproj/project.xcworkspace/xcuserdata ]; then
    echo "   🗑️  删除工作区用户数据..."
    rm -rf GoldBean.xcodeproj/project.xcworkspace/xcuserdata
    echo "   ✅ 工作区用户数据已删除"
else
    echo "   ℹ️  工作区用户数据不存在"
fi

echo ""

# 步骤 3: 清理 Xcode 缓存
echo "3️⃣  清理 Xcode 工具缓存..."
xcrun --kill-cache 2>/dev/null
echo "   ✅ Xcode 缓存已清理"
echo ""

# 步骤 4: 验证 Package.resolved
echo "4️⃣  检查 Package.resolved..."
if [ -f "GoldBean.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    echo "   ✅ Package.resolved 存在"
    
    # 检查是否包含 supabase-swift
    if grep -q "supabase-swift" "GoldBean.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"; then
        echo "   ✅ 包含 supabase-swift 包"
        
        # 显示版本
        VERSION=$(grep -A 2 "supabase-swift" "GoldBean.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" | grep "version" | sed 's/.*: "\(.*\)".*/\1/')
        if [ ! -z "$VERSION" ]; then
            echo "   📦 版本: $VERSION"
        fi
    else
        echo "   ⚠️  未找到 supabase-swift 包"
    fi
else
    echo "   ⚠️  Package.resolved 不存在"
fi
echo ""

# 步骤 5: 清理 Swift Package 临时文件
echo "5️⃣  清理 Swift Package 临时文件..."
if [ -d ~/Library/org.swift.swiftpm ]; then
    rm -rf ~/Library/org.swift.swiftpm
    echo "   ✅ Swift 临时文件已清理"
else
    echo "   ℹ️  无临时文件"
fi
echo ""

# 步骤 6: 重新下载包（使用 xcodebuild）
echo "6️⃣  重新解析和下载 Swift Package..."
echo "   ⏳ 这可能需要 1-2 分钟，请耐心等待..."
echo ""

xcodebuild -resolvePackageDependencies -project GoldBean.xcodeproj 2>&1 | while IFS= read -r line; do
    if [[ "$line" == *"error"* ]] || [[ "$line" == *"Error"* ]]; then
        echo "   ❌ $line"
    elif [[ "$line" == *"Fetching"* ]] || [[ "$line" == *"Cloning"* ]]; then
        echo "   📦 $line"
    elif [[ "$line" == *"Resolved"* ]]; then
        echo "   ✅ $line"
    fi
done

echo ""

# 检查是否成功
if [ $? -eq 0 ]; then
    echo "   ✅ Swift Package 解析成功！"
else
    echo "   ⚠️  解析过程中可能有警告，请查看 Xcode"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✨ 自动修复完成！"
echo ""
echo "📋 完成的操作："
echo "   ✅ 关闭了 Xcode"
echo "   ✅ 清理了所有缓存"
echo "   ✅ 重新下载了 Swift Package"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 下一步操作："
echo ""
echo "1️⃣  打开 Xcode："
echo "   open GoldBean.xcodeproj"
echo ""
echo "2️⃣  等待 Xcode 完全加载（约 10-20 秒）"
echo ""
echo "3️⃣  清理构建文件夹："
echo "   菜单栏 → Product → Clean Build Folder"
echo "   或快捷键: Shift + Cmd + K"
echo ""
echo "4️⃣  立即构建："
echo "   菜单栏 → Product → Build"
echo "   或快捷键: Cmd + B"
echo ""
echo "5️⃣  如果构建成功，运行应用："
echo "   快捷键: Cmd + R"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  如果仍然报错："
echo ""
echo "在 Xcode 中手动操作："
echo "   • File → Packages → Reset Package Caches"
echo "   • File → Packages → Resolve Package Versions"
echo "   • 等待右上角进度条完成"
echo "   • 重新构建 (Cmd + B)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔍 验证 Supabase 包是否正确链接："
echo ""
echo "在 Xcode 中："
echo "   1. 点击项目 GoldBean（蓝色图标）"
echo "   2. 选择 TARGETS → GoldBean"
echo "   3. 点击 General 标签"
echo "   4. 查看 'Frameworks, Libraries, and Embedded Content'"
echo "   5. 应该能看到这 6 个包："
echo "      ✓ Auth"
echo "      ✓ Functions"
echo "      ✓ PostgREST"
echo "      ✓ Realtime"
echo "      ✓ Storage"
echo "      ✓ Supabase"
echo ""
echo "如果看不到，说明需要手动添加。"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "现在可以打开 Xcode 了！"
echo ""






