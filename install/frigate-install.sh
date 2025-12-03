#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Authors: MickLesk (CanbiZ)
# Co-Authors: remz1337
# License: MIT | https://github.com/remz1337/ProxmoxVE/raw/remz/LICENSE
# Source: https://frigate.video/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y {jq,wget,xz-utils,python3,python3-dev,python3-distutils,gcc,pkg-config,libhdf5-dev,unzip,build-essential,automake,libtool,ccache,libusb-1.0-0-dev,apt-transport-https,python3.11,python3.11-dev,cmake,git,libgtk-3-dev,libavcodec-dev,libavformat-dev,libswscale-dev,libv4l-dev,libxvidcore-dev,libx264-dev,libjpeg-dev,libpng-dev,libtiff-dev,gfortran,openexr,libatlas-base-dev,libssl-dev,libtbbmalloc2,libtbb-dev,libdc1394-dev,libopenexr-dev,libgstreamer-plugins-base1.0-dev,libgstreamer1.0-dev,tclsh,libopenblas-dev,liblapack-dev,make,moreutils}
msg_ok "Installed Dependencies"

msg_info "Setting Up Hardware Acceleration"
$STD apt-get -y install {va-driver-all,ocl-icd-libopencl1,intel-opencl-icd,vainfo,intel-gpu-tools}
#apt install -y vainfo libva-drm2 libva-x11-2
if [[ "$CTTYPE" == "0" ]]; then
  chgrp video /dev/dri
  chmod 755 /dev/dri
  chmod 660 /dev/dri/*
  sed -i -e 's/^kvm:x:104:$/render:x:104:root,frigate/' -e 's/^render:x:105:root$/kvm:x:105:/' /etc/group
else
  sed -i -e 's/^kvm:x:104:$/render:x:104:frigate/' -e 's/^render:x:105:$/kvm:x:105:/' /etc/group
fi
msg_ok "Set Up Hardware Acceleration"

msg_info "Setting up environment"
#cd ~ && echo "export PATH=$PATH:/usr/local/bin" >> .bashrc
#source .bashrc
export TARGETARCH="amd64"
export CCACHE_DIR=/root/.ccache
export CCACHE_MAXSIZE=2G
# http://stackoverflow.com/questions/48162574/ddg#49462622
export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
# https://askubuntu.com/questions/972516/debian-frontend-environment-variable
export DEBIAN_FRONTEND=noninteractive
# Globally set pip break-system-packages option to avoid having to specify it every time
export PIP_BREAK_SYSTEM_PACKAGES=1
# https://github.com/NVIDIA/nvidia-docker/wiki/Installation-(Native-GPU-Support)
export NVIDIA_VISIBLE_DEVICES=all
export NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"
# Disable tokenizer parallelism warning
# https://stackoverflow.com/questions/62691279/how-to-disable-tokenizers-parallelism-true-false-warning/72926996#729>
export TOKENIZERS_PARALLELISM=true
# https://github.com/huggingface/transformers/issues/27214
export TRANSFORMERS_NO_ADVISORY_WARNINGS=1
# Set OpenCV ffmpeg loglevel to fatal: https://ffmpeg.org/doxygen/trunk/log_8h.html
export OPENCV_FFMPEG_LOGLEVEL=8
# Set HailoRT to disable logging
export HAILORT_LOGGER_PATH=NONE
msg_ok "Setup environment"

msg_info "Downloading Frigate source"
fetch_and_deploy_gh_release "frigate" "blakeblackshear/frigate" "tarball" "latest" "/opt/frigate"
# cd ~
# RELEASE=$(curl -s https://api.github.com/repos/blakeblackshear/frigate/releases/latest | jq -r '.tag_name')
# mkdir -p /opt/frigate/models
# curl -fsSL "https://github.com/blakeblackshear/frigate/archive/refs/tags/${RELEASE}.tar.gz" -o "frigate.tar.gz"
# $STD tar -xzf frigate.tar.gz -C /opt/frigate --strip-components 1
# rm -rf frigate.tar.gz
# cd /opt/frigate
msg_ok "Downloaded Frigate source"

msg_info "Building Nginx with Custom Modules"
#Overwrite version check as debian 12 LXC doesn't have the debian.list file for some reason
sed -i 's|if.*"$VERSION_ID" == "12".*|if \[\[ "$VERSION_ID" == "12" \]\] \&\ \[\[ -f /etc/apt/sources.list.d/debian.list \]\]; then|g' /opt/frigate/docker/main/build_nginx.sh
$STD bash /opt/frigate/docker/main/build_nginx.sh
sed -e '/s6-notifyoncheck/ s/^#*/#/' -i /opt/frigate/docker/main/rootfs/etc/s6-overlay/s6-rc.d/nginx/run
ln -sf /usr/local/nginx/sbin/nginx /usr/local/bin/nginx
msg_ok "Built Nginx"

