# Build xrdp pulseaudio modules in builder container
# See https://github.com/neutrinolabs/pulseaudio-module-xrdp/wiki/README
ARG TAG=18.04
FROM ubuntu:$TAG as builder

# 替换apt源
RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak
RUN sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list

RUN sed -i -E 's/^# deb-src /deb-src /g' /etc/apt/sources.list \
    && apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        build-essential \
        dpkg-dev \
        git \
        libpulse-dev \
        pulseaudio \
    && apt-get build-dep -y pulseaudio \
    && apt-get source pulseaudio \
    && rm -rf /var/lib/apt/lists/*

RUN cd /pulseaudio-$(pulseaudio --version | awk '{print $2}') \
    && ./configure

RUN git clone https://gitee.com/vell/pulseaudio-module-xrdp.git /pulseaudio-module-xrdp \
    && cd /pulseaudio-module-xrdp \
    && ./bootstrap \
    && ./configure PULSE_DIR=/pulseaudio-$(pulseaudio --version | awk '{print $2}') \
    && make \
    && make install


# Build the final image
FROM ubuntu:$TAG

# 替换apt源
RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak
RUN sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
RUN apt-get update
ARG DEBIAN_FRONTEND=noninteractive

# 安装桌面
RUN apt install -y dbus-x11 \
    git \
    locales \
    pavucontrol \
    pulseaudio \
    pulseaudio-utils \
    sudo \
    x11-xserver-utils \
    xorgxrdp \
    xrdp \
    xfce4

RUN sed -i -E 's/^; autospawn =.*/autospawn = yes/' /etc/pulse/client.conf \
    && [ -f /etc/pulse/client.conf.d/00-disable-autospawn.conf ] && sed -i -E 's/^(autospawn=.*)/# \1/' /etc/pulse/client.conf.d/00-disable-autospawn.conf || :

COPY --from=builder /usr/lib/pulse-*/modules/module-xrdp-sink.so /usr/lib/pulse-*/modules/module-xrdp-source.so /var/lib/xrdp-pulseaudio-installer/

# 安装工具
RUN apt install -y vim git gedit firefox net-tools unzip iputils-ping curl wget gnupg terminator

# 安装中文环境
RUN apt install -y ttf-wqy-microhei fonts-wqy-zenhei ibus-pinyin
RUN locale-gen zh_CN.UTF-8
COPY startwm.sh /etc/xrdp/startwm.sh
RUN chmod a+x /etc/xrdp/startwm.sh

# 创建用户
RUN groupadd --gid 1020 ubuntu && \
useradd --shell /bin/bash --uid 1020 --gid 1020 --password $(openssl passwd ubuntu) --create-home --home-dir /home/ubuntu ubuntu  && \
usermod -aG sudo ubuntu

# 设置默认config
COPY home_config /home/ubuntu/.config
RUN chown -R 1020:1020 /home/ubuntu/.config

COPY start_xrdp /bin/start_xrdp
EXPOSE 3389/tcp
ENTRYPOINT ["/bin/start_xrdp"] 
