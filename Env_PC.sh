#!/bin/bash
############################## lib install setting ##############################
ROS_install=true
lib_install=true
vscode_install=true
ssh_setting=false

##############################       setting       ##############################
echo "输入电脑型号: 0:RK3588芯片 1:桦汉 2:公司电脑 3:我的私人电脑 4:放弃"
read Computer_type
case $Computer_type in
0)
user_name="orangepi"
user_password=orangepi
Change_Browser=true
VNC_setting=true
IP_setting=true
tty_setting=true
;;

1)
user_name="casun"
user_password=casun36689
VNC_setting=true
IP_setting=true
tty_setting=true
;;

2)
user_name="casun"
user_password=1
time_setting=true
IP_setting=true
chrome_install=true
pinyin_install=true
;;

3)
user_name="casso"
user_password=1
time_setting=true
chrome_install=true
pinyin_install=true
;;

*)
echo 没有这个选项
;;

esac

echo "输入需要安装程序: 0:cartographer环境 1:公司3D激光SLAM环境 2:Faster-LIO_SAM 3:Faster-LIO_STD "
read environment
case $environment in
0)
ceres_install=true
Cartographer_install=true
;;

1)
driver_install=true
FasterLIO_install=true
fastlio2localization=true
;;

2)
gtsam_install=true
;;

3)
gtsam_install=true
ceres_install=true
;;

*)
echo 没有这个选项
;;

esac

##############################     ROS install    ##############################
if [ "$ROS_install" = true ];then
mkdir -p /tmp/fishinstall/tools
wget http://mirror.fishros.com/install/install.py -O /tmp/fishinstall/install.py 2>>/dev/null 
source /etc/profile

if [ $UID -eq 0 ];then
    apt-get install sudo 
fi
sudo apt install python3-distro python3-yaml  -y
sudo python3 /tmp/fishinstall/install.py
sudo rm -rf /tmp/fishinstall/
sudo rm fishros
. ~/.bashrc
fi

##############################   library install   ##############################
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
sudo apt install -y cutecom
sudo apt install -y flameshot
sudo apt install -y terminator
sudo apt install -y clang-format

sudo apt install -y pip
sudo apt install -y libpcap-dev
sudo apt install -y pcl-tools
sudo apt install -y ros-noetic-serial
sudo apt install -y libyaml-cpp-dev
sudo apt install -y libeigen3-dev
sudo apt install -y libgoogle-glog-dev
sudo apt install -y libgflags-dev


# geographic
sudo apt-get install -y ros-noetic-geographic-*
sudo apt-get install -y geographiclib-*
sudo apt-get install -y libgeographic-*
sudo ln -s /usr/share/cmake/geographiclib/FindGeographicLib.cmake /usr/share/cmake-3.16/Modules/
fi


###############################      gtsam           ##############################
if [ "$gtsam_install" = true ];then
sudo apt-get install -y ros-noetic-navigation
sudo apt-get install -y ros-noetic-robot-localization
sudo apt-get install -y ros-noetic-robot-state-publisher
sudo add-apt-repository ppa:borglab/gtsam-release-4.0
sudo apt install -y libgtsam-dev libgtsam-unstable-dev
fi


##############################      ceres install     #############################
if [ "$ceres_install" = true ];then
sudo apt-get -y install libatlas-base-dev
sudo apt-get -y install libsuitesparse-dev

echo 输入ceres版本 1: v1.4  2: v2.1
read ceres_version
if [ "$ceres_version" = "1" ];then
git clone -b 1.14.0 https://ceres-solver.googlesource.com/ceres-solver
elif [ "$ceres_version" = "2" ];then
git clone -b 2.1.0 https://ceres-solver.googlesource.com/ceres-solver
else
echo 输入不符合要求
fi

cd ceres-solver
git submodule update --init --recursive
mkdir build
cd build
cmake ..
make -j$(nproc)
sudo make install
fi

############################## time synchronization ##############################
if [ "$time_setting" = true ];then
sudo apt-get install -y ntpdate
sudo ntpdate time.windows.com
sudo hwclock --localtime --systohc
fi


##############################     tty setting     ##############################
if [ "$tty_setting" = true ];then
cat > myusb.rules << EOL
KERNEL=="ttyUSB*", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE:="0777", SYMLINK+="IMU"
KERNEL=="ttyUSB*", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE:="0777", SYMLINK+="MCU"
EOL

sudo mv myusb.rules /etc/udev/rules.d
fi

##############################     vnc setting     ##############################
# https://omar2cloud.github.io/rasp/x11vnc/
if [ "$VNC_setting" = true ];then
cat > x11vnc.service << EOL
[Unit]
Description=x11vnc service
After=display-manager.service network.target syslog.target

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -forever -display :0 -auth guess -passwd 123456
ExecStop=/usr/bin/killall x11vnc
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

