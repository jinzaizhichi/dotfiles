#!/bin/bash
set -euo pipefail
if command -v nvim &>/dev/null; then
    echo "==> [50-nvim] 自动同步 Neovim 插件与 Mason LSP..."
    nvim --headless "+Lazy! sync" "+MasonInstallAll" +qa || true
fi
