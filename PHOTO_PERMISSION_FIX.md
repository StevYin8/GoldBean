# 照片功能闪退问题修复指南

## 问题原因
应用在访问照片库或相机时闪退，是因为缺少必要的隐私权限描述。iOS 要求所有访问敏感数据（如照片、相机）的应用必须在 Info.plist 中声明使用原因。

## 解决方案

### 方法一：通过 Xcode 图形界面添加（推荐）

1. **打开 Xcode 项目**
   - 双击打开 `GoldBean.xcodeproj`

2. **选择项目目标**
   - 在左侧导航栏中选择 `GoldBean` 项目（最上面的蓝色图标）
   - 在中间区域的 TARGETS 列表中选择 `GoldBean`

3. **添加隐私权限**
   - 点击顶部的 `Info` 标签页
   - 找到 `Custom iOS Target Properties` 区域
   - 点击 `+` 按钮添加以下两项：

   **第一项：照片库访问权限**
   - Key: `Privacy - Photo Library Usage Description`
   - Value: `需要访问您的照片库以保存和查看黄金饰品照片`

   **第二项：相机访问权限**
   - Key: `Privacy - Camera Usage Description`
   - Value: `需要使用相机拍摄黄金饰品照片`

4. **保存并重新运行**
   - 按 `Cmd + S` 保存
   - 按 `Cmd + R` 重新编译运行应用

### 方法二：手动创建 Info.plist 文件

如果 Xcode 项目没有 Info 标签页，可以手动创建 Info.plist 文件：

1. 在 `GoldBean` 文件夹中创建 `Info.plist` 文件
2. 添加以下内容：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>需要访问您的照片库以保存和查看黄金饰品照片</string>
    <key>NSCameraUsageDescription</key>
    <string>需要使用相机拍摄黄金饰品照片</string>
</dict>
</plist>
```

3. 在 Xcode 项目设置中指定 Info.plist 路径
   - 选择项目 > Build Settings
   - 搜索 "Info.plist"
   - 设置 `Info.plist File` 为 `GoldBean/Info.plist`

## 验证修复

修复后，当您点击"添加照片"按钮时：
1. **第一次使用**：系统会弹出权限请求对话框，询问是否允许访问照片库/相机
2. **点击"允许"**：即可正常使用照片功能
3. **应用不再闪退**

## 权限说明

添加的两个权限：

| 权限 Key | 英文名称 | 用途 |
|---------|---------|------|
| NSPhotoLibragyUsageDescription | Privacy - Photo Library Usage Description | 访问照片库选择图片 |
| NSCameraUsageDescription | Privacy - Camera Usage Description | 使用相机拍摄照片 |

## 注意事项

1. 权限描述文本会显示给用户，应该清楚说明为什么需要这个权限
2. 如果用户拒绝权限，应用仍可正常使用，只是无法使用照片功能
3. 用户可以稍后在 iOS 设置中修改权限

## 测试清单

- [ ] 应用启动不闪退
- [ ] 点击"添加照片"按钮，显示权限请求对话框
- [ ] 允许权限后，可以选择"拍照"
- [ ] 允许权限后，可以选择"从相册选择"
- [ ] 成功选择照片后，照片显示在界面上
- [ ] 可以保存带照片的记录

## 问题排查

如果修复后仍然闪退：
1. 完全卸载应用后重新安装
2. 检查 Xcode 控制台的错误信息
3. 确认 Info.plist 文件已正确添加到项目中
4. 清理项目：Product > Clean Build Folder (Shift + Cmd + K)




