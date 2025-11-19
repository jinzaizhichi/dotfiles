# 使用最新的 Arch Linux 基础镜像
FROM archlinux

# 维护者标签 (可选)
LABEL maintainer="jinzaizhichi <jinzaizhichi9888@gmail.com>"

# 设置非交互式环境
ENV DEBIAN_FRONTEND=noninteractive

# 定义普通用户及其 UID/GID。您可以在构建时通过 --build-arg 修改这些值。
ARG USERNAME=devuser
ARG USER_UID=1000
ARG USER_GID=1000

# ----------------------------------------------------
# 步骤 1: 解决 Pacman 连接超时问题 & 安装基础工具
# ----------------------------------------------------
RUN pacman-key --init && \
    pacman-key --populate archlinux && \
    # 增加连接超时时间到 30 秒，解决下载超时问题
    sed -i '/^#XferCommand = \/usr\/bin\/curl/s/^#//' /etc/pacman.conf && \
    sed -i 's/XferCommand = \/usr\/bin\/curl -L -C - -f -o %o %u/XferCommand = \/usr\/bin\/curl -L -C - -f --connect-timeout 30 -o %o %u/' /etc/pacman.conf && \
    \
    # 运行更新和安装基础包 (curl 必须先于 chezmoi 的安装步骤被安装)
    pacman -Syu --noconfirm && \
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
    pacman -Sc --noconfirm && \
    \
    # 安装 chezmoi 到 /usr/local/bin (使用 Root 权限)
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# ----------------------------------------------------
# 步骤 2: 添加用户并设置 Sudo 权限 (Root 权限)
# ----------------------------------------------------
RUN groupadd --gid $USER_GID $USERNAME && \
    # -m 创建用户主目录 -G wheel 添加到 wheel 组 -s /bin/bash 设置 Shell
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -G wheel -s /bin/bash && \
    # 允许 wheel 组用户无密码使用 sudo
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    # 修正主目录权限
    chown -R $USERNAME:$USERNAME /home/$USERNAME

# ----------------------------------------------------
# 步骤 3: 切换到普通用户并设置工作目录 (非Root权限)
# ----------------------------------------------------
USER $USERNAME
WORKDIR /home/$USERNAME

# ----------------------------------------------------
# 步骤 4: 配置 dotfiles (使用 chezmoi)
# ----------------------------------------------------
# 1. 初始化 chezmoi，从指定仓库拉取 dotfiles
# 注意：这里假设仓库用户名为 jinzaizhichi
RUN chezmoi init jinzaizhichi && \
    # 2. 创建额外的目录 (例如用于字体)
    mkdir -p .local/share/fonts

# 如果您希望在构建时立即应用 dotfiles，可以取消注释下面的行：
# RUN chezmoi apply

# 默认命令
CMD ["/bin/bash"]