msg_info "Building SQLite with Custom Modules"
sed -i 's|if.*"$VERSION_ID" == "12".*|if \[\[ "$VERSION_ID" == "12" \]\] \&\ \[\[ -f /etc/apt/sources.list.d/debian.list \]\]; then|g' /opt/frigate/docker/main/build_sqlite_vec.sh
$STD bash /opt/frigate/docker/main/build_sqlite_vec.sh
msg_ok "Built SQLite"

msg_info "Installing go2rtc"
fetch_and_deploy_gh_release "go2rtc" "AlexxIT/go2rtc" "singlefile" "latest" "/usr/local/go2rtc/bin" "go2rtc_linux_amd64"
# mkdir -p /usr/local/go2rtc/bin
# cd /usr/local/go2rtc/bin
# curl -fsSL "https://github.com/AlexxIT/go2rtc/releases/latest/download/go2rtc_linux_amd64" -o "go2rtc"
# chmod +x go2rtc
# ln -sf /usr/local/go2rtc/bin/go2rtc /usr/local/bin/go2rtc
msg_ok "Installed go2rtc"

msg_info "Installing Tempio"
sed -i 's|/rootfs/usr/local|/usr/local|g' /opt/frigate/docker/main/install_tempio.sh
$STD bash /opt/frigate/docker/main/install_tempio.sh
ln -sf /usr/local/tempio/bin/tempio /usr/local/bin/tempio
msg_ok "Installed Tempio"

msg_info "Building libUSB without udev"
cd /opt
wget -q https://github.com/libusb/libusb/archive/v1.0.26.zip -O v1.0.26.zip
$STD unzip v1.0.26.zip
cd libusb-1.0.26
$STD ./bootstrap.sh
$STD ./configure CC='ccache gcc' CCX='ccache g++' --disable-udev --enable-shared
$STD make -j $(nproc --all)
cd /opt/libusb-1.0.26/libusb
mkdir -p '/usr/local/lib'
$STD bash ../libtool  --mode=install /usr/bin/install -c libusb-1.0.la '/usr/local/lib'
mkdir -p '/usr/local/include/libusb-1.0'
$STD install -c -m 644 libusb.h '/usr/local/include/libusb-1.0'
mkdir -p '/usr/local/lib/pkgconfig'
cd  /opt/libusb-1.0.26/
$STD install -c -m 644 libusb-1.0.pc '/usr/local/lib/pkgconfig'
ldconfig
msg_ok "Built libUSB"

msg_info "Installing Pip"
wget -q https://bootstrap.pypa.io/get-pip.py -O get-pip.py
sed -i 's/args.append("setuptools")/args.append("setuptools==77.0.3")/' get-pip.py
$STD python3 get-pip.py "pip"
msg_ok "Installed Pip"

msg_info "Installing Frigate Dependencies"
$STD update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
$STD sed -i '/^nvidia-pyindex/s/^/#/' /opt/frigate/docker/main/requirements.txt
$STD pip3 install -r /opt/frigate/docker/main/requirements.txt
msg_ok "Installed Frigate Dependencies"

msg_info "Building pysqlite3"
sed -i 's|^SQLITE3_VERSION=.*|SQLITE3_VERSION="version-3.46.0"|g' /opt/frigate/docker/main/build_pysqlite3.sh
$STD bash /opt/frigate/docker/main/build_pysqlite3.sh
$STD pip3 wheel --wheel-dir=/wheels -r /opt/frigate/docker/main/requirements-wheels.txt
msg_ok "Built pysqlite3"

