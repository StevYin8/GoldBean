#!/bin/bash

echo "🧹 开始完全清理 Xcode 缓存和构建数据..."
echo ""

# 1. 清理 DerivedData
echo "📂 清理 DerivedData..."
if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
    rm -rf ~/Library/Developer/Xcode/DerivedData/*
    echo "✅ DerivedData 已清理"
else
    echo "ℹ️  DerivedData 目录不存在"
fi

echo ""

# 2. 清理 Swift Package Manager 缓存
echo "📦 清理 Swift Package Manager 缓存..."
if [ -d ~/Library/Caches/org.swift.swiftpm ]; then
    rm -rf ~/Library/Caches/org.swift.swiftpm/*
    echo "✅ SwiftPM 缓存已清理"
else
    echo "ℹ️  SwiftPM 缓存目录不存在"
fi

echo ""

# 3. 清理项目本地构建
echo "🔨 清理项目本地构建..."
if [ -d .build ]; then
    rm -rf .build
    echo "✅ 项目 .build 目录已清理"
else
    echo "ℹ️  项目 .build 目录不存在"
fi

echo ""

# 4. 清理 Xcode 缓存
echo "🗑️  清理 Xcode 工具缓存..."
xcrun --kill-cache 2>/dev/null
echo "✅ Xcode 缓存已清理"

echo ""

# 5. 显示项目信息
echo "📋 项目信息："
echo "   路径: $(pwd)"
echo "   Info.plist: $(if [ -f GoldBean/Info.plist ]; then echo '✅ 存在'; else echo '❌ 不存在'; fi)"
echo ""

echo "✨ 清理完成！"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "下一步操作："
echo ""
echo "1️⃣  打开 Xcode"
echo "   open GoldBean.xcodeproj"
echo ""
echo "2️⃣  重新解析包依赖"
echo "   File → Packages → Reset Package Caches"
echo "   File → Packages → Resolve Package Versions"
echo ""
echo "3️⃣  检查 Target 链接"
echo "   项目 → TARGETS → GoldBean → General"
echo "   → Frameworks, Libraries, and Embedded Content"
echo "   → 添加 Supabase 所有 6 个产品"
echo ""
echo "4️⃣  修复 Info.plist"
echo "   Build Phases → Copy Bundle Resources"
echo "   → 移除 Info.plist（如果存在）"
echo ""
echo "5️⃣  清理并构建"
echo "   Shift + Cmd + K"
echo "   Cmd + R"
echo ""
echo "详细步骤请查看: 完整修复方案.md"
echo ""




