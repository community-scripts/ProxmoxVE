#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Authors: MickLesk (CanbiZ) | Co-Authors: remz1337
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://frigate.video/ | Github: https://github.com/blakeblackshear/frigate

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

source /etc/os-release
if [[ "$VERSION_ID" != "12" ]]; then
  msg_error "Frigate requires Debian 12 (Bookworm) due to Python 3.11 dependencies"
  exit 238
fi

msg_info "Converting APT sources to DEB822 format"
if [ -f /etc/apt/sources.list ]; then
  cat >/etc/apt/sources.list.d/debian.sources <<'EOF'
Types: deb
URIs: http://deb.debian.org/debian
Suites: bookworm
Components: main contrib
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://deb.debian.org/debian
Suites: bookworm-updates
Components: main contrib
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org
Suites: bookworm-security
Components: main contrib
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
  mv /etc/apt/sources.list /etc/apt/sources.list.bak
  $STD apt update
fi
msg_ok "Converted APT sources"

msg_info "Installing Dependencies"
$STD apt install -y \
  xz-utils \
  python3 \
  python3-dev \
  python3-pip \
  gcc \
  pkg-config \
  libhdf5-dev \
  build-essential \
  automake \
  libtool \
  ccache \
  libusb-1.0-0-dev \
  apt-transport-https \
  cmake \
  git \
  libgtk-3-dev \
  libavcodec-dev \
  libavformat-dev \
  libswscale-dev \
  libv4l-dev \
  libxvidcore-dev \
  libx264-dev \
  libjpeg-dev \
  libpng-dev \
  libtiff-dev \
  gfortran \
  openexr \
  libssl-dev \
  libtbbmalloc2 \
  libtbb-dev \
  libdc1394-dev \
  libopenexr-dev \
  libgstreamer-plugins-base1.0-dev \
  libgstreamer1.0-dev \
  tclsh \
  libopenblas-dev \
  liblapack-dev \
  libgomp1 \
  make \
  moreutils
msg_ok "Installed Dependencies"

setup_hwaccel

export TARGETARCH="amd64"
export CCACHE_DIR=/root/.ccache
export CCACHE_MAXSIZE=2G
export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
export PIP_BREAK_SYSTEM_PACKAGES=1
export NVIDIA_VISIBLE_DEVICES=all
export NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"
export TOKENIZERS_PARALLELISM=true
export TRANSFORMERS_NO_ADVISORY_WARNINGS=1
export OPENCV_FFMPEG_LOGLEVEL=8
export PYTHONWARNINGS="ignore:::numpy.core.getlimits"
export HAILORT_LOGGER_PATH=NONE
export TF_CPP_MIN_LOG_LEVEL=3
export TF_CPP_MIN_VLOG_LEVEL=3
export TF_ENABLE_ONEDNN_OPTS=0
export AUTOGRAPH_VERBOSITY=0
export GLOG_minloglevel=3
export GLOG_logtostderr=0

fetch_and_deploy_gh_release "frigate" "blakeblackshear/frigate" "tarball" "v0.17.1" "/opt/frigate"

msg_info "Building Nginx"
$STD bash /opt/frigate/docker/main/build_nginx.sh
sed -e '/s6-notifyoncheck/ s/^#*/#/' -i /opt/frigate/docker/main/rootfs/etc/s6-overlay/s6-rc.d/nginx/run
ln -sf /usr/local/nginx/sbin/nginx /usr/local/bin/nginx
msg_ok "Built Nginx"

msg_info "Building SQLite Extensions"
$STD bash /opt/frigate/docker/main/build_sqlite_vec.sh
msg_ok "Built SQLite Extensions"

fetch_and_deploy_gh_release "go2rtc" "AlexxIT/go2rtc" "singlefile" "latest" "/usr/local/go2rtc/bin" "go2rtc_linux_amd64"

msg_info "Installing Tempio"
sed -i 's|/rootfs/usr/local|/usr/local|g' /opt/frigate/docker/main/install_tempio.sh
$STD bash /opt/frigate/docker/main/install_tempio.sh
ln -sf /usr/local/tempio/bin/tempio /usr/local/bin/tempio
msg_ok "Installed Tempio"

