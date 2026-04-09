# Dotfiles - 模块化跨平台配置

**方案 B：结构化重组** - 保留你所有现有配置，增强跨平台支持

## 🎯 特性

- ✅ **保留所有现有工具**：Powerlevel10k, fasd, atuin, bun, pass, OpenClaw
- ✅ **模块化设计**：配置分模块管理，易于维护
- ✅ **跨平台支持**：Arch Linux, Ubuntu, WSL2, macOS
- ✅ **安全增强**：API Keys 使用 pass 管理，不再硬编码
- ✅ **80+ 别名**：涵盖 Git, Docker, Python, Node.js, 系统管理
- ✅ **30+ 函数**：实用的开发和运维函数
- ✅ **项目管理**：你的交易和开发项目快捷操作

## 📁 目录结构

```
dotfiles-advanced/
├── .chezmoi.toml.tmpl              # 主配置（系统检测）
├── dot_zshrc.tmpl                  # Zsh 入口文件
│
├── dot_config/zsh/                 # 模块化配置
│   ├── 00-env.zsh.tmpl            # 环境变量（跨平台）
│   ├── 10-path.zsh.tmpl           # PATH 配置
│   ├── 20-aliases.zsh.tmpl        # 别名（系统特定）
│   ├── 30-functions.zsh.tmpl      # 自定义函数
│   ├── 40-tools.zsh.tmpl          # 工具集成（保留你的配置）
│   ├── 50-projects.zsh.tmpl       # 项目特定配置
│   └── 99-local.zsh               # 本地配置（不提交）
│
└── README.md                       # 本文档
```

## 🚀 快速开始

### 前提条件

1. 已安装 Chezmoi
2. 已克隆你的 dotfiles 仓库

### 安装步骤

```bash
# 1. 备份当前配置
cp ~/.zshrc ~/.zshrc.backup
cp -r ~/.local/share/chezmoi ~/.local/share/chezmoi.backup

# 2. 进入 Chezmoi 源目录
chezmoi cd

# 3. 复制新配置文件
cp -r /path/to/dotfiles-advanced/* .

# 4. 查看将要应用的更改
exit
chezmoi diff

# 5. 应用配置
chezmoi apply -v

# 6. 重新加载
source ~/.zshrc
```

## 📊 相比原版的改进

### 1. 安全性提升

#### ❌ 原版问题
```bash
# API Keys 硬编码在 .zshrc 中
export GEMINI_API_KEY="AIzaSyDZ..."  # 不安全！
```

#### ✅ 新版方案
```bash
# 使用 pass 管理（00-env.zsh）
export GEMINI_API_KEY="$(pass show google/gemini/api)"
```

### 2. 跨平台支持

#### ❌ 原版问题
```bash
# 路径硬编码
export PATH="/home/jinzaizhichi/.cargo/bin:$PATH"
```

#### ✅ 新版方案
```bash
# 使用变量（10-path.zsh）
add_to_path "$HOME/.cargo/bin"  # 自动适配所有系统
```

### 3. 系统检测

自动根据系统加载不同配置：

```bash
{{- if .isArch }}
  # Arch 特定配置
{{- else if .isUbuntu }}
  # Ubuntu 特定配置
{{- else if .isMac }}
  # macOS 特定配置
{{- end }}
```

### 4. 模块化管理

原版所有配置在一个文件，新版分模块：

- `00-env.zsh` - 环境变量
- `10-path.zsh` - PATH 配置
- `20-aliases.zsh` - 别名
- `30-functions.zsh` - 函数
- `40-tools.zsh` - 工具集成
- `50-projects.zsh` - 项目配置

## 🔧 配置模块说明

### 00-env.zsh - 环境变量

包含：
- 语言设置（LANG, LC_ALL）
- 编辑器配置（EDITOR=nvim）
- XDG Base Directory
- API Keys（使用 pass）
- WSL/macOS 特定环境变量

### 10-path.zsh - PATH 配置

智能 PATH 管理：
- 避免重复添加
- 按优先级排序
- 系统特定路径

### 20-aliases.zsh - 别名

80+ 别名，包括：
- Git（gs, ga, gc, gp, gl...）
- Docker（dps, dlog, dexec, dclean...）
- Python（py, venv, activate, pipi...）
- Node.js（ni, nr, ns, nt...）
- 系统管理（update, install, remove...）
- 项目跳转（cdtv, cdopt, cdbot...）

### 30-functions.zsh - 自定义函数

30+ 实用函数：
- `mkcd` - 创建并进入目录
- `pyproject` - 创建 Python 项目
- `flask-dev` - 启动 Flask 开发服务器
- `docker-cleanup` - 清理 Docker 资源
- `port` - 查看端口占用
- `extract` - 解压任意格式
- `backup` - 快速备份文件

### 40-tools.zsh - 工具集成

保留你所有现有工具：
- ✅ Powerlevel10k（美化终端）
- ✅ fasd（快速跳转）
- ✅ atuin（历史记录搜索）
- ✅ bun（JavaScript 运行时）
- ✅ broot（目录导航）
- ✅ OpenClaw（你的工具）
- ✅ 所有快捷键绑定

