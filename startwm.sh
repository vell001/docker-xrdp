#!/bin/sh
# xrdp X session start script (c) 2015, 2017 mirabilos
# published under The MirOS Licence

if test -r /etc/profile; then
        . /etc/profile
fi

export LANG=zh_CN.UTF-8
export LANGUAGE=zh_CN:zh:en_US:en
export LC_CTYPE="zh_CN.UTF-8"
export LC_NUMERIC=zh_CN.UTF-8
export LC_TIME=zh_CN.UTF-8
export LC_COLLATE="zh_CN.UTF-8"
export LC_MONETARY=zh_CN.UTF-8
export LC_MESSAGES="zh_CN.UTF-8"
export LC_PAPER=zh_CN.UTF-8
export LC_NAME=zh_CN.UTF-8
export LC_ADDRESS=zh_CN.UTF-8
export LC_TELEPHONE=zh_CN.UTF-8
export LC_MEASUREMENT=zh_CN.UTF-8
export LC_IDENTIFICATION=zh_CN.UTF-8
export LC_ALL=zh_CN.utf8
export TZ=Asia/Shanghai

#export GTK_IM_MODULE=fcitx
#export QT4_IM_MODULE=fcitx
#export XMODIFIERS=@im=fcitx
#export CLUTTER_IM_MODULE=fcitx
#export QT_IM_MODULE=fcitx

eval `dbus-launch --sh-syntax --exit-with-session`
if test -r /etc/profile; then
        . /etc/profile
fi

# 解决无法复制文件问题
umount -f xrdp-chansrv

test -x /etc/X11/Xsession && exec /etc/X11/Xsession
exec /bin/sh /etc/X11/Xsession