msg_info "Building libUSB"
fetch_and_deploy_gh_release "libusb" "libusb/libusb" "tarball" "v1.0.26" "/opt/libusb"
cd /opt/libusb
$STD ./bootstrap.sh
$STD ./configure CC='ccache gcc' CCX='ccache g++' --disable-udev --enable-shared
$STD make -j "$(nproc)"
cd /opt/libusb/libusb
mkdir -p /usr/local/lib /usr/local/include/libusb-1.0 /usr/local/lib/pkgconfig
$STD bash ../libtool --mode=install /usr/bin/install -c libusb-1.0.la /usr/local/lib
install -c -m 644 libusb.h /usr/local/include/libusb-1.0
cd /opt/libusb/
install -c -m 644 libusb-1.0.pc /usr/local/lib/pkgconfig
ldconfig
msg_ok "Built libUSB"

msg_info "Bootstrapping pip"
curl_with_retry "https://bootstrap.pypa.io/get-pip.py" "/tmp/get-pip.py"
sed -i 's/args.append("setuptools")/args.append("setuptools==77.0.3")/' /tmp/get-pip.py
$STD python3 /tmp/get-pip.py "pip"
rm -f /tmp/get-pip.py
msg_ok "Bootstrapped pip"

msg_info "Installing Python Dependencies"
$STD pip3 install -r /opt/frigate/docker/main/requirements.txt
msg_ok "Installed Python Dependencies"

msg_info "Building Python Wheels (Patience)"
mkdir -p /wheels
$STD bash /opt/frigate/docker/main/build_pysqlite3.sh
for i in {1..3}; do
  $STD pip3 wheel --wheel-dir=/wheels -r /opt/frigate/docker/main/requirements-wheels.txt --default-timeout=300 --retries=3 && break
  [[ $i -lt 3 ]] && sleep 10
done
msg_ok "Built Python Wheels"

NODE_VERSION="20" setup_nodejs

msg_info "Downloading Inference Models"
mkdir -p /models /openvino-model
curl_with_retry "https://github.com/google-coral/test_data/raw/release-frogfish/ssdlite_mobiledet_coco_qat_postprocess_edgetpu.tflite" "/edgetpu_model.tflite"
curl_with_retry "https://github.com/google-coral/test_data/raw/release-frogfish/ssdlite_mobiledet_coco_qat_postprocess.tflite" "/models/cpu_model.tflite"
cp /opt/frigate/labelmap.txt /labelmap.txt
msg_ok "Downloaded Inference Models"

msg_info "Downloading Audio Model"
curl_with_retry "https://www.kaggle.com/api/v1/models/google/yamnet/tfLite/classification-tflite/1/download" "/tmp/yamnet.tar.gz"
$STD tar xzf /tmp/yamnet.tar.gz -C /
mv /1.tflite /cpu_audio_model.tflite
cp /opt/frigate/audio-labelmap.txt /audio-labelmap.txt
rm -f /tmp/yamnet.tar.gz
msg_ok "Downloaded Audio Model"

msg_info "Installing OpenVino"
$STD pip3 install -r /opt/frigate/docker/main/requirements-ov.txt
msg_ok "Installed OpenVino"

