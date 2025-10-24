# Xcode 配置指南 - 添加相机和相册权限

## 📱 必需配置

为了使用图片拍摄和选择功能，需要在Xcode项目中添加隐私权限说明。

## 🔧 配置步骤

### 方法1：通过Xcode界面配置（推荐）

1. **打开项目**
   - 在Xcode中打开 `GoldBean.xcodeproj`

2. **选择Target**
   - 在左侧项目导航中，点击顶部的 `GoldBean` 项目
   - 在 TARGETS 列表中选择 `GoldBean`

3. **进入Info标签页**
   - 点击顶部的 `Info` 标签

4. **添加权限说明**
   - 在 `Custom iOS Target Properties` 区域
   - 点击任意一行后面的 `+` 按钮添加新条目

5. **添加以下三个权限**：

   **相机权限**
   - Key: `Privacy - Camera Usage Description`
   - Type: `String`
   - Value: `需要使用相机拍摄黄金饰品照片，方便您记录和管理您的黄金资产`

   **相册访问权限**
   - Key: `Privacy - Photo Library Usage Description`
   - Type: `String`
   - Value: `需要访问相册以选择黄金饰品照片，方便您记录和管理您的黄金资产`

   **相册添加权限**（可选）
   - Key: `Privacy - Photo Library Additions Usage Description`
   - Type: `String`
   - Value: `需要保存照片到相册`

### 方法2：直接编辑Info.plist源码

如果你的项目有Info.plist文件，可以直接添加以下内容：

```xml
<key>NSCameraUsageDescription</key>
<string>需要使用相机拍摄黄金饰品照片，方便您记录和管理您的黄金资产</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册以选择黄金饰品照片，方便您记录和管理您的黄金资产</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要保存照片到相册</string>
```

## ✅ 验证配置

配置完成后：

1. 运行应用
2. 尝试添加记录并选择"拍照"或"从相册选择"
3. 系统会弹出权限请求对话框
4. 允许权限后即可正常使用

## ⚠️ 注意事项

1. **模拟器相机功能**
   - iOS模拟器不支持真实相机
   - 可以从相册选择图片测试
   - 建议使用真机测试完整功能

2. **权限说明要求**
   - 必须提供清晰的权限使用说明
   - 说明文字要符合Apple审核要求
   - 不能使用模糊或误导性的描述

3. **App Store审核**
   - 确保权限说明与实际功能相符
   - 只在需要时请求权限
   - 提供良好的权限拒绝处理

## 🚀 构建和运行

配置完成后：

```bash
# 清理构建
xcodebuild clean

# 重新构建
xcodebuild -project GoldBean.xcodeproj -scheme GoldBean build

# 或者在Xcode中直接运行（推荐）
# Command + R
```

## 📸 功能测试清单

- [ ] 相机权限请求正常显示
- [ ] 相册权限请求正常显示
- [ ] 拍照功能正常工作
- [ ] 相册选择功能正常工作
- [ ] 图片裁剪功能正常工作
- [ ] 图片保存到CoreData成功
- [ ] 图片在列表中正确显示
- [ ] 图片全屏查看功能正常
- [ ] 删除记录时图片一起删除

---

**配置完成后即可正常使用图片功能！**


