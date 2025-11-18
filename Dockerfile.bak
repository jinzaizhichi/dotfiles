# 基础镜像使用官方 Arch Linux
FROM archlinux:latest

# 定义构建参数，方便修改用户ID和组ID
ARG USERNAME=jinzaizhichi
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# ----------------------------------------------------
# 步骤 1: 设置时区和系统环境 (Root 权限)
# ----------------------------------------------------
ENV TZ=Asia/Shanghai
# 设置时区符号链接
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# ----------------------------------------------------
# 步骤 2: 安装必要的软件包 (Root 权限)
# ----------------------------------------------------
# 最佳实践：将安装和缓存清理合并在一个 RUN 指令中
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    curl \
    git \
    bats \
    kcov \
    sudo \
    tzdata \
    parallel \
    base-devel \
    ca-certificates && \
    # 清理缓存以减小镜像体积
    pacman -Sc --noconfirm

# ----------------------------------------------------
# 步骤 3: 创建用户并配置 Sudo (Root 权限)
# ----------------------------------------------------
# 在 Arch 中，通常使用 'wheel' 组进行 sudo 授权
RUN groupadd --gid $USER_GID $USERNAME \
    # -m 创建家目录；-G wheel 添加到 wheel 组；-s /bin/bash 设置默认 Shell
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -G wheel -s /bin/bash \
    # 启用 wheel 组用户免密使用 sudo (Arch 默认可能已配置)
    && echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    # 确保家目录及其内容的所有权是正确的
    && chown -R $USERNAME:$USERNAME /home/$USERNAME

# ----------------------------------------------------
# 步骤 4: 安装 chezmoi (Root 权限)
# ----------------------------------------------------
# 安装到 /usr/local/bin 属于系统操作，应在 root 权限下完成
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# ----------------------------------------------------
# 步骤 5: 切换到普通用户 (切换权限)
# ----------------------------------------------------
USER $USERNAME
WORKDIR /home/$USERNAME

# ----------------------------------------------------
# 步骤 6: 普通用户环境设置 (新增同步 dotfiles)
# ----------------------------------------------------
# 1. 初始化并同步您的 dotfiles 仓库
# chezmoi init <仓库用户名> 会自动克隆仓库到 ~/.local/share/chezmoi
RUN chezmoi init jinzaizhichi

# 2. 创建字体目录 (保持原有逻辑)
RUN mkdir -p .local/share/fonts

# 创建 chezmoi 工作目录（如果 chezmoi init 失败，作为备用）
RUN mkdir -p .local/share/chezmoi

# 注意：如果您的 dotfiles 仓库需要执行特定的安装脚本（例如 chezmoiscripts），
# 您可能需要添加 RUN chezmoi apply 来实际应用配置。
# RUN chezmoi apply
