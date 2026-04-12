# dotfiles

jinzaizhichi 的个人配置，通过 [chezmoi](https://www.chezmoi.io/) 管理，支持 Arch Linux / Ubuntu / WSL2 / macOS 跨平台部署。

## 目录结构

```
.
├── .chezmoi.toml.tmpl          # chezmoi 主配置模板（系统自动检测）
├── .chezmoiexternal.toml       # 外部依赖（暂未启用）
├── .chezmoitemplates/          # 公共模板片段
├── dot_zshrc.tmpl              # Zsh 入口
├── dot_gitconfig.tmpl          # Git 配置
├── dot_config/
│   ├── mypy/config             # mypy 类型检查配置
│   └── zsh/                    # Zsh 模块化配置
│       ├── 00-env.zsh.tmpl     # 环境变量（API Keys 通过 pass 读取）
│       ├── 10-path.zsh.tmpl    # PATH 配置
│       ├── 20-aliases.zsh.tmpl # 别名
│       ├── 30-functions.zsh.tmpl # 自定义函数
│       ├── 40-tools.zsh.tmpl   # 工具集成（p10k, atuin, fasd, bun 等）
│       ├── 50-projects.zsh.tmpl # 项目快捷操作
│       └── readonly_99-local.zsh # 本机本地配置（不提交）
├── private_dot_ssh/
│   ├── config                  # SSH 连接配置
│   ├── encrypted_private_readonly_id_ed25519.asc     # 私钥（GPG 加密）
│   └── encrypted_private_readonly_id_ed25519.pub.asc # 公钥（GPG 加密）
└── private_dot_gnupg/
    └── gpg-agent.conf          # GPG Agent 配置
```

## 快速开始

### 新机器初始化

```bash
# 安装 chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# 从 GitHub 初始化并应用
chezmoi init --apply https://github.com/jinzaizhichi/dotfiles.git
```

SSH 密钥使用 GPG 加密存储，初始化时需要先导入 GPG 私钥：

```bash
gpg --import your-private-key.asc
chezmoi init --apply https://github.com/jinzaizhichi/dotfiles.git
```

Zsh 依赖 oh-my-zsh，chezmoi apply 完成后需单独安装：

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
```

## 日常使用

```bash
# 编辑配置文件
chezmoi edit ~/.config/zsh/20-aliases.zsh

# 预览变更
chezmoi diff

# 应用变更到家目录
chezmoi apply

# 拉取远程最新配置并应用
chezmoi update

# 提交到远程
chezmoi cd
git add .
git commit -m "chore: ..."
git push
```

## 安全说明

- API Keys 通过 [pass](https://www.passwordstore.org/) 读取，不硬编码在配置中
- SSH 私钥通过 GPG 加密后存储（`.asc` 文件）
- 本机专属配置写入 `~/.config/zsh/99-local.zsh`，不纳入版本控制
