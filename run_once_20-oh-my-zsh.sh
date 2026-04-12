#!/bin/bash
# 安装 oh-my-zsh
# 为什么用 KEEP_ZSHRC=yes：chezmoi 管理 .zshrc，不能让 omz installer 覆盖它
set -euo pipefail

echo "==> [20-oh-my-zsh] 安装 oh-my-zsh..."

if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "oh-my-zsh 已安装，跳过"
    exit 0
fi

KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

echo "==> [20-oh-my-zsh] 完成 ✓"
