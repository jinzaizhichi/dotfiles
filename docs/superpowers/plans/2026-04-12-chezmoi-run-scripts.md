# chezmoi run_ 自动化脚本 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 通过 chezmoi `run_` 脚本机制，让新机器执行 `chezmoi init --apply` 后自动完成全部环境初始化，无需任何手动步骤。

**Architecture:** 四个脚本按数字前缀顺序执行：系统包 → oh-my-zsh → curl 类工具 → zsh 插件。`run_once_` 用哈希标记确保只运行一次，`run_onchange_` 在插件列表变动时自动重装。

**Tech Stack:** bash, chezmoi template engine (Go templates), pacman/yay, apt, Homebrew

---

## 文件清单

| 操作 | 文件路径 |
|---|---|
| 新建 | `run_once_10-packages.sh.tmpl` |
| 新建 | `run_once_20-oh-my-zsh.sh` |
| 新建 | `run_once_30-cli-tools.sh` |
| 新建 | `run_onchange_40-zsh-plugins.sh.tmpl` |
| 修改 | `README.md` |

---

## Task 1: 系统包安装脚本

**Files:**
- Create: `run_once_10-packages.sh.tmpl`

### 背景

此脚本用 chezmoi 模板语法区分平台，渲染后是纯 bash。chezmoi 以渲染后内容的 SHA256 hash 判断是否已执行过。

- [ ] **Step 1: 在 chezmoi source directory 创建文件**

```bash
cd ~/.local/share/chezmoi
```

- [ ] **Step 2: 写入脚本内容**

创建文件 `run_once_10-packages.sh.tmpl`，内容如下：

```bash
#!/bin/bash
# 系统包安装脚本
# 为什么用 run_once_：包管理器安装只需做一次，后续用 update 命令维护
set -e

echo "==> [10-packages] 安装系统包..."

{{ if .isMac -}}
# ============================================================
# macOS - Homebrew
# ============================================================

# 安装 Homebrew（如果不存在）
if ! command -v brew &>/dev/null; then
    echo "安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 安装核心工具
brew install \
    git curl wget \
    zsh neovim \
    fzf zoxide direnv \
    atuin fasd \
    ripgrep fd bat eza \
    htop jq \
    pass gnupg \
    gh \
    pyenv

{{ else if .isArch -}}
# ============================================================
# Arch Linux - pacman + yay
# ============================================================

# 确保 yay 已安装（AUR helper）
if ! command -v yay &>/dev/null; then
    echo "安装 yay..."
    sudo pacman -S --noconfirm --needed git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
    rm -rf /tmp/yay
fi

# pacman 官方源
sudo pacman -S --noconfirm --needed \
    git curl wget \
    zsh neovim \
    fzf direnv \
    ripgrep fd bat eza \
    htop jq \
    pass gnupg \
    github-cli

# AUR 包
yay -S --noconfirm --needed \
    zoxide \
    atuin \
    fasd

{{ else if .isUbuntu -}}
# ============================================================
# Ubuntu / WSL2 - apt + 手动安装
# ============================================================

sudo apt-get update -qq

# 核心工具（apt 直接安装）
sudo apt-get install -y \
    git curl wget \
    zsh \
    fzf direnv \
    ripgrep fd-find bat \
    htop jq \
    pass gnupg \
    software-properties-common apt-transport-https ca-certificates

# fd 在 Ubuntu 里叫 fd-find，建立软链
if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
fi

# bat 在 Ubuntu 里叫 batcat，建立软链
if ! command -v bat &>/dev/null && command -v batcat &>/dev/null; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
fi

# neovim - 使用官方 unstable PPA 获取最新版
if ! command -v nvim &>/dev/null; then
    echo "安装 neovim..."
    sudo add-apt-repository -y ppa:neovim-ppa/unstable
    sudo apt-get update -qq
    sudo apt-get install -y neovim
fi

# GitHub CLI - 使用官方 apt 源
if ! command -v gh &>/dev/null; then
    echo "安装 GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y gh
fi

# eza - 官方安装方式
if ! command -v eza &>/dev/null; then
    echo "安装 eza..."
    sudo apt-get install -y gpg
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
        | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
        | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo apt-get update -qq
    sudo apt-get install -y eza
fi

# zoxide - 官方安装脚本
if ! command -v zoxide &>/dev/null; then
    echo "安装 zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

# atuin - 官方安装脚本
if ! command -v atuin &>/dev/null; then
    echo "安装 atuin..."
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
fi

# fasd - 从源码安装
if ! command -v fasd &>/dev/null; then
    echo "安装 fasd..."
    git clone https://github.com/clvv/fasd.git /tmp/fasd
    sudo make -C /tmp/fasd install
    rm -rf /tmp/fasd
fi

{{ end -}}

echo "==> [10-packages] 完成 ✓"
```

