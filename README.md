# docker+xrdp+xfce4+ros的中文开发环境

# 前言

![Screenshot of XFCE desktop](https://raw.githubusercontent.com/vell001/docker-xrdp/master/screenshot_2.png)

1. 团队多人协同经常出现开发环境不一致问题
2. ubuntu默认的桌面系统动不动就挂掉
3. 一台高配服务器如何让多人同时独立使用一套完整统一的带界面的开发环境
4. 出差笔记本性能差，能否直接连服务器开发

带着这几个问题，最先想到的就是docker环境了，但每次都是想搞，后面就烂尾了，因为vnc搭建远程桌面比较简单，但vnc需要消耗较大网络带宽，出差在机场这些网络较差的地方还是有点不爽，远程桌面最优解还是微软的rdp，在linux下的插件就是xrdp
由于我们开发环境是ubuntu18.04的，对xrdp支持不太友好，安装总是会出各种蓝屏、黑屏、中文输入法无法输入等等问题，就一直拖着没完整的去做一个镜像
这次抽了点时间，把坑都躺了一遍
源码：https://github.com/vell001/docker-xrdp
制作好的镜像：

1. 不带ros环境，只有xfce4+xrdp: https://hub.docker.com/repository/docker/vell001/ubt18.04_xrdp
2. 带ros环境: https://hub.docker.com/repository/docker/vell001/ubt18.04_ros_xrdp
3. 只有ros环境，不带xrdp: https://hub.docker.com/repository/docker/vell001/ubt18.04_ros

# 使用方式

1. clone源码
    ``` bash
    git clone https://github.com/vell001/docker-xrdp
    ```
2. 编译【非必要，如果不需要修改Dockerfile，直接跳到下一步即可】
   可以直接使用我写好的build脚本`./build`编译，默认编译带ros环境的
   也可以docker命令行编译
    ``` bash
    docker build -t vell001/ubt18.04_xrdp -f ./Dockerfile .
    ```
3. 运行
   可以直接使用我写好的run脚本`./run`运行，默认运行带ros环境的镜像，xrdp端口为`23389`，挂载本地/data到/data上
   当容器已经存在的话，直接使用旧容器运行
   可以根据我的脚本自行按需修改
   进入容器后，还可以运行`/bin/start_xrdp`来重启xrdp
    ``` bash
    #!/usr/bin/env bash
    docker_image="vell001/ubt18.04_ros_xrdp:latest"
    
    docker_name="ubt18.04_ros_xrdp"
    num=$(docker ps -a | grep -w ${docker_name} | wc -l)
    if [ $num -ne 0 ]; then
      container_id=$(docker ps -a | grep -w ${docker_name} | grep -v grep | awk '{print $1}')
      echo "use old container: "$container_id
      docker container start $container_id
      docker exec -d $container_id /bin/start_xrdp
    else
      docker run -it \
        --privileged=true \
        --hostname="$(hostname)" \
        --publish="23389:3389/tcp" \
        --name=${docker_name} \
        -v /data:/data \
        --shm-size="2g" \
        ${docker_image} /bin/bash
    fi
    ```
   启动后就可以在windows上连接rdp了，默认端口23389，用户名：ubuntu，密码：ubuntu
   ![Screenshot of login prompt](https://raw.githubusercontent.com/vell001/docker-xrdp/master/screenshot_1.png)

   首次运行`./run`时会以交互终端运行，exit后容器会关掉，再次运行`./run`
   时会以后台进程方式启动容器，当你想长期使用这个容器时，重启物理机后只需要再次运行`./run`即可
4. 删除容器
   参考`./rm`脚本
    ``` bash
    #!/usr/bin/env bash
    docker stop ubt18.04_ros_xrdp 
    docker rm ubt18.04_ros_xrdp
    ```
5. 保存新镜像
   参考`./commit`脚本
    ``` bash
    #!/usr/bin/env bash
    docker stop ubt18.04_ros_xrdp
    docker commit ubt18.04_ros_xrdp vell001/ubt18.04_ros_xrdp
    ```
6. 提交镜像到hub.docker.com【注意，修改为你自己的docker账号哈】
    ``` bash
    docker push vell001/ubt18.04_ros_xrdp:latest
    ```

# 感谢

xfce4+xrdp部分参考： https://github.com/scottyhardy/docker-remote-desktop

----------

# docker-xrdp

Docker image with RDP server using [xrdp](http://xrdp.org) on Ubuntu with [XFCE](https://xfce.org).

Images are built weekly using the Ubuntu Docker image with the 'latest' tag.

## Running manually with `docker` commands

Download the latest version of the image:

```bash
docker pull vell001/ubt18.04_ros_xrdp
```

To run with an interactive bash session:

```bash
docker run -it \
    --rm \
    --hostname="$(hostname)" \
    --publish="3389:3389/tcp" \
    --name="remote-desktop" \
    vell001/ubt18.04_ros_xrdp:latest /bin/bash
```

To start as a detached daemon:

```bash
docker run --detach \
    --rm \
    --hostname="$(hostname)" \
    --publish="3389:3389/tcp" \
    --name="ubt18.04_ros_xrdp" \
    vell001/ubt18.04_ros_xrdp:latest
```

To stop the detached container:

```bash
docker kill ubt18.04_ros_xrdp
```

## Connecting with an RDP client

All Windows desktops and servers come with Remote Desktop pre-installed and macOS users can download the Microsoft
Remote Desktop application for free from the App Store. For Linux users, I'd suggest using the Remmina Remote Desktop
client.

For the hostname, use `localhost` if the container is hosted on the same machine you're running your Remote Desktop
client on and for remote connections just use the name or IP address of the machine you are connecting to.
NOTE: To connect to a remote machine, it will require TCP port 3389 to be exposed through the firewall.

To log in, use the following default user account details:

```bash
Username: ubuntu
Password: ubuntu
```

![Screenshot of login prompt](https://raw.githubusercontent.com/vell001/docker-xrdp/master/screenshot_1.png)

![Screenshot of XFCE desktop](https://raw.githubusercontent.com/vell001/docker-xrdp/master/screenshot_2.png)

## Building docker-remote-desktop on your own machine

First, clone the GitHub repository:
[commit](commit)

```bash
git clone https://github.com/vell001/docker-xrdp.git

cd docker-xrdp
```

You can then build the image with the supplied script:

```bash
./build
```

Or run the following `docker` command:

```bash
docker build -t ubt18.04_ros_xrdp .
```

## Running local images with scripts

I've created some simple scripts that give the minimum requirements for either running the container interactively or
running as a detached daemon.

To run with an interactive bash session:

```bash
./run
```

To remove a container:

```bash
./rm
```
