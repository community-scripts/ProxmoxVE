#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Authors: MickLesk (CanbiZ)
# Co-Authors: remz1337
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://frigate.video/

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
  exit 1
fi

msg_info "Converting APT sources to DEB822 format"
if [ -f /etc/apt/sources.list ]; then
  cat > /etc/apt/sources.list.d/debian.sources <<'EOF'
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
  $STD apt-get update
fi
msg_ok "Converted APT sources"

msg_info "Installing Dependencies"
$STD apt-get install -y \
  jq \
  wget \
  xz-utils \
  python3 \
  python3-dev \
  python3-pip \
  gcc \
  pkg-config \
  libhdf5-dev \
  unzip \
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
  make \
  moreutils
msg_ok "Installed Dependencies"

msg_info "Setting Up Hardware Acceleration"
# Use native packages for hardware acceleration
# intel-media-va-driver-non-free was renamed to intel-media-va-driver in newer releases
$STD apt-get install -y \
  vainfo \
  intel-media-va-driver \
  intel-gpu-tools \
  mesa-va-drivers \
  mesa-vulkan-drivers || true
msg_ok "Set Up Hardware Acceleration"

msg_info "Configuring GPU Access"
if [[ "$CTTYPE" == "0" ]]; then
  sed -i -e 's/^kvm:x:104:$/render:x:104:root,frigate/' -e 's/^render:x:105:root$/kvm:x:105:/' /etc/group
else
  sed -i -e 's/^kvm:x:104:$/render:x:104:frigate/' -e 's/^render:x:105:$/kvm:x:105:/' /etc/group
fi
msg_ok "Configured GPU Access"

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
export HAILORT_LOGGER_PATH=NONE

fetch_and_deploy_gh_release "frigate" "blakeblackshear/frigate" "tarball" "latest" "/opt/frigate"

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
cd /opt
wget -q https://github.com/libusb/libusb/archive/v1.0.26.zip -O libusb.zip
$STD unzip -q libusb.zip
cd libusb-1.0.26
$STD ./bootstrap.sh
$STD ./configure CC='ccache gcc' CCX='ccache g++' --disable-udev --enable-shared
$STD make -j "$(nproc)"
cd /opt/libusb-1.0.26/libusb
mkdir -p /usr/local/lib /usr/local/include/libusb-1.0 /usr/local/lib/pkgconfig
$STD bash ../libtool --mode=install /usr/bin/install -c libusb-1.0.la /usr/local/lib
install -c -m 644 libusb.h /usr/local/include/libusb-1.0
cd /opt/libusb-1.0.26/
install -c -m 644 libusb-1.0.pc /usr/local/lib/pkgconfig
ldconfig
msg_ok "Built libUSB"

msg_info "Installing Python Dependencies"
$STD pip3 install -r /opt/frigate/docker/main/requirements.txt
msg_ok "Installed Python Dependencies"

msg_info "Building Python Wheels (Patience)"
mkdir -p /wheels
sed -i 's|^SQLITE3_VERSION=.*|SQLITE3_VERSION="version-3.46.0"|g' /opt/frigate/docker/main/build_pysqlite3.sh
$STD bash /opt/frigate/docker/main/build_pysqlite3.sh
for i in {1..3}; do
  $STD pip3 wheel --wheel-dir=/wheels -r /opt/frigate/docker/main/requirements-wheels.txt --default-timeout=300 --retries=3 && break
  [[ $i -lt 3 ]] && sleep 10
done
msg_ok "Built Python Wheels"

NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs

msg_info "Downloading Inference Models"
mkdir -p /models /openvino-model
wget -q -O /edgetpu_model.tflite https://github.com/google-coral/test_data/raw/release-frogfish/ssdlite_mobiledet_coco_qat_postprocess_edgetpu.tflite
wget -q -O /models/cpu_model.tflite https://github.com/google-coral/test_data/raw/release-frogfish/ssdlite_mobiledet_coco_qat_postprocess.tflite
cp /opt/frigate/labelmap.txt /labelmap.txt
msg_ok "Downloaded Inference Models"

msg_info "Downloading Audio Model"
wget -q -O /tmp/yamnet.tar.gz https://www.kaggle.com/api/v1/models/google/yamnet/tfLite/classification-tflite/1/download
$STD tar xzf /tmp/yamnet.tar.gz -C /
mv /1.tflite /cpu_audio_model.tflite
cp /opt/frigate/audio-labelmap.txt /audio-labelmap.txt
rm -f /tmp/yamnet.tar.gz
msg_ok "Downloaded Audio Model"

msg_info "Installing HailoRT Runtime"
$STD bash /opt/frigate/docker/main/install_hailort.sh
cp -a /opt/frigate/docker/main/rootfs/. /
sed -i '/^.*unset DEBIAN_FRONTEND.*$/d' /opt/frigate/docker/main/install_deps.sh
echo "libedgetpu1-max libedgetpu/accepted-eula boolean true" | debconf-set-selections
echo "libedgetpu1-max libedgetpu/install-confirm-max boolean true" | debconf-set-selections
$STD bash /opt/frigate/docker/main/install_deps.sh
$STD pip3 install -U /wheels/*.whl
ldconfig
msg_ok "Installed HailoRT Runtime"

msg_info "Installing OpenVino"
$STD pip3 install -r /opt/frigate/docker/main/requirements-ov.txt
msg_ok "Installed OpenVino"

msg_info "Building OpenVino Model"
cd /models
wget -q http://download.tensorflow.org/models/object_detection/ssdlite_mobilenet_v2_coco_2018_05_09.tar.gz
$STD tar -zxf ssdlite_mobilenet_v2_coco_2018_05_09.tar.gz --no-same-owner
if python3 /opt/frigate/docker/main/build_ov_model.py 2>&1; then
  cp /models/ssdlite_mobilenet_v2.xml /openvino-model/
  cp /models/ssdlite_mobilenet_v2.bin /openvino-model/
  wget -q https://github.com/openvinotoolkit/open_model_zoo/raw/master/data/dataset_classes/coco_91cl_bkgr.txt -O /openvino-model/coco_91cl_bkgr.txt
  sed -i 's/truck/car/g' /openvino-model/coco_91cl_bkgr.txt
  msg_ok "Built OpenVino Model"
else
  msg_warn "OpenVino build failed (CPU may not support required instructions). Frigate will use CPU model."
fi

msg_info "Building Frigate Application (Patience)"
cd /opt/frigate
$STD pip3 install -r /opt/frigate/docker/main/requirements-dev.txt
$STD bash /opt/frigate/.devcontainer/initialize.sh
$STD make version
cd /opt/frigate/web
$STD npm install
$STD npm run build
cp -r /opt/frigate/web/dist/* /opt/frigate/web/
sed -i '/^s6-svc -O \.$/s/^/#/' /opt/frigate/docker/main/rootfs/etc/s6-overlay/s6-rc.d/frigate/run
msg_ok "Built Frigate Application"

msg_info "Configuring Frigate"
mkdir -p /config /media/frigate
cp -r /opt/frigate/config/. /config

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
auth:
  enabled: false
detect:
  enabled: false
EOF

if grep -q -o -m1 -E 'avx[^ ]*|sse4_2' /proc/cpuinfo; then
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
else
  cat <<EOF >>/config/config.yml
ffmpeg:
  hwaccel_args: auto
model:
  path: /cpu_model.tflite
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
rm -rf /opt/libusb.zip /opt/libusb-1.0.26 /wheels /models/*.tar.gz
msg_ok "Cleaned Up"

motd_ssh
customize
cleanup_lxc
