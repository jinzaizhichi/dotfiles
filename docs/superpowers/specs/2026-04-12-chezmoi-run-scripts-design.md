# chezmoi run_ 自动化脚本设计

**日期**: 2026-04-12  
**状态**: 已确认  

## 背景

当前 oh-my-zsh 和其他 CLI 工具需要在 `chezmoi apply` 后手动安装。目标是通过 chezmoi 的 `run_` 脚本机制，让新机器只需一条命令即可完成完整环境初始化。

## 设计目标

- `chezmoi init --apply` 一条命令搞定所有环境
- 三平台支持：Arch Linux / Ubuntu(WSL2) / macOS
- 充分利用三种 run_ 模式：`run_once_`、`run_onchange_`

## 文件结构

```
chezmoi/
├── run_once_10-packages.sh.tmpl          # 第一步：系统包
├── run_once_20-oh-my-zsh.sh              # 第二步：oh-my-zsh 本体
├── run_once_30-cli-tools.sh              # 第三步：curl 安装的工具
└── run_onchange_40-zsh-plugins.sh.tmpl   # 插件变动时重装
```

## 各脚本职责

### run_once_10-packages.sh.tmpl

用平台包管理器安装核心工具。macOS 先检测并安装 Homebrew。

| 工具 | Arch | Ubuntu | macOS |
|---|---|---|---|
| neovim | pacman | PPA 最新版 | brew |
| git / curl / wget | pacman | apt | brew |
| fzf / zoxide / direnv | pacman | apt / 手动 / apt | brew |
| atuin | yay AUR | 官方脚本 | brew |
| gh (GitHub CLI) | pacman | 官方 apt 源 | brew |
| ripgrep / fd / bat / eza | pacman | apt | brew |
| pass / gnupg | pacman | apt | brew |
| fasd | yay AUR | 手动 clone | brew |

### run_once_20-oh-my-zsh.sh

- `KEEP_ZSHRC=yes` + `--unattended` 安装，不覆盖 chezmoi 管理的 `.zshrc`
- 纯 bash，无需模板，各平台行为一致
- 幂等：检测 `~/.oh-my-zsh` 是否已存在

### run_once_30-cli-tools.sh

平台无关，全部用官方 installer 脚本安装：

- nvm — curl 安装
- bun — curl 安装
- rustup — curl 安装
- pyenv — macOS 用 brew，Linux 用 pyenv-installer

### run_onchange_40-zsh-plugins.sh.tmpl

脚本顶部嵌入插件版本锁定注释，修改注释触发重装：

```bash
# === 插件版本锁定（修改此处会触发重新安装）===
# zsh-autosuggestions: main
# powerlevel10k: master
```

覆盖范围：
- 所有平台：安装 `zsh-autosuggestions`
- 仅 Ubuntu/WSL2：安装 `powerlevel10k`（Arch 用 pacman，macOS 用 brew）

## 执行顺序

```
chezmoi init --apply
  ↓ run_once_10-packages.sh.tmpl
  系统包就绪（neovim, git, fzf...）
  ↓ run_once_20-oh-my-zsh.sh
  oh-my-zsh 安装到 ~/.oh-my-zsh/
  ↓ run_once_30-cli-tools.sh
  nvm / bun / rustup / pyenv 安装
  ↓ run_onchange_40-zsh-plugins.sh.tmpl
  zsh-autosuggestions / powerlevel10k clone 到 ~/.oh-my-zsh/custom/
  ↓
完成，打开新 shell 即可用
```

## 幂等性保证

每个脚本在执行前检测目标是否已存在，确保重复执行安全：
- `[ ! -d "$HOME/.oh-my-zsh" ]` 才安装 oh-my-zsh
- `[ ! -d "$HOME/.nvm" ]` 才安装 nvm
- 以此类推
