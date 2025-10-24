#!/bin/bash

# 照片功能修复验证脚本
# 用于验证 Info.plist 配置是否正确

echo "🔍 开始验证照片功能修复..."
echo ""

# 检查 Info.plist 文件是否存在
INFO_PLIST="GoldBean/Info.plist"

if [ -f "$INFO_PLIST" ]; then
    echo "✅ Info.plist 文件存在"
else
    echo "❌ Info.plist 文件不存在"
    echo "   路径: $INFO_PLIST"
    exit 1
fi

echo ""
echo "📋 检查必需的权限配置..."
echo ""

# 检查照片库权限
if grep -q "NSPhotoLibraryUsageDescription" "$INFO_PLIST"; then
    echo "✅ 照片库访问权限已配置"
    PHOTO_DESC=$(grep -A 1 "NSPhotoLibraryUsageDescription" "$INFO_PLIST" | tail -1 | sed 's/<[^>]*>//g' | xargs)
    echo "   描述: $PHOTO_DESC"
else
    echo "❌ 照片库访问权限未配置"
fi

echo ""

# 检查相机权限
if grep -q "NSCameraUsageDescription" "$INFO_PLIST"; then
    echo "✅ 相机访问权限已配置"
    CAMERA_DESC=$(grep -A 1 "NSCameraUsageDescription" "$INFO_PLIST" | tail -1 | sed 's/<[^>]*>//g' | xargs)
    echo "   描述: $CAMERA_DESC"
else
    echo "❌ 相机访问权限未配置"
fi

echo ""

# 检查照片库添加权限
if grep -q "NSPhotoLibraryAddUsageDescription" "$INFO_PLIST"; then
    echo "✅ 照片库添加权限已配置"
    ADD_DESC=$(grep -A 1 "NSPhotoLibraryAddUsageDescription" "$INFO_PLIST" | tail -1 | sed 's/<[^>]*>//g' | xargs)
    echo "   描述: $ADD_DESC"
else
    echo "⚠️  照片库添加权限未配置（可选）"
fi

echo ""
echo "📱 检查相关源文件..."
echo ""

# 检查 ImagePicker.swift
if [ -f "GoldBean/Views/ImagePicker.swift" ]; then
    echo "✅ ImagePicker.swift 存在"
    
    # 检查是否导入了必要的框架
    if grep -q "import Photos" "GoldBean/Views/ImagePicker.swift"; then
        echo "   ✅ 已导入 Photos 框架"
    else
        echo "   ⚠️  未导入 Photos 框架"
    fi
    
    if grep -q "import AVFoundation" "GoldBean/Views/ImagePicker.swift"; then
        echo "   ✅ 已导入 AVFoundation 框架"
    else
        echo "   ⚠️  未导入 AVFoundation 框架"
    fi
    
    if grep -q "checkPhotoLibraryPermission" "GoldBean/Views/ImagePicker.swift"; then
        echo "   ✅ 包含照片库权限检查方法"
    else
        echo "   ⚠️  未包含照片库权限检查方法"
    fi
    
    if grep -q "checkCameraPermission" "GoldBean/Views/ImagePicker.swift"; then
        echo "   ✅ 包含相机权限检查方法"
    else
        echo "   ⚠️  未包含相机权限检查方法"
    fi
else
    echo "❌ ImagePicker.swift 不存在"
fi

echo ""
echo "🎯 验证结果总结"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 统计验证结果
TOTAL_CHECKS=5
PASSED_CHECKS=0

[ -f "$INFO_PLIST" ] && ((PASSED_CHECKS++))
grep -q "NSPhotoLibraryUsageDescription" "$INFO_PLIST" && ((PASSED_CHECKS++))
grep -q "NSCameraUsageDescription" "$INFO_PLIST" && ((PASSED_CHECKS++))
[ -f "GoldBean/Views/ImagePicker.swift" ] && ((PASSED_CHECKS++))
grep -q "checkPhotoLibraryPermission" "GoldBean/Views/ImagePicker.swift" 2>/dev/null && ((PASSED_CHECKS++))

echo "通过检查: $PASSED_CHECKS/$TOTAL_CHECKS"

if [ $PASSED_CHECKS -eq $TOTAL_CHECKS ]; then
    echo ""
    echo "🎉 所有检查通过！"
    echo ""
    echo "下一步操作："
    echo "1. 在 Xcode 中打开项目"
    echo "2. 将 Info.plist 添加到项目中"
    echo "3. 配置 Build Settings 中的 Info.plist File 路径"
    echo "4. 清理并重新编译 (Shift + Cmd + K, 然后 Cmd + R)"
    echo ""
    echo "详细步骤请查看: PHOTO_CRASH_FIX_STEPS.md"
else
    echo ""
    echo "⚠️  部分检查未通过，请检查上述输出"
fi

echo ""




