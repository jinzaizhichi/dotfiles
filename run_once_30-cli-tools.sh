#!/bin/bash
# 安装通过 curl/官方脚本安装的工具（平台无关）
# 为什么不放在 packages 脚本里：这些工具有自己的安装方式，不走包管理器
set -euo pipefail

echo "==> [30-cli-tools] 安装 curl 类工具..."

# ============================================================
# nvm - Node Version Manager
# 为什么同时检查两个路径：nvm 会优先安装到 $XDG_CONFIG_HOME/nvm（如果 XDG 已设置），
# 否则安装到 ~/.nvm，两个路径都要检查才能正确判断已安装
# ============================================================
_NVM_DEFAULT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
if [ ! -d "$HOME/.nvm" ] && [ ! -d "$_NVM_DEFAULT_DIR" ]; then
    echo "安装 nvm..."
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh -o /tmp/install_nvm.sh
    bash /tmp/install_nvm.sh
    rm -f /tmp/install_nvm.sh
else
    echo "nvm 已安装，跳过"
fi
unset _NVM_DEFAULT_DIR

# ============================================================
# bun - JavaScript 运行时
# ============================================================
if [ ! -d "$HOME/.bun" ]; then
    echo "安装 bun..."
    curl -fsSL https://bun.sh/install -o /tmp/install_bun.sh
    bash /tmp/install_bun.sh
    rm -f /tmp/install_bun.sh
else
    echo "bun 已安装，跳过"
fi

# ============================================================
# rustup - Rust 工具链
# ============================================================
if ! command -v rustup &>/dev/null && [ ! -f "$HOME/.cargo/env" ]; then
    echo "安装 rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/install_rustup.sh
    bash /tmp/install_rustup.sh -y --no-modify-path
    rm -f /tmp/install_rustup.sh
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
        curl https://pyenv.run -o /tmp/install_pyenv.sh
        bash /tmp/install_pyenv.sh
        rm -f /tmp/install_pyenv.sh
    fi
else
    echo "pyenv 已安装，跳过"
fi

echo "==> [30-cli-tools] 完成 ✓"