msg_info "Building OpenVino Model"
cd /models
curl_with_retry "http://download.tensorflow.org/models/object_detection/ssdlite_mobilenet_v2_coco_2018_05_09.tar.gz" "ssdlite_mobilenet_v2_coco_2018_05_09.tar.gz"
$STD tar -zxf ssdlite_mobilenet_v2_coco_2018_05_09.tar.gz --no-same-owner
if python3 /opt/frigate/docker/main/build_ov_model.py &>/dev/null; then
  mkdir -p /openvino-model
  cp /models/ssdlite_mobilenet_v2.xml /openvino-model/
  cp /models/ssdlite_mobilenet_v2.bin /openvino-model/
  OV_LABELS=$(python3 -c "import omz_tools; import os; print(os.path.join(omz_tools.__path__[0], 'data/dataset_classes/coco_91cl_bkgr.txt'))" 2>/dev/null)
  if [[ -n "$OV_LABELS" && -f "$OV_LABELS" ]]; then
    ln -sf "$OV_LABELS" /openvino-model/coco_91cl_bkgr.txt
  else
    OV_LABELS=$(find /usr/local/lib -name "coco_91cl_bkgr.txt" 2>/dev/null | head -1)
    if [[ -n "$OV_LABELS" ]]; then
      ln -sf "$OV_LABELS" /openvino-model/coco_91cl_bkgr.txt
    else
      curl_with_retry "https://raw.githubusercontent.com/openvinotoolkit/open_model_zoo/master/data/dataset_classes/coco_91cl_bkgr.txt" "/openvino-model/coco_91cl_bkgr.txt"
    fi
  fi
  sed -i 's/truck/car/g' /openvino-model/coco_91cl_bkgr.txt
  msg_ok "Built OpenVino Model"
else
  msg_warn "OpenVino build failed (CPU may not support required instructions). Frigate will use CPU model."
fi