msg_info "Installing NodeJS"
NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs
# $STD curl -SLO https://deb.nodesource.com/nsolid_setup_deb.sh
# chmod 500 nsolid_setup_deb.sh
# $STD ./nsolid_setup_deb.sh 20
# $STD apt-get install nodejs -y
# $STD npm install -g npm@10
msg_ok "Installed NodeJS"

# This should be moved to conditional block, only needed if Coral TPU is detected
msg_info "Downloading Coral TPU Model"
cd /
wget -qO edgetpu_model.tflite https://github.com/google-coral/test_data/raw/release-frogfish/ssdlite_mobiledet_coco_qat_postprocess_edgetpu.tflite
msg_ok "Downloaded Coral TPU Model"

msg_info "Downloading CPU Model"
mkdir -p /models
cd /models
wget -qO cpu_model.tflite https://github.com/google-coral/test_data/raw/release-frogfish/ssdlite_mobiledet_coco_qat_postprocess.tflite
cp /opt/frigate/labelmap.txt /labelmap.txt
msg_ok "Downloaded CPU Model"

msg_info "Building Audio Models"
# Get Audio Model and labels
wget -qO yamnet-tflite-classification-tflite-v1.tar.gz https://www.kaggle.com/api/v1/models/google/yamnet/tfLite/classification-tflite/1/download
$STD tar xzf yamnet-tflite-classification-tflite-v1.tar.gz
rm -rf yamnet-tflite-classification-tflite-v1.tar.gz
mv 1.tflite cpu_audio_model.tflite
cp /opt/frigate/audio-labelmap.txt /audio-labelmap.txt
msg_ok "Built Audio Models"

