# dotfiles

jinzaizhichi 的个人配置，通过 [chezmoi](https://www.chezmoi.io/) 管理，支持 Arch Linux / Debian / Ubuntu / WSL2 / macOS 跨平台部署。

## 目录结构

```
.
├── .chezmoi.toml.tmpl          # chezmoi 主配置（首次 init 填写 name/email）
├── .chezmoidata/               # 静态数据（渲染到所有 .tmpl）
│   ├── hosts.toml              #   - VPS/主机配置
│   └── projects.toml           #   - 项目清单（驱动 cd 别名和跳转）
├── .chezmoiexternal.toml.tmpl  # 声明式外部资源（TPM / zsh 插件）
├── .chezmoiignore              # 跨平台忽略规则（支持模板语法）
├── .chezmoitemplates/          # 公共模板片段
├── .editorconfig               # 缩进/换行统一规则（仓库自身，不部署）
│
├── run_once_10-packages.sh.tmpl       # 系统包（Arch/Debian/Ubuntu/macOS）
├── run_once_20-oh-my-zsh.sh           # oh-my-zsh（KEEP_ZSHRC 模式）
├── run_once_30-cli-tools.sh           # curl 安装类工具（nvm/bun/rustup/pyenv/atuin/zoxide）
├── run_once_after_45-tmux-plugins.sh  # 首次触发 TPM install_plugins
│
├── dot_zshrc.tmpl              # Zsh 入口
├── dot_tmux.conf.tmpl          # tmux 配置
├── dot_gitconfig.tmpl          # Git 配置
│
├── dot_config/
│   ├── mypy/config
│   └── zsh/                    # Zsh 模块化配置
│       ├── 00-env.zsh.tmpl         # 环境变量（pass 取 API key）
│       ├── 10-path.zsh.tmpl        # PATH
│       ├── 20-aliases.zsh.tmpl     # 别名（项目跳转由 .chezmoidata 驱动）
│       ├── 30-functions.zsh.tmpl   # 自定义函数
│       ├── 40-tools.zsh.tmpl       # 工具集成 + nvm/pyenv/rbenv lazy load
│       ├── 50-projects.zsh.tmpl    # 项目/VPS 快捷操作
│       └── create_99-local.zsh.tmpl # 机器本地配置（首次生成后不再覆盖）
│
├── private_dot_ssh/
│   ├── config.tmpl             # SSH 配置（主机来自 .chezmoidata/hosts.toml）
│   ├── encrypted_private_readonly_id_ed25519.asc     # 私钥（GPG 加密）
│   └── encrypted_private_readonly_id_ed25519.pub.asc # 公钥（GPG 加密）
└── private_dot_gnupg/
    └── gpg-agent.conf          # GPG Agent 配置（Linux 专属）
```

## 快速开始

### 新机器初始化

**第一步：安装基础依赖**

```bash
# Ubuntu / WSL2
sudo apt install curl git gpg pass -y

# macOS
brew install curl git gnupg pass

# Arch Linux
sudo pacman -S curl git gnupg pass
```

**第二步：导入 GPG 私钥**

SSH 密钥和 pass 密码库均用 GPG 加密，需要先导入私钥：

```bash
gpg --import your-private-key.asc
```

**第三步：同步 pass 密码库**

`dot_gitconfig.tmpl` 在渲染时会调用 `pass show github/api/token`，密码库必须提前就绪：

```bash
# 如果 pass 密码库用 git 管理，克隆到本地
git clone <your-pass-repo> ~/.password-store

# 或者初始化并手动插入必要的 key
pass init jinzaizhichi9888@gmail.com
pass insert github/api/token
```

**第四步：安装 chezmoi 并初始化**

```bash
sh -c "$(curl -fsLS get.chezmoi.io)"
~/.local/bin/chezmoi init --apply https://github.com/jinzaizhichi/dotfiles.git
```

`run_once_*` 脚本自动装系统包、oh-my-zsh、nvm/bun/rustup/pyenv；`chezmoiexternal` 自动拉取 TPM、zsh-autosuggestions、powerlevel10k（每周刷新）。

## 使用方法

### 1. 编辑与应用

```bash
# 编辑共享配置（chezmoi 会打开仓库内的源文件）
chezmoi edit ~/.config/zsh/20-aliases.zsh

# 编辑机器本地配置（不会同步到远程）
nvim ~/.config/zsh/99-local.zsh

# 预览将要应用的变更
chezmoi diff

# 真正应用到家目录
chezmoi apply -v

# 跳过外部资源（TPM/插件）的网络拉取，加快迭代
chezmoi diff --exclude=externals
chezmoi apply --exclude=externals -v
```

### 2. 新增项目（数据驱动）

只改一处即可生效：在 `.chezmoidata/projects.toml` 末尾追加：

```toml
[[projects]]
alias = "blog"
dir   = "my-blog"
desc  = "个人博客"
```

`chezmoi apply` 后自动得到 `cdblog` 别名。

### 3. 修改 VPS / 主机信息

`.chezmoidata/hosts.toml` 是单一真源。改 IP/端口/用户后：

```bash
chezmoi apply -v          # ~/.ssh/config 和 zsh 函数自动同步
```

涉及的文件：`~/.ssh/config`、`ssh-vps`、`sync-to-vps`、`nginx-access/error`、`FUTU_SSH_TUNNEL` 等。

### 4. 机器本地配置

需要写当前机器才用得上的 API key 引用 / 别名 / 函数？

```bash
nvim ~/.config/zsh/99-local.zsh
```

- 此文件由 `create_99-local.zsh.tmpl` 首次生成，之后**不会被 apply 覆盖**
- 不会同步到远程仓库
- 重装机器时会从模板重新生成默认内容

### 5. 同步与提交

```bash
# 拉取远程最新配置并应用
chezmoi update

# 进入仓库目录提交本地修改
chezmoi cd
git add .
git commit -m "feat: ..."
git push
exit
```

### 6. 外部资源（TPM / zsh 插件）

由 `.chezmoiexternal.toml.tmpl` 管理，每 168h（7 天）自动检查更新。

```bash
# 查看 chezmoi 管理的外部资源
chezmoi managed --include=externals

# 强制刷新（不等 7 天）
chezmoi apply --refresh-externals
```

### 7. 模板调试

```bash
# 测试模板变量是否能正确取到
chezmoi execute-template '{{ .hosts.lance.ip }}'
chezmoi execute-template '{{ range .projects }}{{ .alias }} {{ end }}'

# 查看渲染后的某个文件（不写入磁盘）
chezmoi cat ~/.ssh/config

# 全量列出 chezmoi 会管理的文件
chezmoi managed
```

### 8. 常用别名（dot_zshrc 导入后可用）

| 别名 | 等价命令 |
|------|---------|
| `cm` | `chezmoi` |
| `cma` | `chezmoi apply` |
| `cme` | `chezmoi edit` |
| `cmcd` | `chezmoi cd` |
| `cmu` | `chezmoi update` |

### 9. 故障排查

| 现象 | 排查 |
|------|------|
| `chezmoi diff` 卡住 | 通常是 externals 网络慢，加 `--exclude=externals` |
| `pass: error` | pass 密码库没就绪，参考"快速开始"第三步 |
| GPG 解密失败 | 确认 `gpg --list-secret-keys` 有对应私钥 |
| zsh 启动慢 | `time zsh -i -c exit` 测耗时；逐个注释 `40-tools.zsh` 排查 |
| `cdxxx` 别名失效 | 检查 `.chezmoidata/projects.toml` 后是否 `chezmoi apply` |

## 架构特性

### 数据与模板分离

- **静态数据**：VPS IP/端口、项目路径 → `.chezmoidata/*.toml`
- **模板引用**：`{{ .hosts.lance.ip }}` / `{{ .projects }}` 等
- 新增项目只需在 `projects.toml` 加一项，`cd{{alias}}` 别名和跳转函数自动生成
- VPS 迁移/换 IP 只需改一处

### 声明式外部资源

`.chezmoiexternal.toml.tmpl` 管理 git 仓库类依赖：

- TPM、zsh-autosuggestions 所有平台
- powerlevel10k 仅在无 pacman/brew 的系统（Arch/macOS 由包管理器装）
- 自动按 `refreshPeriod = "168h"` 每周检查更新

### Zsh 启动性能

- `nvm/pyenv/rbenv` 采用**惰性加载**，首次调用 `node/python/ruby` 才初始化
- `kubectl/gh` 补全**缓存到文件**，命令二进制未变动就不重新生成
- 预估启动耗时：300–500ms → <100ms（视已装工具数）

### 本地/共享配置分离

- 共享配置在 `00-env` 到 `50-projects`，所有机器一致
- 机器专属：`create_99-local.zsh.tmpl`
  - `create_` 前缀语义：文件不存在才生成模板，已存在不覆盖
  - 适合存放 API Key 引用、机器特定 SSH 隧道、临时测试变量

## Claude Code 模型供应商切换

`~/.config/zsh/99-local.zsh` 内置 `switch-model` 函数（从 `~/claude-config/scripts/switch-model.sh` 加载）：

```bash
switch-model deepseek    # → api.deepseek.com/anthropic
switch-model anthropic   # → api.apikey.fun
echo $ANTHROPIC_BASE_URL
```

| 供应商 | API 地址 | Key 来源 |
|--------|---------|----------|
| deepseek | api.deepseek.com/anthropic | `pass deepseek/api-key` |
| anthropic | api.apikey.fun | `pass apikey-fun/api-key` |

## 安全说明

- API Keys 通过 [pass](https://www.passwordstore.org/) 读取，**不硬编码**
- SSH 私钥通过 GPG 加密后存入 Git（`.asc` 文件）
- 机器专属的 `99-local.zsh` 首次生成后不再被覆盖
