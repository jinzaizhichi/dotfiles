#!/usr/bin/env bash
# TPM 本身由 chezmoi externals 管理（.chezmoiexternal.toml.tmpl）。
# 此脚本仅负责触发首次插件安装（tpm/bin/install_plugins 幂等）。
#
# 为什么用 run_once_after_：必须在 externals 拉下 TPM 目录之后执行。

set -euo pipefail

TPM_BIN="$HOME/.tmux/plugins/tpm/bin/install_plugins"

if [[ ! -x "$TPM_BIN" ]]; then
    echo "==> [45-tmux-plugins] 跳过：TPM 未安装（externals 未执行？）"
    exit 0
fi

echo "==> [45-tmux-plugins] 安装 tmux 插件..."
"$TPM_BIN" >/dev/null
echo "==> [45-tmux-plugins] 完成"