# This should be moved to conditional block, only needed if Hailo AI module is detected
msg_info "Building HailoRT"
$STD bash /opt/frigate/docker/main/install_hailort.sh
cp -a /opt/frigate/docker/main/rootfs/. /
sed -i '/^.*unset DEBIAN_FRONTEND.*$/d' /opt/frigate/docker/main/install_deps.sh
echo "libedgetpu1-max libedgetpu/accepted-eula boolean true" | debconf-set-selections
echo "libedgetpu1-max libedgetpu/install-confirm-max boolean true" | debconf-set-selections
$STD bash /opt/frigate/docker/main/install_deps.sh
$STD pip3 install -U /wheels/*.whl
ldconfig
#Run twice to fix dependency conflict
$STD pip3 install -U /wheels/*.whl
msg_ok "Built HailoRT"

msg_info "Installing OpenVino Runtime and Dev library"
$STD pip3 install -r /opt/frigate/docker/main/requirements-ov.txt
msg_ok "Installed OpenVino Runtime and Dev library"

msg_info "Downloading OpenVino Model"
mkdir -p /models
cd /models
wget -q http://download.tensorflow.org/models/object_detection/ssdlite_mobilenet_v2_coco_2018_05_09.tar.gz
$STD tar -zxvf ssdlite_mobilenet_v2_coco_2018_05_09.tar.gz --no-same-owner
$STD python3 /opt/frigate/docker/main/build_ov_model.py
mkdir -p /openvino-model
cp -r /models/ssdlite_mobilenet_v2.xml /openvino-model/
cp -r /models/ssdlite_mobilenet_v2.bin /openvino-model/
wget -q https://github.com/openvinotoolkit/open_model_zoo/raw/master/data/dataset_classes/coco_91cl_bkgr.txt -O /openvino-model/coco_91cl_bkgr.txt
sed -i 's/truck/car/g' /openvino-model/coco_91cl_bkgr.txt
msg_ok "Downloaded OpenVino Model"

# # Optional model to test
# msg_info "Building D-FINE Model"
# cd /
# $STD git clone https://github.com/Peterande/D-FINE
# cd /D-FINE
# $STD pip3 install -r requirements.txt
# $STD pip3 install onnxsim onnxscript
# mkdir -p models
# cd models
# wget -q https://github.com/Peterande/storage/releases/download/dfinev1.0/dfine_n_coco.pth
# sed -i 's|data = torch.rand(32, 3, 640, 640)|data = torch.rand(1, 3, 640, 640)|g' /D-FINE/tools/deployment/export_onnx.py
# sed -i 's|dynamic_axes=dynamic_axes|dynamo=True|g' /D-FINE/tools/deployment/export_onnx.py
# sed -i 's|opset_version=[[:digit:]]\+|opset_version=18|g' /D-FINE/tools/deployment/export_onnx.py
# sed -i 's|640, 640|320, 320|g' /D-FINE/configs/dfine/include/dfine_hgnetv2.yml
# sed -i 's|640, 640|320, 320|g' /D-FINE/tools/deployment/export_onnx.py
# sed -i 's|load_state_dict(state)|load_state_dict(new_checkpoint, strict=False)|g' /D-FINE/tools/deployment/export_onnx.py
# sed -i '/state = checkpoint\["model"\]/a \
# \
        # # We remove the anchors and valid_mask saved parameters here\
        # new_checkpoint = {}\
        # for k in state:\
          # if "anchors" in k or "valid_mask" in k:\
            # print(k)\
            # continue\
          # new_checkpoint[k] = state[k]' /D-FINE/tools/deployment/export_onnx.py
# set +e
# ######## This line is throwing a segfault but still converting the model successfully...
# $STD python3 /D-FINE/tools/deployment/export_onnx.py -c /D-FINE/configs/dfine/dfine_hgnetv2_n_coco.yml -r /D-FINE/models/dfine_n_coco.pth
# set -e
# msg_ok "Built D-FINE Model"

# # Optional model to test
# msg_info "Downloading YoloX Model"
# mkdir -p /models
# cd /models
# wget -qO yolox_tiny.onnx https://github.com/Megvii-BaseDetection/YOLOX/releases/download/0.1.1rc0/yolox_tiny.onnx
# msg_ok "Downloaded YoloX Model"

msg_info "Installing Frigate"
cd /opt/frigate
$STD pip3 install -r /opt/frigate/docker/main/requirements-dev.txt
$STD bash /opt/frigate/.devcontainer/initialize.sh
$STD make version
cd /opt/frigate/web
$STD npm install
$STD npm run build
cp -r /opt/frigate/web/dist/* /opt/frigate/web/
cd /opt/frigate/
sed -i '/^s6-svc -O \.$/s/^/#/' /opt/frigate/docker/main/rootfs/etc/s6-overlay/s6-rc.d/frigate/run
cp -r /opt/frigate/config/. /config
mkdir -p /media/frigate
curl -fsSL "https://github.com/intel-iot-devkit/sample-videos/raw/master/person-bicycle-car-detection.mp4" -o "/media/frigate/person-bicycle-car-detection.mp4"
echo "tmpfs   /tmp/cache      tmpfs   defaults        0       0" >>/etc/fstab
cat <<EOF >/etc/frigate.env
DEFAULT_FFMPEG_VERSION="7.0"
INCLUDED_FFMPEG_VERSIONS="7.0:5.0"
EOF
cat <<EOF >/config/config.yml
mqtt:
  enabled: false
cameras:
  test:
    ffmpeg:
      inputs:
        - path: /media/frigate/person-bicycle-car-detection.mp4
          input_args: -re -stream_loop -1 -fflags +genpts
          roles:
            - detect
            - rtmp
    detect:
      height: 1080
      width: 1920
      fps: 5
# Optional: Authentication configuration
auth:
  # Optional: Enable authentication
  enabled: false
detect:
  enabled: false
EOF
msg_ok "Installed Frigate"

source <(curl -s https://raw.githubusercontent.com/remz1337/ProxmoxVE/remz/misc/nvidia.func)
nvidia_installed=$(check_nvidia_drivers_installed)
if [ $nvidia_installed == 1 ]; then
  check_nvidia_drivers_version
  echo -e "Nvidia drivers detected. Version ${NVD_VER}"
  msg_info "Installing Nvidia Dependencies"
  os=""
  if [ $PCT_OSTYPE == "debian" ]; then
    os="debian$PCT_OSVERSION"
  elif [ $PCT_OSTYPE == "ubuntu" ]; then
    os_ver=$(echo "$var_version" | sed 's|\.||g')
    os="ubuntu$os_ver"
  fi
  check_cuda_version
  TARGET_CUDA_VER=$(echo $NVD_VER_CUDA | sed 's|\.|-|g')
  $STD apt update
  $STD apt install -y gnupg
  $STD apt-key del 7fa2af80
  wget -q https://developer.download.nvidia.com/compute/cuda/repos/${os}/x86_64/cuda-keyring_1.1-1_all.deb
  $STD dpkg -i cuda-keyring_1.1-1_all.deb
  $STD apt install -y software-properties-common
  $STD apt update
  $STD add-apt-repository -y contrib
  rm cuda-keyring_1.1-1_all.deb
#  if grep -qR "Acquire::http::Proxy" /etc/apt/apt.conf.d/ && [ -f "/etc/apt/sources.list.d/cuda-${os}-x86_64.list" ]; then
#    sed -i "s|https://developer|http://HTTPS///developer|g" /etc/apt/sources.list.d/cuda-${os}-x86_64.list
#  fi
#  $STD apt update && sleep 1
  #Cap to CUDA 12
  if [[ "${NVD_MAJOR_CUDA}" -gt 12 ]]; then
    TARGET_CUDA_VER=12
    NVD_MAJOR_CUDA=12
  fi
  $STD apt update
  $STD apt install -qqy "cuda-toolkit-$TARGET_CUDA_VER"
  $STD apt install -qqy "cudnn-cuda-$NVD_MAJOR_CUDA"
  export PATH=/usr/local/cuda/bin:${PATH:+:${PATH}}
  export LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
  echo "PATH=${PATH}"  >> ~/.bashrc
  echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}" >> ~/.bashrc
  source ~/.bashrc
  ldconfig
  $STD pip3 uninstall -y onnxruntime onnxruntime-openvino tensorflow-cpu
  $STD pip3 install onnxruntime-gpu onnx
  msg_ok "Installed Nvidia Dependencies"

  msg_info "Installing TensorRT Object Detection Model (Patience)"
  $STD pip3 install tensorrt cuda-core[cu${NVD_MAJOR_CUDA}]
  TRT_VER=$(pip freeze | grep -e "^tensorrt==" | sed "s|tensorrt==||g")
  TRT_VER=$(cut -d. -f1-3 <<<${TRT_VER})
  TRT_MAJOR=${TRT_VER%%.*}
  export CUDA_ROOT=/usr/local/cuda
  echo "CUDA_ROOT=${CUDA_ROOT}"  >> ~/.bashrc
  $STD apt-get install -y python3-libnvinfer-dev
  export LD_LIBRARY_PATH=/usr/local/lib/python3.11/dist-packages/tensorrt_libs:${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
  echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}" >> ~/.bashrc
  sed -i 's|if platform.machine() == "x86_64"|if platform.machine() == "x69_69"|g' /opt/frigate/frigate/detectors/plugins/tensorrt.py
  sed -i 's|from cuda import cuda|import cuda.bindings.driver as cuda|g' /opt/frigate/frigate/detectors/plugins/tensorrt.py
  cp -a /opt/frigate/docker/tensorrt/detector/rootfs/. /
  mkdir -p /usr/local/src/tensorrt_demos
  cd /usr/local/src
  fix_tensorrt="$(cat << EOF
#!/bin/bash
sed -i 's|/usr/local/TensorRT-.*/|/usr/local/lib/python3.11/dist-packages/tensorrt_libs/|g' /usr/local/src/tensorrt_demos/plugins/Makefile
EOF
)"
  echo "${fix_tensorrt}" > /opt/frigate/fix_tensorrt.sh
  if [ $TRT_MAJOR -gt 8 ]; then
    echo "sed -i 's|-lnvparsers ||g' /usr/local/src/tensorrt_demos/plugins/Makefile" >> /opt/frigate/fix_tensorrt.sh
    echo "sed -i 's|-lnvToolsExt ||g' /usr/local/src/tensorrt_demos/plugins/Makefile" >> /opt/frigate/fix_tensorrt.sh
  fi
  sed -i '18,21 s|.|#&|' /opt/frigate/docker/tensorrt/detector/tensorrt_libyolo.sh
  sed -i '9 i bash \/opt\/frigate\/fix_tensorrt.sh' /opt/frigate/docker/tensorrt/detector/tensorrt_libyolo.sh 
  $STD bash /opt/frigate/docker/tensorrt/detector/tensorrt_libyolo.sh
  cd /opt/frigate
  #export YOLO_MODELS="yolov4-tiny-288,yolov4-tiny-416,yolov7-tiny-416,yolov7-320"
  export YOLO_MODELS="yolov7-tiny-416"
  export TRT_VER="$TRT_VER"
  $STD bash /opt/frigate/docker/tensorrt/detector/rootfs/etc/s6-overlay/s6-rc.d/trt-model-prepare/run
  cat <<EOF >>/config/config.yml
