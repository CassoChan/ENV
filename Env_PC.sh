#!/bin/bash

# lib install setting
lib_install=true
VNC_setting=true
tty_setting=true
time_setting=true
ssh_setting=true
remove_LIB_PAKAGE=true
IP_setting=true

PLOT_install=true
Cartographer_install=true
FasterLIO_install=true

# setting
user_name="orangepi"
user_password=orangepi

# library install
if [ "$lib_install" = true ];
then
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
sudo apt install -y ros-noetic-serial


# plot
sudo apt -y install python2.7-dev
sudo apt -y install pybind11-dev
sudo apt -y install libyaml-cpp-dev
pip3 install matplotlib==3.5.0 -i https://pypi.tuna.tsinghua.edu.cn/simple
pip3 install pytest
sudo apt-get -y install build-essential libgtk2.0-dev libgtk-3-dev libavcodec-dev libavformat-dev libjpeg-dev libswscale-dev libtiff5-dev


# cartographer
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


# liosam
sudo apt-get install -y ros-noetic-navigation
sudo apt-get install -y ros-noetic-robot-localization
sudo apt-get install -y ros-noetic-robot-state-publisher
sudo add-apt-repository ppa:borglab/gtsam-release-4.0
sudo apt install libgtsam-dev libgtsam-unstable-dev
fi

# time synchronization
if [ "$time_setting" = true ];
then
  sudo apt-get install -y ntpdate
  sudo ntpdate time.windows.com
  sudo hwclock --localtime --systohc
fi


# tty setting
if [ "$tty_setting" = true ];
then
cat > myusb.rules << EOL
KERNEL=="ttyUSB*", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE:="0777", SYMLINK+="IMU"
EOL

sudo mv myusb.rules /etc/udev/rules.d
fi

# vnc setting
# https://omar2cloud.github.io/rasp/x11vnc/
if [ "$VNC_setting" = true ];
then
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

# PLOT install
cd
if [ "$PLOT_install" = true ];
then
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
cd
if [ "$Cartographer_install" = true ];
then
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


#remove
cd
if [ "$remove_LIB_PAKAGE" = true ];
then
  rm -rf matplotlibcpp17
  rm -rf library
  rm -rf opencv.zip
  rm -rf opencv-3.4.15
fi


# git && ssh setting
if [ "$ssh_setting" = true ];
then
  git config --global user.name "casun"
  git config --global user.email chenjiacongcjc@163.com
  ssh-keygen -t rsa -C "chenjiacongcjc@163.com"
  ssh -T git@github.com
fi


# IP setting
if [ "$IP_setting" = true ];
then
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

# Faster-LIO
if [ "$FasterLIO_install" = true ];
then
livox-SDK
cd 
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
cd ..
catkin_make

# Faster-LIO
cd
mkdir -p Faster-LIO/src
cd Faster-LIO/src
git clone https://github.com/gaoxiang12/faster-lio.git
cd ..
catkin_make
fi
