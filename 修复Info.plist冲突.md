# 修复 Info.plist 冲突错误

## 错误信息
```
Multiple commands produce '/Users/stev/Library/Developer/Xcode/DerivedData/GoldBean-xxx/Build/Products/Debug-iphoneos/GoldBean.app/Info.plist'
```

## 问题原因
Info.plist 文件被重复处理：
1. ❌ 被添加到了 "Copy Bundle Resources"（错误）
2. ✅ 在 Build Settings 中指定了路径（正确）

Xcode 不知道该使用哪一个，导致构建失败。

---

## 🎯 解决方案（2分钟）

### 方法一：移除 Copy Bundle Resources 中的 Info.plist（推荐）

1. **打开 Xcode 项目**
   ```bash
   open GoldBean.xcodeproj
   ```

2. **选择项目和 Target**
   - 点击左上角的 `GoldBean` 项目（蓝色图标）
   - 在中间选择 TARGETS → `GoldBean`

3. **打开 Build Phases**
   - 点击顶部的 `Build Phases` 标签

4. **展开 "Copy Bundle Resources"**
   - 找到并点击展开 `Copy Bundle Resources` 部分

5. **移除 Info.plist**
   - 在列表中找到 `Info.plist`
   - 选中它
   - 点击下方的 `-` 按钮删除
   - ⚠️ **重要**：这只是从构建阶段移除，不是删除文件

6. **确认 Build Settings 正确**
   - 点击 `Build Settings` 标签
   - 搜索 `info.plist`
   - 确认 `Info.plist File` 设置为：`GoldBean/Info.plist`

7. **清理并重新构建**
   - `Shift + Cmd + K` - 清理构建文件夹
   - `Cmd + R` - 重新运行

---

### 方法二：通过项目导航器移除（如果方法一找不到）

1. **在 Xcode 左侧项目导航栏**
   - 找到 `Info.plist` 文件
   - 右键点击它
   - 选择 `Delete`

2. **在删除对话框中**
   - ⚠️ **重要**：选择 `Remove Reference`（移除引用）
   - ❌ **不要选** `Move to Trash`（移到废纸篓）

3. **重新添加 Info.plist（正确方式）**
   - 右键点击 `GoldBean` 文件夹
   - 选择 `Add Files to "GoldBean"...`
   - 选择 `Info.plist`
   - ❌ **取消勾选** `Copy items if needed`
   - ✅ **勾选** `GoldBean` target
   - ⚠️ **重要**：在 "Add to targets" 下方，找到并 **取消勾选** `Copy Bundle Resources`

4. **配置 Build Settings**
   - 项目 → Build Settings → 搜索 `info.plist`
   - 设置 `Info.plist File` 为：`GoldBean/Info.plist`

5. **清理并构建**
   - `Shift + Cmd + K`
   - `Cmd + R`

---

### 方法三：手动编辑 project.pbxproj（高级）

如果上述方法不起作用，可以手动编辑项目文件：

1. **关闭 Xcode**

2. **编辑项目文件**
   ```bash
   # 打开项目配置文件
   open -e GoldBean.xcodeproj/project.pbxproj
   ```

3. **搜索并删除错误的引用**
   - 按 `Cmd + F` 搜索 `Info.plist`
   - 找到在 `PBXBuildFile` 和 `PBXResourcesBuildPhase` 中的 Info.plist 引用
   - 删除这些行（通常是包含 `Info.plist` 且在 `/* Resources */` 部分的行）

4. **保存并重新打开 Xcode**

---

## ✅ 验证修复

构建成功后应该看到：
```
Build Succeeded
```

不再有 "Multiple commands produce" 错误。

---

## 📋 最佳实践

### Info.plist 的正确配置方式

✅ **应该做的**：
- Info.plist 应该在项目目录中
- 只在 Build Settings 中设置 `Info.plist File` 路径
- Info.plist 应该在项目导航器中可见（但不在 Copy Bundle Resources 中）

❌ **不应该做的**：
- 不要把 Info.plist 添加到 Copy Bundle Resources
- 不要勾选 "Copy items if needed"（除非要真的复制文件）
- 不要有多个 Info.plist 文件

---

## 🔍 检查清单

- [ ] Info.plist 在项目导航器中可见
- [ ] Info.plist **不在** Build Phases → Copy Bundle Resources 中
- [ ] Build Settings → Info.plist File = `GoldBean/Info.plist`
- [ ] 清理构建文件夹 (`Shift + Cmd + K`)
- [ ] 重新构建成功 (`Cmd + R`)

---

## ⚠️ 常见问题

### Q: 我找不到 Info.plist 在 Copy Bundle Resources 中？
**A**: 可能在其他地方。搜索整个 Build Phases 的所有部分，或使用方法二完全重新添加。

### Q: 删除后构建还是失败？
**A**: 
1. 完全清理：`Shift + Cmd + Option + K`
2. 删除 DerivedData：
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/GoldBean-*
   ```
3. 重启 Xcode
4. 重新构建

### Q: 提示找不到 Info.plist？
**A**: 检查 Build Settings 中的路径是否正确：
- 应该是 `GoldBean/Info.plist`
- 不是 `./Info.plist` 或其他路径

---

## 🎯 快速命令

如果想完全清理并重新开始：

```bash
# 1. 清理 DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/GoldBean-*

# 2. 重新打开项目
open GoldBean.xcodeproj
```

然后按照方法一操作。

---

**完成后应该能正常构建了！** 🎉




