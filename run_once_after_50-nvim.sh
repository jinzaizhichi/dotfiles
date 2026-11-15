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

local function log(msg)
  io.stdout:write(msg .. "\n")
  io.stdout:flush()
end

mr.refresh(function()
  local pending = 0
  local total = #packages
  local done = 0

  for _, name in ipairs(packages) do
    local ok, pkg = pcall(mr.get_package, name)
    if ok then
      if pkg:is_installed() then
        done = done + 1
        log(string.format("[已存在 %d/%d] %s", done, total, name))
      else
        pending = pending + 1
        log(string.format("[开始安装] %s ...", name))
        local handle = pkg:install()
        handle:once("closed", function()
          pending = pending - 1
          done = done + 1
          if pkg:is_installed() then
            log(string.format("[✓ 完成 %d/%d] %s (剩余 %d 个)", done, total, name, pending))
          else
            log(string.format("[✗ 失败 %d/%d] %s (剩余 %d 个)", done, total, name, pending))
          end
        end)
      end
    else
      log("[! 未找到包] " .. name)
    end
  end

  if pending == 0 then
    log("所有 Mason 工具均已就绪！")
    vim.cmd("qall!")
    return
  end

  local ok = vim.wait(300000, function() return pending == 0 end, 500)
  if not ok then
    log("[!] 等待超时，仍有 " .. pending .. " 个包未完成。")
  end
  vim.cmd("qall!")
end)
LUAEOF

    nvim --headless -c "luafile /tmp/mason_install.lua"
    rm -f /tmp/mason_install.lua
    echo "==> [50-nvim] 完成 ✓"
fi
