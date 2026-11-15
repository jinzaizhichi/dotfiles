#!/usr/bin/env bash
set -euo pipefail

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "==> [20-oh-my-zsh] 安装 Oh My Zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# 自动将默认 Shell 切换为 zsh（非 macOS 环境）
if command -v zsh &>/dev/null; then
    ZSH_PATH="$(command -v zsh)"
    if [ "${SHELL:-}" != "$ZSH_PATH" ] && command -v chsh &>/dev/null; then
        sudo chsh -s "$ZSH_PATH" "$USER" 2>/dev/null || true
    fi
fi

echo "==> [20-oh-my-zsh] 完成 ✓"
