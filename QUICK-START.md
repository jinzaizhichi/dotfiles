# 🚀 快速修复指南

## 📥 下载文件到你的 WSL Arch 系统

在你的 **WSL Arch Linux** (用户: jinzaizhichi) 中运行：

```bash
# 进入家目录
cd ~

# 下载修复脚本（从你下载的文件中）
# 假设你已经下载了这些文件

# 给脚本执行权限
chmod +x chezmoi-fix-all.sh
```

## ⚡ 一键诊断和修复

```bash
# 运行一键修复脚本
bash chezmoi-fix-all.sh
```

这个脚本会：

1. ✅ 检查系统信息
2. ✅ 检查 Chezmoi 是否安装（没有则自动安装）
3. ✅ 检查 Chezmoi 是否初始化（没有则提示初始化）
4. ✅ 检查配置文件状态（符号链接 vs 普通文件）
5. ✅ 检查本地配置和仓库的差异
6. ✅ 提供修复选项（保留本地修改或恢复仓库版本）

## 🎯 预期结果

### 如果有差异（你的情况）

脚本会显示：

```
⚠️  检测到配置差异！

[1] 保留本地修改，同步到 Chezmoi 仓库 (推荐)
[2] 从 Chezmoi 仓库恢复配置 (丢失本地修改)
[3] 仅查看完整差异
[4] 跳过修复，稍后手动处理

请选择 (1/2/3/4):
```

**选择 1（推荐）**：
- 会将你在 .zshrc 中的修改同步到 Chezmoi
- 提示你提交到 Git
- 推送到 GitHub

**选择 2（谨慎）**：
- 会丢失你的本地修改
- 从 GitHub 恢复配置
- 但会先备份你的当前配置

### 如果没有差异

```
✅ 没有差异！配置已同步
```

然后可以考虑升级到增强版配置。

## 📝 手动操作（如果需要）

如果脚本运行有问题，可以手动操作：

### 1. 检查 Chezmoi 状态

```bash
# 查看 Chezmoi 是否安装
which chezmoi

# 查看管理的文件
chezmoi managed

# 查看差异
chezmoi diff
```

### 2. 同步本地修改到 Chezmoi

```bash
# 重新添加修改的文件
chezmoi re-add ~/.zshrc
chezmoi re-add ~/.bashrc
chezmoi re-add ~/.gitconfig

# 进入 Chezmoi 源目录
chezmoi cd

# 查看 Git 状态
git status

# 提交
git add .
git commit -m "chore: sync local changes"
git push

# 退出
exit
```

### 3. 从 Chezmoi 恢复（如果需要）

```bash
# 备份当前配置
cp ~/.zshrc ~/.zshrc.backup
cp ~/.bashrc ~/.bashrc.backup

# 强制应用 Chezmoi 配置
chezmoi apply --force

# 重新加载
source ~/.zshrc
```

## 🎓 正确的使用方式

### ❌ 以前的错误方式

```bash
vim ~/.zshrc          # 直接编辑
# 修改...
source ~/.zshrc
# 问题: 没有同步到 Chezmoi 和 GitHub
```

### ✅ 正确的方式

```bash
chezmoi edit ~/.zshrc  # 通过 Chezmoi 编辑
# 修改...
chezmoi apply          # 应用更改
source ~/.zshrc        # 重新加载
```

### 🚀 更好的方式（启用自动提交）

编辑 Chezmoi 配置：

```bash
chezmoi edit ~/.local/share/chezmoi/.chezmoi.toml.tmpl
```

添加：

```toml
[git]
    autoCommit = true
    autoPush = true
```

然后：

```bash
chezmoi edit ~/.zshrc  # 编辑
chezmoi apply          # 会自动提交和推送！
source ~/.zshrc
```

## 🔍 其他脚本

如果你想分步操作：

1. **check-chezmoi-sync.sh** - 仅诊断，不修复
2. **sync-chezmoi-config.sh** - 手动选择同步方式
3. **chezmoi-fix-all.sh** - 一键完成所有操作（推荐）

## 💡 常见问题

### Q: 如何查看我修改了什么？

```bash
chezmoi diff
```

### Q: 如何撤销本地修改？

```bash
chezmoi apply --force
```

### Q: 如何查看 Chezmoi 源目录？

```bash
chezmoi cd
ls -la
exit
```

### Q: 如何从 GitHub 拉取最新配置？

```bash
chezmoi update
```

## 📦 升级到增强版

修复同步问题后，可以升级：

```bash
# 解压增强版配置
tar -xzf chezmoi-enhanced.tar.gz

# 查看迁移指南
cat chezmoi-enhanced/MIGRATION.md

# 按照指南操作
```

---

**现在就运行**: `bash chezmoi-fix-all.sh` 🚀