- [ ] **Step 3: 验证模板语法正确**

```bash
chezmoi execute-template < ~/.local/share/chezmoi/run_once_10-packages.sh.tmpl | head -30
```

期望输出：渲染后的 bash 代码（无模板标记残留，第一行是 `#!/bin/bash`）。

- [ ] **Step 4: Commit**

```bash
cd ~/.local/share/chezmoi
git add run_once_10-packages.sh.tmpl
git commit -m "feat: add run_once script to install system packages"
```

---

## Task 2: oh-my-zsh 安装脚本

**Files:**
- Create: `run_once_20-oh-my-zsh.sh`

- [ ] **Step 1: 创建脚本**

创建文件 `run_once_20-oh-my-zsh.sh`，内容如下：

```bash
#!/bin/bash
# 安装 oh-my-zsh
# 为什么用 KEEP_ZSHRC=yes：chezmoi 管理 .zshrc，不能让 omz installer 覆盖它
set -e

echo "==> [20-oh-my-zsh] 安装 oh-my-zsh..."

if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "oh-my-zsh 已安装，跳过"
    exit 0
fi

KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

echo "==> [20-oh-my-zsh] 完成 ✓"
```

- [ ] **Step 2: 验证脚本语法**

```bash
bash -n ~/.local/share/chezmoi/run_once_20-oh-my-zsh.sh
echo "语法检查: $?"
```

期望输出：`语法检查: 0`（无语法错误）。

- [ ] **Step 3: 验证幂等性——在已有 oh-my-zsh 的机器上干跑**

```bash
bash ~/.local/share/chezmoi/run_once_20-oh-my-zsh.sh
```

期望输出：`oh-my-zsh 已安装，跳过`（不会重新安装）。

- [ ] **Step 4: Commit**

```bash
git add run_once_20-oh-my-zsh.sh
git commit -m "feat: add run_once script to install oh-my-zsh"
```

---

## Task 3: curl 类工具安装脚本

**Files:**
- Create: `run_once_30-cli-tools.sh`

- [ ] **Step 1: 创建脚本**

创建文件 `run_once_30-cli-tools.sh`，内容如下：

```bash
#!/bin/bash
# 安装通过 curl/官方脚本安装的工具（平台无关）
# 为什么不放在 packages 脚本里：这些工具有自己的安装方式，不走包管理器
set -e

echo "==> [30-cli-tools] 安装 curl 类工具..."

# ============================================================
# nvm - Node Version Manager
# ============================================================
if [ ! -d "$HOME/.nvm" ]; then
    echo "安装 nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
else
    echo "nvm 已安装，跳过"
fi

# ============================================================
# bun - JavaScript 运行时
# ============================================================
if [ ! -d "$HOME/.bun" ]; then
    echo "安装 bun..."
    curl -fsSL https://bun.sh/install | bash
else
    echo "bun 已安装，跳过"
fi

# ============================================================
# rustup - Rust 工具链
# ============================================================
if ! command -v rustup &>/dev/null && [ ! -f "$HOME/.cargo/env" ]; then
    echo "安装 rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
else
    echo "rustup/cargo 已安装，跳过"
fi

# ============================================================
# pyenv - Python Version Manager
# macOS 在 packages 脚本里用 brew 安装，Linux 用 pyenv-installer
# ============================================================
if [ ! -d "$HOME/.pyenv" ]; then
    if command -v brew &>/dev/null; then
        echo "macOS: pyenv 已由 brew 安装，跳过"
    else
        echo "安装 pyenv..."
        curl https://pyenv.run | bash
    fi
else
    echo "pyenv 已安装，跳过"
fi

echo "==> [30-cli-tools] 完成 ✓"
```

