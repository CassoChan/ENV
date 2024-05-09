#!/bin/bash

# lib install setting
ROS_install=true
lib_install=false
VNC_setting=false
tty_setting=false
IP_setting=false

time_setting=false
ssh_setting=false

PLOT_install=false
Cartographer_install=false
FasterLIO_install=false
KAIST=false

# setting
user_name="orangepi"
user_password=orangepi

if [ "$ROS_install" = true ];then
mkdir -p /tmp/fishinstall/tools
wget http://mirror.fishros.com/install/install.py -O /tmp/fishinstall/install.py 2>>/dev/null 
source /etc/profile
# 强制解锁，太多用户遇到这个问题了，没办法，后续想个办法解决下
# 强解可能会有依赖问题
# sudo rm /var/cache/apt/archives/lock
# sudo rm /var/lib/dpkg/lock
# sudo rm /var/lib/dpkg/lock-frontend
if [ $UID -eq 0 ];then
    apt-get install sudo 
fi
sudo apt install python3-distro python3-yaml  -y
sudo python3 /tmp/fishinstall/install.py
sudo rm -rf /tmp/fishinstall/
sudo rm fishros
. ~/.bashrc
fi

# library install
if [ "$lib_install" = true ];then
# lib update
sudo apt update
sudo apt upgrade


# lib install
sudo apt install -y git
sudo apt install -y vim
sudo apt install -y ssh
sudo apt install -y net-tools
sudo apt install -y htop
sudo apt install -y pip
sudo apt install -y flameshot
sudo apt install -y terminator
sudo apt install -y libpcap-dev
sudo apt install -y pcl-tools
sudo apt install -y ros-noetic-serial
sudo apt install -y libyaml-cpp-dev
sudo apt install -y libgoogle-glog-dev 


# liosam
sudo apt-get install -y ros-noetic-navigation
sudo apt-get install -y ros-noetic-robot-localization
sudo apt-get install -y ros-noetic-robot-state-publisher
sudo add-apt-repository ppa:borglab/gtsam-release-4.0
sudo apt install libgtsam-dev libgtsam-unstable-dev
fi

# time synchronization
if [ "$time_setting" = true ];then
sudo apt-get install -y ntpdate
sudo ntpdate time.windows.com
sudo hwclock --localtime --systohc
fi


# tty setting
if [ "$tty_setting" = true ];then
cat > myusb.rules << EOL
KERNEL=="ttyUSB*", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE:="0777", SYMLINK+="IMU"
EOL

sudo mv myusb.rules /etc/udev/rules.d
fi

# vnc setting
# https://omar2cloud.github.io/rasp/x11vnc/
if [ "$VNC_setting" = true ];then
cat > x11vnc.service << EOL
[Unit]
Description=x11vnc service
After=display-manager.service network.target syslog.target

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -forever -display :0 -auth guess -passwd 1
ExecStop=/usr/bin/killall x11vnc
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

sudo apt-get -y install x11vnc
x11vnc -storepasswd
sudo mv x11vnc.service /etc/systemd/system
x11vnc -rfbport 5900 -rfbauth /home/${user_name}/.vnc/passwd -display :0 -forever -bg -repeat -nowf -capslock -shared -o /home/${user_name}/.vnc/x11vnc.log
echo ${user_password} | sudo -S systemctl daemon-reload
echo ${user_password} | sudo -S systemctl enable x11vnc.service
echo ${user_password} | sudo -S systemctl start x11vnc.service
fi

# IP setting
if [ "$IP_setting" = true ];then
cat > 00-installer-config.yaml << EOL
network: 
  ethernets: 
    eth0: 
      addresses: [192.168.192.102/24]
      dhcp4: false
  version: 2
  renderer: networkd
EOL

sudo mv 00-installer-config.yaml /etc/netplan
sudo netplan apply
fi

# PLOT install
if [ "$PLOT_install" = true ];then
cd
# plot
sudo apt -y install python2.7-dev
sudo apt -y install pybind11-dev
sudo apt -y install libyaml-cpp-dev
pip3 install matplotlib==3.5.0 -i https://pypi.tuna.tsinghua.edu.cn/simple
pip3 install pytest
sudo apt-get -y install build-essential libgtk2.0-dev libgtk-3-dev libavcodec-dev libavformat-dev libjpeg-dev libswscale-dev libtiff5-dev


# opencv 3.4.15
wget -O opencv.zip https://github.com/opencv/opencv/archive/3.4.15.zip
unzip opencv.zip
cd opencv-3.4.15
mkdir build
cd build
cmake -D CMAKE_BUILD_TYPE=Release -D OPENCV_GENERATE_PKGCONFIG=YES ..
make -j$(nproc)
sudo make install


# matplotlibcpp17
cd
git clone https://github.com/soblin/matplotlibcpp17.git
cd matplotlibcpp17
mkdir build
cd build
cmake .. -DADD_DEMO=0
make -j$(nproc)
sudo make install
fi

