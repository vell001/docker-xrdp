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

# 安装桌面
RUN apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        dbus-x11 \
        git \
        locales \
        pavucontrol \
        pulseaudio \
        pulseaudio-utils \
        sudo \
        x11-xserver-utils \
        xfce4 \
        xfce4-goodies \
        xfce4-pulseaudio-plugin \
        xorgxrdp \
        xrdp \
        xubuntu-icon-theme

RUN sed -i -E 's/^; autospawn =.*/autospawn = yes/' /etc/pulse/client.conf \
    && [ -f /etc/pulse/client.conf.d/00-disable-autospawn.conf ] && sed -i -E 's/^(autospawn=.*)/# \1/' /etc/pulse/client.conf.d/00-disable-autospawn.conf || :

COPY --from=builder /usr/lib/pulse-*/modules/module-xrdp-sink.so /usr/lib/pulse-*/modules/module-xrdp-source.so /var/lib/xrdp-pulseaudio-installer/

# 安装工具
RUN apt install -y vim gedit net-tools unzip iputils-ping curl wget gnupg terminator
# 安装ros
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu bionic main" > /etc/apt/sources.list.d/ros-latest.list'

RUN curl -s http://packages.ros.org/ros.key | apt-key add -
RUN apt update
RUN DEBIAN_FRONTEND=noninteractive apt install -y ros-melodic-desktop-full
RUN echo "source /opt/ros/melodic/setup.bash" >> /root/.bashrc

# 安装gtsam
RUN apt install -y software-properties-common
RUN add-apt-repository ppa:borglab/gtsam-release-4.1
RUN apt update
RUN apt install -y libgtsam-dev libgtsam-unstable-dev

# 安装GeographicLib
RUN git clone https://gitee.com/vell/GeographicLib.git
RUN cd GeographicLib && mkdir build && cd build && cmake .. && make -j $(nproc) && make install
RUN rm -rf GeographicLib

# 安装octomap
RUN apt install -y ros-melodic-octomap*

# 安装Sophus
RUN git clone -b ubt18.04 https://gitee.com/vell/Sophus.git
RUN cd Sophus && mkdir build && cd build && cmake .. && make -j $(nproc) && make install
RUN rm -rf Sophus

# 安装Livox-SDK
RUN git clone https://gitee.com/vell/Livox-SDK.git
RUN cd Livox-SDK && cd build && cmake .. && make -j $(nproc) && make install
RUN rm -rf Livox-SDK

# 安装pcap
RUN apt install -y libpcap-dev

# 安装g2o
RUN apt install -y ros-melodic-geodesy ros-melodic-pcl-ros ros-melodic-nmea-msgs ros-melodic-libg2o
RUN git clone -b cmake_3.10 https://gitee.com/vell/g2o.git --depth=1
RUN cd g2o && mkdir build && cd build && cmake .. && make -j $(nproc) && make install
RUN echo "export LD_LIBRARY_PATH=\"/usr/lib/x86_64-linux-gnu/:/usr/lib:/usr/local/lib:\$LD_LIBRARY_PATH\"" >> /root/.bashrc
RUN rm -rf g2o

# 安装中文环境
ENV TZ=Asia/Shanghai \
    LANG=zh_CN.UTF-8 \
    LC_ALL=${LANG} \
    LANGUAGE=${LANG}
RUN apt install -y ttf-wqy-microhei fonts-wqy-zenhei ibus-pinyin
RUN locale-gen zh_CN.UTF-8
#COPY sogoupinyin_4.2.1.145_amd64.deb /sogoupinyin_4.2.1.145_amd64.deb
#RUN apt install -y fonts-wqy-zenhei fcitx && dpkg -i /sogoupinyin_4.2.1.145_amd64.deb
#RUN rm -f /sogoupinyin_4.2.1.145_amd64.deb
COPY startwm.sh /etc/xrdp/startwm.sh
RUN chmod a+x /etc/xrdp/startwm.sh

# 创建用户
RUN groupadd --gid 1020 ubuntu && \
useradd --shell /bin/bash --uid 1020 --gid 1020 --password $(openssl passwd ubuntu) --create-home --home-dir /home/ubuntu ubuntu  && \
usermod -aG sudo ubuntu

# 设置环境
RUN echo "source /opt/ros/melodic/setup.bash" >> /home/ubuntu/.bashrc && \
echo "export LD_LIBRARY_PATH=\"/usr/lib/x86_64-linux-gnu/:/usr/lib:/usr/local/lib:\$LD_LIBRARY_PATH\"" >> /home/ubuntu/.bashrc && \
echo "export TZ=Asia/Shanghai" >> /home/ubuntu/.bashrc

# 设置xfce桌面
COPY xfce_config/xfce4 /home/ubuntu/.config/xfce4

COPY start_xrdp /bin/start_xrdp
EXPOSE 3389/tcp
ENTRYPOINT ["/bin/start_xrdp"] 