msg_info "Installing HailoRT Runtime"
$STD bash /opt/frigate/docker/main/install_hailort.sh
cp -a /opt/frigate/docker/main/rootfs/. /
sed -i '/^.*unset DEBIAN_FRONTEND.*$/d' /opt/frigate/docker/main/install_deps.sh
echo "libedgetpu1-max libedgetpu/accepted-eula boolean true" | debconf-set-selections
echo "libedgetpu1-max libedgetpu/install-confirm-max boolean true" | debconf-set-selections
echo 'force-overwrite' >/etc/dpkg/dpkg.cfg.d/force-overwrite
$STD bash /opt/frigate/docker/main/install_deps.sh
rm -f /etc/dpkg/dpkg.cfg.d/force-overwrite
$STD pip3 install -U /wheels/*.whl
ldconfig
msg_ok "Installed HailoRT Runtime"

msg_info "Installing MemryX Runtime"
$STD bash /opt/frigate/docker/main/install_memryx.sh
msg_ok "Installed MemryX Runtime"

msg_info "Building Frigate Application (Patience)"
cd /opt/frigate
$STD pip3 install -r /opt/frigate/docker/main/requirements-dev.txt
$STD bash /opt/frigate/.devcontainer/initialize.sh
$STD make version
cd /opt/frigate/web
$STD npm install
$STD npm run build
mv /opt/frigate/web/dist/BASE_PATH/monacoeditorwork/* /opt/frigate/web/dist/assets/
rm -rf /opt/frigate/web/dist/BASE_PATH
cp -r /opt/frigate/web/dist/* /opt/frigate/web/
sed -i '/^s6-svc -O \.$/s/^/#/' /opt/frigate/docker/main/rootfs/etc/s6-overlay/s6-rc.d/frigate/run
msg_ok "Built Frigate Application"

msg_info "Configuring Frigate"
mkdir -p /config /media/frigate
cp -r /opt/frigate/config/. /config

curl_with_retry "https://github.com/intel-iot-devkit/sample-videos/raw/master/person-bicycle-car-detection.mp4" "/media/frigate/person-bicycle-car-detection.mp4"

echo "tmpfs   /tmp/cache      tmpfs   defaults        0       0" >>/etc/fstab

cat <<EOF >/etc/frigate.env
DEFAULT_FFMPEG_VERSION="7.0"
INCLUDED_FFMPEG_VERSIONS="7.0:5.0"
NVIDIA_VISIBLE_DEVICES=all
NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"
TOKENIZERS_PARALLELISM=true
TRANSFORMERS_NO_ADVISORY_WARNINGS=1
OPENCV_FFMPEG_LOGLEVEL=8
PYTHONWARNINGS="ignore:::numpy.core.getlimits"
HAILORT_LOGGER_PATH=NONE
TF_CPP_MIN_LOG_LEVEL=3
TF_CPP_MIN_VLOG_LEVEL=3
TF_ENABLE_ONEDNN_OPTS=0
AUTOGRAPH_VERBOSITY=0
GLOG_minloglevel=3
GLOG_logtostderr=0
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
    detect:
      height: 1080
      width: 1920
      fps: 5
auth:
  enabled: false
detect:
  enabled: false
EOF

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
elif grep -q -o -m1 -E 'avx[^ ]*|sse4_2' /proc/cpuinfo && [[ -f /openvino-model/ssdlite_mobilenet_v2.xml ]] && [[ -f /openvino-model/coco_91cl_bkgr.txt ]]; then
  cat <<EOF >>/config/config.yml
ffmpeg:
  hwaccel_args: auto
detectors:
  detector01:
    type: openvino
    device: AUTO
model:
  width: 300
  height: 300
  input_tensor: nhwc
  input_pixel_format: bgr
  path: /openvino-model/ssdlite_mobilenet_v2.xml
  labelmap_path: /openvino-model/coco_91cl_bkgr.txt
EOF
else
  msg_info "Configuring CPU Object Detection Model"
  cat <<EOF >>/config/config.yml
ffmpeg:
  hwaccel_args: auto
model:
  path: /models/cpu_model.tflite
EOF
fi
msg_ok "Configured Frigate"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/create_directories.service
[Unit]
Description=Create necessary directories for Frigate logs
Before=frigate.service go2rtc.service nginx.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c '/bin/mkdir -p /dev/shm/logs/{frigate,go2rtc,nginx} && /bin/touch /dev/shm/logs/{frigate/current,go2rtc/current,nginx/current} && /bin/chmod -R 777 /dev/shm/logs'

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/go2rtc.service
[Unit]
Description=go2rtc streaming service
After=network.target create_directories.service
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
EnvironmentFile=/etc/frigate.env
ExecStartPre=+rm -f /dev/shm/logs/go2rtc/current
ExecStart=/bin/bash -c "bash /opt/frigate/docker/main/rootfs/etc/s6-overlay/s6-rc.d/go2rtc/run 2> >(/usr/bin/ts '%%Y-%%m-%%d %%H:%%M:%%.S ' >&2) | /usr/bin/ts '%%Y-%%m-%%d %%H:%%M:%%.S '"
StandardOutput=file:/dev/shm/logs/go2rtc/current
StandardError=file:/dev/shm/logs/go2rtc/current

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/frigate.service
[Unit]
Description=Frigate NVR service
After=go2rtc.service create_directories.service
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
EnvironmentFile=/etc/frigate.env
ExecStartPre=+rm -f /dev/shm/logs/frigate/current
ExecStart=/bin/bash -c "bash /opt/frigate/docker/main/rootfs/etc/s6-overlay/s6-rc.d/frigate/run 2> >(/usr/bin/ts '%%Y-%%m-%%d %%H:%%M:%%.S ' >&2) | /usr/bin/ts '%%Y-%%m-%%d %%H:%%M:%%.S '"
StandardOutput=file:/dev/shm/logs/frigate/current
StandardError=file:/dev/shm/logs/frigate/current

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/nginx.service
[Unit]
Description=Nginx reverse proxy for Frigate
After=frigate.service create_directories.service
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
ExecStartPre=+rm -f /dev/shm/logs/nginx/current
ExecStart=/bin/bash -c "bash /opt/frigate/docker/main/rootfs/etc/s6-overlay/s6-rc.d/nginx/run 2> >(/usr/bin/ts '%%Y-%%m-%%d %%H:%%M:%%.S ' >&2) | /usr/bin/ts '%%Y-%%m-%%d %%H:%%M:%%.S '"
StandardOutput=file:/dev/shm/logs/nginx/current
StandardError=file:/dev/shm/logs/nginx/current

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable -q --now create_directories
sleep 2
systemctl enable -q --now go2rtc
sleep 2
systemctl enable -q --now frigate
sleep 2
systemctl enable -q --now nginx
msg_ok "Created Services"

msg_info "Cleaning Up"
rm -rf /opt/libusb /wheels /models/*.tar.gz
msg_ok "Cleaned Up"

motd_ssh
customize
cleanup_lxc