# cartographer install
if [ "$Cartographer_install" = true ];then
cd
# cartographer lib
sudo apt-get install -y clang
sudo apt-get install -y cmake
sudo apt-get install -y google-mock
sudo apt-get install -y libboost-all-dev
sudo apt-get install -y libcairo2-dev
sudo apt-get install -y libcurl4-openssl-dev
sudo apt-get install -y libeigen3-dev
sudo apt-get install -y libgflags-dev
sudo apt-get install -y libgoogle-glog-dev 
sudo apt-get install -y liblua5.2-dev 
sudo apt-get install -y libsuitesparse-dev
sudo apt-get install -y lsb-release
sudo apt-get install -y ninja-build
sudo apt-get install -y stow
sudo apt -y install libceres-dev
sudo apt -y install python3-sphinx
sudo apt -y install libgmock-dev
sudo apt-get -y install libgrpc++

# ceres install
set -o errexit
set -o verbose
cd ~/library/ceres-solver/
mkdir build
cd build
cmake .. -G Ninja -DCXX11=ON
ninja -j$(nproc)
sudo ninja install


# protoc insall
set -o errexit
set -o verbose
cd ~/library/protobuf/
./autogen.sh
./configure
make -j$(nproc)
sudo make install
sudo ldconfig


# cares install
set -o errexit
set -o verbose
cd ~/library/grpc/third_party/cares/cares
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc)
sudo make install


# grpc insall
set -o errexit
set -o verbose
cd ~/library/grpc
mkdir build
cd build
cmake -DgRPC_INSTALL=ON -DgRPC_BUILD_TESTS=OFF -DgRPC_PROTOBUF_PROVIDER=package -DgRPC_ZLIB_PROVIDER=package -DgRPC_CARES_PROVIDER=package -DgRPC_SSL_PROVIDER=package -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc)
sudo make install


# abseil install
set -o errexit
set -o verbose
cd ~/library/abseil-cpp/
mkdir build
cd build
cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DCMAKE_INSTALL_PREFIX=/usr/local/stow/absl \
  ..
ninja -j$(nproc)
sudo ninja install
cd /usr/local/stow
sudo stow absl


# async_grpc install
set -o errexit
set -o verbose
cd ~/library/async_grpc
mkdir build
cd build
cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  ..
ninja -j$(nproc)
sudo ninja install
fi


# git && ssh setting
if [ "$ssh_setting" = true ];then
git config --global user.name "casun"
git config --global user.email chenjiacongcjc@163.com
ssh-keygen -t rsa -C "chenjiacongcjc@163.com"
ssh -T git@github.com
fi

# Faster-LIO
if [ "$FasterLIO_install" = true ];then
cd
# livox-SDK
git clone https://github.com/Livox-SDK/Livox-SDK.git
cd Livox-SDK
cd build && cmake ..
make -j$(nproc)
sudo make install

# IMU && lslidar driver
cd
mkdir -p driver/src
cd driver/src
git clone https://github.com/casso1993/wit_ros.git
git clone https://github.com/CassoChan/lslidar_cx_driver.git
git clone https://github.com/Livox-SDK/livox_ros_driver.git
cd ..
catkin_make

# Faster-LIO
cd
mkdir -p Faster-LIO/src
cd Faster-LIO/src
git clone https://github.com/gaoxiang12/faster-lio.git
cd ..
catkin_make

# sophus
cd
git clone https://github.com/strasdat/Sophus.git
cd Sophus
git checkout a621ff
mkdir build
cd build
cmake ../ -DUSE_BASIC_LOGGING=ON
make -j$(nproc)
sudo make install

# fast-lio2-map-based-localization
cd
mkdir -p fast-lio2-map-based-localization/src
cd fast-lio2-map-based-localization/src
git clone https://github.com/xz00/fast-lio2-map-based-localization.git
cd ..
source ~/driver/devel/setup.bash
catkin_make
fi

# FAST-LIO-Localization-QN
if [ "$KAIST" = true ];then
cd
sudo apt -y install libomp-dev

# Teaser++
git clone https://github.com/MIT-SPARK/TEASER-plusplus.git
cd TEASER-plusplus && mkdir build && cd build
cmake .. -DENABLE_DIAGNOSTIC_PRINT=OFF -DPYTHON_EXECUTABLE=/usr/bin/python3.8
sudo make install -j$(nproc)
sudo ldconfig

# mapping
mkdir -p ~/mapping/src
cd ~/mapping/src
git clone https://github.com/engcang/FAST-LIO-SAM-QN --recursive
cd ..
catkin build nano_gicp -DCMAKE_BUILD_TYPE=Release
catkin build quatro -DCMAKE_BUILD_TYPE=Release -DQUATRO_TBB=ON
catkin build -DCMAKE_BUILD_TYPE=Release

# Localization
mkdir -p ~/localization/src
cd ~/localization/src
git clone https://github.com/engcang/FAST-LIO-Localization-SC-QN --recursive
cd ..
catkin build nano_gicp -DCMAKE_BUILD_TYPE=Release
catkin build quatro -DCMAKE_BUILD_TYPE=Release -DQUATRO_TBB=ON
catkin build -DCMAKE_BUILD_TYPE=Release
fi