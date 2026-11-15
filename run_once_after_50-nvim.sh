#!/bin/bash
set -euo pipefail

# 加载常见二进制路径与 nvm（如存在）
export PATH="$HOME/.local/bin:$HOME/go/bin:/usr/local/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if command -v nvim &>/dev/null; then
    echo "==> [50-nvim] 同步 Neovim 插件..."
    nvim --headless "+Lazy! sync" +qa

    echo "==> [50-nvim] 安装 Mason LSP/Formatter 工具..."
    cat << 'LUAEOF' > /tmp/mason_install.lua
require("lazy").load({ plugins = { "mason.nvim" } })
local mr = require("mason-registry")
local packages = {
  "prettier", "bash-language-server", "black", "css-lsp",
  "goimports", "gopls", "html-lsp", "isort", "json-lsp",
  "lua-language-server", "pyright", "stylua", "typescript-language-server"
}

mr.refresh(function()
  local pending = 0
  for _, name in ipairs(packages) do
    local ok, pkg = pcall(mr.get_package, name)
    if ok and not pkg:is_installed() then
      pending = pending + 1
      print("Installing " .. name .. "...")
      pkg:install():once("closed", function()
        pending = pending - 1
      end)
    end
  end
  if pending == 0 then
    vim.cmd("qall!")
    return
  end
  vim.wait(300000, function() return pending == 0 end, 500)
  vim.cmd("qall!")
end)
LUAEOF

    nvim --headless -c "luafile /tmp/mason_install.lua"
    rm -f /tmp/mason_install.lua
    echo "==> [50-nvim] 完成 ✓"
fi
