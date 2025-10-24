#!/bin/bash

echo "🧹 清理 Xcode 构建缓存..."
echo ""

# 清理 DerivedData
DERIVED_DATA_PATH=~/Library/Developer/Xcode/DerivedData/GoldBean-*

if ls $DERIVED_DATA_PATH 1> /dev/null 2>&1; then
    echo "📂 找到 DerivedData 目录，正在删除..."
    rm -rf $DERIVED_DATA_PATH
    echo "✅ DerivedData 已清理"
else
    echo "ℹ️  未找到 DerivedData 目录（可能已清理）"
fi

echo ""
echo "✨ 清理完成！"
echo ""
echo "下一步："
echo "1. 打开 Xcode: open GoldBean.xcodeproj"
echo "2. 按 Shift + Cmd + K 清理构建文件夹"
echo "3. 按 Cmd + R 重新运行"
echo ""