- [ ] **Step 2: 验证语法**

```bash
bash -n ~/.local/share/chezmoi/run_once_30-cli-tools.sh
echo "语法检查: $?"
```

期望输出：`语法检查: 0`

- [ ] **Step 3: 验证幂等性——在已有工具的机器上干跑**

```bash
bash ~/.local/share/chezmoi/run_once_30-cli-tools.sh
```

期望输出：每行都是 `xxx 已安装，跳过`，不触发任何重新安装。

- [ ] **Step 4: Commit**

```bash
git add run_once_30-cli-tools.sh
git commit -m "feat: add run_once script to install curl-based tools (nvm, bun, rustup, pyenv)"
```

---

## Task 4: zsh 插件安装脚本（run_onchange_）

**Files:**
- Create: `run_onchange_40-zsh-plugins.sh.tmpl`

### 关键机制说明

`run_onchange_` 脚本每次 `chezmoi apply` 时，chezmoi 会计算渲染后文件内容的 SHA256 hash，与上次执行时的 hash 对比。不同则重新执行。

脚本顶部的版本锁定注释就是"触发器"——改动插件版本号会改变 hash，下次 `chezmoi apply` 自动重装。

- [ ] **Step 1: 创建脚本**

创建文件 `run_onchange_40-zsh-plugins.sh.tmpl`，内容如下：

```bash
#!/bin/bash
# zsh 插件安装脚本
# 为什么用 run_onchange_：插件版本更新时自动重装，run_once_ 做不到这点
#
# === 插件版本锁定（修改此处会触发重新安装）===
# zsh-autosuggestions: main
# powerlevel10k: master（仅 Ubuntu/WSL2）
# =============================================
set -e

echo "==> [40-zsh-plugins] 安装/更新 zsh 插件..."

OMZ_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# 如果 oh-my-zsh 还没装好就退出（理论上不会发生，因为脚本有序执行）
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "oh-my-zsh 未找到，跳过插件安装"
    exit 0
fi

# ============================================================
# zsh-autosuggestions（所有平台）
# ============================================================
AUTOSUGGESTIONS_DIR="$OMZ_CUSTOM/plugins/zsh-autosuggestions"
if [ ! -d "$AUTOSUGGESTIONS_DIR" ]; then
    echo "安装 zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUGGESTIONS_DIR"
else
    echo "更新 zsh-autosuggestions..."
    git -C "$AUTOSUGGESTIONS_DIR" pull --ff-only
fi

# ============================================================
# powerlevel10k（仅 Ubuntu/WSL2）
# Arch 用 pacman 安装的系统包，macOS 用 brew 安装
# ============================================================
{{- if not .isArch }}
{{- if not .isMac }}
P10K_DIR="$OMZ_CUSTOM/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
    echo "安装 powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
    echo "更新 powerlevel10k..."
    git -C "$P10K_DIR" pull --ff-only
fi
{{- end }}
{{- end }}

echo "==> [40-zsh-plugins] 完成 ✓"
```

- [ ] **Step 2: 验证模板渲染（以当前平台为例）**

```bash
chezmoi execute-template < ~/.local/share/chezmoi/run_onchange_40-zsh-plugins.sh.tmpl
```

期望：渲染后的 bash 代码，Arch 机器上不含 powerlevel10k 那段，Ubuntu 机器上包含。

- [ ] **Step 3: 验证幂等性——重复运行只做更新不重装**

