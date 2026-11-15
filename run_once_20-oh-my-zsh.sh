#!/usr/bin/env bash
set -euo pipefail

echo "==> [20-oh-my-zsh] 安装 oh-my-zsh..."

if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    rm -rf /tmp/ohmyzsh
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /tmp/ohmyzsh
    mkdir -p "$HOME/.oh-my-zsh"
    cp -rn /tmp/ohmyzsh/. "$HOME/.oh-my-zsh/"
    rm -rf /tmp/ohmyzsh
else
    echo "oh-my-zsh 已安装，跳过"
fi