ffmpeg:
  hwaccel_args: preset-nvidia
#  output_args:
#    record: preset-record-generic-audio-aac
detectors:
  detector01:
    type: tensorrt
#    device: 0
model:
  path: /config/model_cache/tensorrt/yolov7-tiny-416.trt
  input_tensor: nchw
  input_pixel_format: rgb
  width: 416
  height: 416
EOF
  msg_ok "Installed TensorRT Object Detection Model"
elif grep -q -o -m1 -E 'avx[^ ]* | sse4_2' /proc/cpuinfo; then
  msg_ok "AVX or SSE 4.2 Support Detected"
  msg_info "Configuring Openvino Object Detection Model"
  cat <<EOF >>/config/config.yml
ffmpeg:
  hwaccel_args: auto
detectors:
  detector01:
    type: openvino
model:
  width: 300
  height: 300
  input_tensor: nhwc
  input_pixel_format: bgr
  path: /openvino-model/ssdlite_mobilenet_v2.xml
  labelmap_path: /openvino-model/coco_91cl_bkgr.txt
EOF
  msg_ok "Configured Openvino Object Detection Model"
else
  msg_info "Configuring CPU Object Detection Model"
  cat <<EOF >>/config/config.yml
ffmpeg:
  hwaccel_args: auto
model:
  path: /cpu_model.tflite
