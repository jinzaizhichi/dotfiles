# 用 Docker 测试 chezmoi dotfiles 全流程笔记

## 目标

在一个干净的 Ubuntu 容器里模拟新机器初始化，验证 chezmoi dotfiles 能否完整部署。

---

## 完整步骤

### 1. 导出 GPG 私钥到宿主机临时文件

```bash
gpg --export-secret-keys --armor <KEY_ID> > /tmp/dotfiles-test-key.asc
```

dotfiles 里的 SSH 私钥是用 GPG 加密存储的（`.asc` 文件），所以容器里必须有 GPG 私钥才能解密。

---

### 2. 启动容器并挂载 GPG 密钥

```bash
docker run -d --name dotfiles-test \
  -v /tmp/dotfiles-test-key.asc:/tmp/gpg-key.asc:ro \
  ubuntu:24.04 sleep infinity
```

用 `sleep infinity` 让容器保持存活，方便多次 `docker exec` 进去操作。
`ro` 只读挂载，密钥不会被容器修改。

---

### 3. 安装依赖包

```bash
docker exec dotfiles-test bash -c "
  apt-get update -qq
  apt-get install -y curl git zsh gpg gpg-agent pass sudo locales ca-certificates
"
```

`ca-certificates` 是关键——没有它，`curl` 会报 SSL 证书错误，导致 chezmoi 安装脚本失败。

---

### 4. 安装 chezmoi

```bash
docker exec dotfiles-test bash -c "
  sh -c \"\$(curl -fsLS get.chezmoi.io)\" -- -b /usr/local/bin
"
```

---

### 5. 导入 GPG 私钥并设置信任级别

```bash
docker exec dotfiles-test bash -c "
  mkdir -p /root/.gnupg && chmod 700 /root/.gnupg
  gpg --batch --import /tmp/gpg-key.asc
  echo '<FINGERPRINT>:6:' | gpg --import-ownertrust
"
```

`6` 表示 ultimate 信任，不设置的话 chezmoi 解密时会有信任警告甚至失败。
fingerprint 用 `gpg --list-secret-keys` 查看。

---

### 6. 处理非交互环境下的 GPG 口令问题（核心难点）

**问题：** Docker exec 默认没有 TTY，GPG 无法弹出口令输入框，报错：
```
gpg: cannot open '/dev/tty': No such device or address
```

**解决方案：** 用 `gpg-preset-passphrase` 预先把口令缓存到 gpg-agent，后续调用无需再输入。

```bash
docker exec dotfiles-test bash -c "
  # 1. 配置 gpg-agent 允许 loopback 和 preset passphrase
  echo 'allow-loopback-pinentry' >> /root/.gnupg/gpg-agent.conf
  echo 'allow-preset-passphrase' >> /root/.gnupg/gpg-agent.conf
  echo 'pinentry-mode loopback'  >> /root/.gnupg/gpg.conf

  # 2. 重载 agent 使配置生效
  gpgconf --reload gpg-agent

  # 3. 分别缓存主密钥和加密子密钥的口令（keygrip 用 --with-keygrip 查）
  echo -n 'YOUR_PASSPHRASE' | /usr/lib/gnupg/gpg-preset-passphrase --preset <KEYGRIP_主密钥>
  echo -n 'YOUR_PASSPHRASE' | /usr/lib/gnupg/gpg-preset-passphrase --preset <KEYGRIP_子密钥>
"
```

查看 keygrip：
```bash
gpg --with-keygrip --list-secret-keys
```

---

### 7. 复制 pass 密码库

chezmoi 的 `.gitconfig.tmpl` 里调用了 `pass show github/api/token`，容器里没有 pass 数据库会直接报错导致 apply 失败。

```bash
docker cp ~/.password-store dotfiles-test:/root/.password-store
```

---

### 8. 运行 chezmoi init

```bash
docker exec dotfiles-test bash -c "
  export PASSWORD_STORE_DIR=/root/.password-store
  chezmoi init --apply https://github.com/jinzaizhichi/dotfiles.git
"
```

---

### 9. 验证部署结果

```bash
docker exec dotfiles-test bash -c "
  ls -la ~/.zshrc ~/.gitconfig ~/.ssh/ ~/.config/zsh/
  zsh -c 'source ~/.zshrc; echo exit: \$?'
"
```

---

## 测试发现的问题

| 问题 | 原因 | 处理方式 |
|------|------|----------|
| `oh-my-zsh` 缺失 | `.chezmoiexternal.toml` 里注释掉了 | 在 README 补充单独安装步骤 |
| `LC_ALL` locale 警告 | Docker 最小镜像没有完整 locale | 正常现象，生产机器不影响 |

---

## 清理

```bash
docker rm -f dotfiles-test
rm /tmp/dotfiles-test-key.asc
```

---

## 关键经验

1. **非交互 GPG 解密** 必须用 `allow-preset-passphrase` + `gpg-preset-passphrase`，两个 keygrip（主密钥 + 子密钥）都要缓存。
2. **chezmoi 模板里的 `pass` 调用** 会在 apply 阶段执行，新机器上必须先有 pass 数据库，否则整个 init 会中断报错。
3. **`ca-certificates`** 是容器里安装 chezmoi 的前提，最小镜像默认不带。
4. **apt lock 竞争**：Docker 启动后 Ubuntu 可能有后台 apt 进程，等它结束再安装包。