```bash
bash <(chezmoi execute-template < ~/.local/share/chezmoi/run_onchange_40-zsh-plugins.sh.tmpl)
```

期望输出：`更新 zsh-autosuggestions...`（已存在则 pull，不重新 clone）。

- [ ] **Step 4: Commit**

```bash
git add run_onchange_40-zsh-plugins.sh.tmpl
git commit -m "feat: add run_onchange script to install/update zsh plugins"
```

---

## Task 5: 更新 README.md

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 删除手动安装 oh-my-zsh 的说明**

找到 README.md 中这段（约第 51-55 行）：

```markdown
Zsh 依赖 oh-my-zsh，chezmoi apply 完成后需单独安装：

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
```
```

替换为：

```markdown
oh-my-zsh、zsh 插件、及常用 CLI 工具（nvm、bun、rustup、atuin 等）均由 chezmoi `run_once_` 脚本自动安装，无需手动操作。
```

- [ ] **Step 2: 更新目录结构说明**

在 README.md 的目录结构部分，在 `dot_zshrc.tmpl` 之前加入：

```markdown
├── run_once_10-packages.sh.tmpl    # 自动安装系统包（pacman/apt/brew）
├── run_once_20-oh-my-zsh.sh        # 自动安装 oh-my-zsh
├── run_once_30-cli-tools.sh        # 自动安装 nvm/bun/rustup/pyenv
├── run_onchange_40-zsh-plugins.sh.tmpl  # 插件变动时自动重装
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: update README to reflect automated run_once_ scripts"
```

---

## Task 6: 端到端验证（Docker）

参考 `chezmoi-docker-test-notes.md` 的方法，在 Ubuntu 容器中验证完整流程。

- [ ] **Step 1: 导出 GPG 私钥**

```bash
gpg --export-secret-keys --armor jinzaizhichi9888@gmail.com > /tmp/dotfiles-test-key.asc
```

- [ ] **Step 2: 启动干净的 Ubuntu 容器**

```bash
docker run -d --name dotfiles-test-run \
  -v /tmp/dotfiles-test-key.asc:/tmp/gpg-key.asc:ro \
  ubuntu:24.04 sleep infinity
```

- [ ] **Step 3: 安装最小依赖并跑 chezmoi init**

```bash
docker exec dotfiles-test-run bash -c "
  apt-get update -qq &&
  apt-get install -y curl git gpg gpg-agent pass sudo locales ca-certificates &&
  sh -c \"\$(curl -fsLS get.chezmoi.io)\" &&
  gpg --import /tmp/gpg-key.asc
"

docker exec dotfiles-test-run bash -c "
  ~/.local/bin/chezmoi init --apply https://github.com/jinzaizhichi/dotfiles.git 2>&1
"
```

- [ ] **Step 4: 验证关键工具已安装**

```bash
docker exec dotfiles-test-run bash -c "
  for cmd in nvim gh fzf zoxide atuin; do
    command -v \$cmd && echo \"\$cmd: OK\" || echo \"\$cmd: MISSING\"
  done
  [ -d ~/.oh-my-zsh ] && echo 'oh-my-zsh: OK' || echo 'oh-my-zsh: MISSING'
  [ -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ] && echo 'zsh-autosuggestions: OK' || echo 'zsh-autosuggestions: MISSING'
"
```

期望输出：每行都是 `xxx: OK`，无 MISSING。

- [ ] **Step 5: 清理容器**

```bash
docker rm -f dotfiles-test-run
rm /tmp/dotfiles-test-key.asc
```

- [ ] **Step 6: Push 到 GitHub**

```bash
cd ~/.local/share/chezmoi
git push
```

---

## 附：触发 run_onchange_ 的方法

以后要更新插件版本，编辑 `run_onchange_40-zsh-plugins.sh.tmpl` 顶部的版本注释：

```bash
# zsh-autosuggestions: main  ← 改成具体 commit hash 即可触发重装
```

然后 `chezmoi apply`，脚本自动重新执行。