### 50-projects.zsh - 项目配置

你的项目管理：
- `start-tv-chart` - 启动 TradingView 图表
- `start-options-tracker` - 启动期权追踪器
- `start-tg-bot` - 启动 Telegram 机器人
- `check-all-projects` - 检查所有项目状态
- `sync-to-vps` - 同步到 VPS
- `backup-projects` - 备份所有项目

## 🎓 使用示例

### 项目管理

```bash
# 快速跳转
cdtv           # 进入 tv-chart 项目
cdopt          # 进入 options-tracker 项目

# 启动服务
start-tv-chart           # 启动图表开发服务器
start-options-tracker    # 启动期权追踪器

# 检查状态
check-all-projects       # 检查所有项目 Git 状态
pull-all-projects        # 拉取所有项目
```

### Docker 管理

```bash
dps            # docker ps
dlog nginx     # docker logs -f nginx
denter app     # 进入容器
dclean         # 清理所有资源
```

### Python 开发

```bash
pyproject myapp      # 创建完整项目结构
venv                 # 创建虚拟环境
activate             # 激活虚拟环境
flask-dev 5000       # 启动 Flask（端口 5000）
```

### Git 工作流

```bash
gs               # git status
ga .             # git add .
gcm "feat: xxx"  # git commit -m
gp               # git push
gl               # 漂亮的 git log
```

## 🔐 安全最佳实践

### 1. 使用 pass 管理 API Keys

```bash
# 初始化 pass（首次）
pass init your-gpg-key-id

# 存储 API Key
pass insert google/gemini/api
pass insert openai/api
pass insert aws/jinzaizhichi/aws_access_key_id
pass insert aws/jinzaizhichi/aws_secret_access_key

# 在配置中使用
export GEMINI_API_KEY="$(pass show google/gemini/api)"
```

### 2. 本地敏感配置

使用 `~/.config/zsh/99-local.zsh`（不提交到 Git）：

```bash
# 99-local.zsh
export LOCAL_API_KEY="your-secret-key"
alias local-server='ssh user@your-server'
```

### 3. Chezmoi 加密

```bash
# 加密敏感文件
chezmoi add --encrypt ~/.ssh/id_ed25519
```

## 📱 跨平台使用

### Arch Linux (当前)

所有功能完整支持。

### Ubuntu

```bash
# 包管理器自动切换
update    # sudo apt update && sudo apt upgrade
install   # sudo apt install
```

### WSL2

```bash
# 自动检测 WSL 环境
open .          # explorer.exe .
clip            # clip.exe
wsl-restart     # 重启 WSL
```

### macOS（准备）

```bash
# Homebrew 包管理
update    # brew update && brew upgrade
install   # brew install

# macOS 特定别名
flush     # 刷新 DNS
show      # 显示隐藏文件
```

## 🔄 升级和维护

### 编辑配置

```bash
# 编辑主配置
chezmoi edit ~/.zshrc

# 编辑模块
chezmoi edit ~/.config/zsh/20-aliases.zsh

# 应用更改
chezmoi apply

# 重新加载
source ~/.zshrc
```

### 更新和同步

```bash
# 拉取远程更新
chezmoi update

# 提交本地更改
chezmoi cd
git add .
git commit -m "feat: add new alias"
git push
exit
```

### 添加新功能

1. 编辑对应模块
2. 测试功能
3. 提交到 Git

```bash
# 例如：添加新别名
chezmoi edit ~/.config/zsh/20-aliases.zsh
# 添加: alias myalias='echo "test"'
chezmoi apply
source ~/.zshrc
myalias  # 测试

# 提交
chezmoi cd
git add dot_config/zsh/20-aliases.zsh.tmpl
git commit -m "feat: add myalias"
git push
```

## 📝 常见问题

### Q: 如何查看当前系统类型？

```bash
echo "OS: {{ .chezmoi.os }}"
echo "Distro: {{ .chezmoi.osRelease.id }}"
echo "User: {{ .name }}"
```

### Q: 如何禁用某个模块？

注释掉 `.zshrc` 中的加载行：

```bash
# [ -f "$ZSH_CONFIG_DIR/50-projects.zsh" ] && source "$ZSH_CONFIG_DIR/50-projects.zsh"
```

### Q: 如何在 macOS 上使用？

配置会自动检测 macOS 并加载对应的设置。只需：

```bash
# 1. 安装 Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. 安装 Chezmoi
brew install chezmoi

# 3. 初始化
chezmoi init https://github.com/jinzaizhichi/dotfiles.git
chezmoi apply
```

## 🎉 总结

这个配置：
- ✅ 保留了你所有现有的工具和习惯
- ✅ 提升了安全性（API Keys 使用 pass）
- ✅ 支持跨平台（Arch, Ubuntu, WSL, macOS）
- ✅ 模块化设计（易于维护和扩展）
- ✅ 增加了 80+ 实用别名和 30+ 函数
- ✅ 项目管理功能完善

**开始使用吧！** 🚀