sudo apt-get -y install x11vnc
x11vnc -storepasswd
sudo mv x11vnc.service /etc/systemd/system
cd /etc/systemd/system
sudo chmod 777 x11vnc.service
cd
x11vnc -rfbport 5900 -rfbauth /home/${user_name}/.vnc/passwd -display :0 -forever -bg -repeat -nowf -capslock -shared -o /home/${user_name}/.vnc/x11vnc.log
echo ${user_password} | sudo -S systemctl daemon-reload
echo ${user_password} | sudo -S systemctl enable x11vnc.service
echo ${user_password} | sudo -S systemctl start x11vnc.service
fi

##############################      IP setting      ##############################
if [ "$IP_setting" = true ];then

if [ "$Computer_type" = "0" ];then
cat > 00-installer-config.yaml << EOL
network: 
  ethernets: 
    eth0: 
      addresses: [192.168.192.102/24]
      dhcp4: false
  version: 2
  renderer: networkd
EOL
elif [ "$Computer_type" = "1" ];then
cat > 00-installer-config.yaml << EOL
network: 
  ethernets: 
    enp1s0: 
      addresses: [192.168.192.11/24]
      dhcp4: false
  version: 2
  renderer: networkd
EOL
elif [ "$Computer_type" = "2" ];then
cat > 00-installer-config.yaml << EOL
network: 
  ethernets: 
    eno1: 
      addresses: [192.168.192.11/24]
      dhcp4: false
  version: 2
  renderer: networkd
EOL
else
  echo 输入不符合要求
fi

sudo mv 00-installer-config.yaml /etc/netplan
sudo netplan apply
fi


##############################      Browser Change    ###########################
if [ "$Change_Browser" = true ];then
sudo apt install -y iceweasel
fi


##############################      chrome install    ###########################
if [ "$chrome_install" = true ];then
wget -c https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
fi


##############################    vscode install    ##############################
if [ "$vscode_install" = true ];then
sudo apt install -y software-properties-common apt-transport-https wget
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -

if [ "$Computer_type" = "1" ] || [ "$Computer_type" = "2" ] || [ "$Computer_type" = "3" ];then
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
elif [ "$Computer_type" = "0" ];then
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
else
echo There is no such computer type
exit [0]
fi

sudo apt update
sudo apt install -y code

code --install-extension ms-vscode.cpptools-extension-pack
# code --install-extension ms-ceintl.vscode-language-pack-zh-hans
code --install-extension ms-vscode-remote.remote-ssh
code --install-extension ms-iot.vscode-ros
code --install-extension redhat.vscode-yaml
code --install-extension eamodio.gitlens
code --install-extension tomoki1207.pdf
code --install-extension jeff-hykin.better-cpp-syntax
code --install-extension xaver.clang-format
code --install-extension alibaba-cloud.tongyi-lingma
fi

############################## google pinyin ##############################
if [ "$pinyin_install" = true ];then
sudo apt install -y fcitx
im-config
sudo apt install -y fcitx-googlepinyin
fi


############################## git && ssh setting ##############################
if [ "$ssh_setting" = true ];then
git config --global user.name "casun"
git config --global user.email chenjiacongcjc@163.com
ssh-keygen -t rsa -C "chenjiacongcjc@163.com"
ssh -T git@github.com
fi


##############################     PLOT install     ##############################
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


############################## cartographer install ##############################
if [ "$Cartographer_install" = true ];then
cd
# cartographer lib
sudo apt-get install -y clang
sudo apt-get install -y cmake
sudo apt-get install -y google-mock
sudo apt-get install -y libboost-all-dev
sudo apt-get install -y libcairo2-dev
sudo apt-get install -y libcurl4-openssl-dev
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

# # ceres install
# set -o errexit
# set -o verbose
# cd ~/library/ceres-solver/
# mkdir build
# cd build
# cmake .. -G Ninja -DCXX11=ON
# ninja -j$(nproc)
# sudo ninja install


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


##############################      driver          ##############################
if [ "$driver_install" = true ];then
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
git clone https://gitee.com/szcasun/driver.git
cd ..
catkin_make

fi



##############################      Faster-LIO      ##############################
if [ "$FasterLIO_install" = true ];then

# Faster-LIO
cd
mkdir -p Faster-LIO/src
cd Faster-LIO/src
git clone https://github.com/gaoxiang12/faster-lio.git
cd ..
catkin_make

fi


##############################      fast-lio2-map-based-localization      ##############################

if [ "$fastlio2localization" = true ];then
# sophus
cd
git clone https://gitee.com/szcasun/driver.git
cd Sophus
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
