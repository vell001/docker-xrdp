# docker-remote-desktop
* 增加中文支持
* 安装ros1环境，和slam基础库，如：g2o、gtsam

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

All Windows desktops and servers come with Remote Desktop pre-installed and macOS users can download the Microsoft Remote Desktop application for free from the App Store.  For Linux users, I'd suggest using the Remmina Remote Desktop client.

For the hostname, use `localhost` if the container is hosted on the same machine you're running your Remote Desktop client on and for remote connections just use the name or IP address of the machine you are connecting to.
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

I've created some simple scripts that give the minimum requirements for either running the container interactively or running as a detached daemon.

To run with an interactive bash session:

```bash
./run
```

To remove a container:

```bash
./rm
```