EOF
  msg_ok "Configured CPU Object Detection Model"
fi

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/create_directories.service
[Unit]
Description=Create necessary directories for logs

[Service]
Type=oneshot
ExecStart=/bin/bash -c '/bin/mkdir -p /dev/shm/logs/{frigate,go2rtc,nginx} && /bin/touch /dev/shm/logs/{frigate/current,go2rtc/current,nginx/current} && /bin/chmod -R 777 /dev/shm/logs'

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now create_directories
sleep 3
cat <<EOF >/etc/systemd/system/go2rtc.service
[Unit]
Description=go2rtc service
After=network.target
After=create_directories.service
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
EnvironmentFile=/etc/frigate.env
ExecStartPre=+rm /dev/shm/logs/go2rtc/current
ExecStart=/bin/bash -c "bash /opt/frigate/docker/main/rootfs/etc/s6-overlay/s6-rc.d/go2rtc/run 2> >(/usr/bin/ts '%%Y-%%m-%%d %%H:%%M:%%.S ' >&2) | /usr/bin/ts '%%Y-%%m-%%d %%H:%%M:%%.S '"
StandardOutput=file:/dev/shm/logs/go2rtc/current
StandardError=file:/dev/shm/logs/go2rtc/current

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now go2rtc
sleep 3
cat <<EOF >/etc/systemd/system/frigate.service
[Unit]
Description=Frigate service
After=go2rtc.service
After=create_directories.service
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
EnvironmentFile=/etc/frigate.env
# Environment=PLUS_API_KEY=
ExecStartPre=+rm /dev/shm/logs/frigate/current
ExecStart=/bin/bash -c "bash /opt/frigate/docker/main/rootfs/etc/s6-overlay/s6-rc.d/frigate/run 2> >(/usr/bin/ts '%%Y-%%m-%%d %%H:%%M:%%.S ' >&2) | /usr/bin/ts '%%Y-%%m-%%d %%H:%%M:%%.S '"
StandardOutput=file:/dev/shm/logs/frigate/current
StandardError=file:/dev/shm/logs/frigate/current

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now frigate
sleep 3
cat <<EOF >/etc/systemd/system/nginx.service
[Unit]
Description=Nginx service
After=frigate.service
After=create_directories.service
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
ExecStartPre=+rm /dev/shm/logs/nginx/current
ExecStart=/bin/bash -c "bash /opt/frigate/docker/main/rootfs/etc/s6-overlay/s6-rc.d/nginx/run 2> >(/usr/bin/ts '%%Y-%%m-%%d %%H:%%M:%%.S ' >&2) | /usr/bin/ts '%%Y-%%m-%%d %%H:%%M:%%.S '"
StandardOutput=file:/dev/shm/logs/nginx/current
StandardError=file:/dev/shm/logs/nginx/current

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now nginx
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
