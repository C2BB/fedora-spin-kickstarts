lang en_US.UTF-8
keyboard us

bootloader --disabled
cmdline
rootpw root

part / --size=1200 --label=rootfs --fstype ext4

services --enabled=ssh --disabled=network

%include fedora-repo.ks
repo --name=rpmfusion-free --mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-$releasever&arch=$basearch
repo --name=rpmfusion-free-updates --mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-updates-released-$releasever&arch=$basearch

%packages

# system-core utils
bash
systemd
tar
cpio
openssl
openssh
python
gzip
elfutils
dnf
curl
passwd
nfs-utils
rootfiles
e2fsprogs
dosfstools
findutils
bzip2
xz
man
newt

# Development
glibc-devel
glibc-headers
gcc
gcc-c++

# multimedia
alsa-utils
pulseaudio
pulseaudio-utils

# graphics
libdrm
drm-utils

# network
net-tools
wpa_supplicant
openssh
openssh-clients
openssh-server
dhclient
iputils
wireless-tools
rfkill
avahi
avahi-tools
hostapd
bridge-utils
nss-mdns
iptables-services
libical
sbc

# Web
nodejs

# utility
vim-minimal
procps-ng
i2c-tools
usbutils
wget
python-dbus

# rpmfusion
ffmpeg-libs
mplayer
rpmfusion-free-release

%end

%post --nochroot
cp prebuilt/bluez/*.rpm $INSTALL_ROOT
cp prebuilt/artik-config/*.rpm $INSTALL_ROOT
cp prebuilt/connman/*.rpm $INSTALL_ROOT

echo "Install oracle jdk"
mkdir -p $INSTALL_ROOT/usr/java
tar xf prebuilt/oracle_jdk/jdk*.gz -C $INSTALL_ROOT/usr/java/
cd $INSTALL_ROOT/usr/java
ln -sf jdk* default
%end

%post

# downgrade bluez
rpm -ivh --force --nodeps /*.rpm
rm -f /*.rpm

# fstab
rm /etc/fstab
cat > /etc/fstab << EOF
/dev/mmcblk0p3	/	ext4	errors=remount-ro,noatime,nodiratime	0	1
/dev/mmcblk0p1	/boot	vfat	defaults,rw,owner,flush,umask=000	0	0
/dev/mmcblk0p2	/usr/lib/modules	ext4	defaults,ro	0	0
EOF

echo -n "Setting default runlevel to multiuser text mode"
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
echo .

echo "Cleaning old dnf repodata."

echo "Import RPM GPG key"
rm -f /var/lib/rpm/__db*
releasever=$(rpm -q --qf '%{version}\n' fedora-release)
basearch=armhfp
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch

rpm -qa

# Note that running rpm recreates the rpm db files which aren't needed/wanted
rm -f /var/lib/rpm/__db*

# Limit journal size
sed -i "s/#SystemMaxUse=/SystemMaxUse=10M/" /etc/systemd/journald.conf

# Network configurations
# enable eth0 with dhcp configuration
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="yes"
EOF

# wpa_supplicant
sed -i 's/INTERFACES=\"\"/INTERFACES=\"-iwlan0\"/g' /etc/sysconfig/wpa_supplicant
sed -i 's/DRIVERS=\"\"/DRIVERS=\"-Dnl80211\"/g' /etc/sysconfig/wpa_supplicant

# bluez
systemctl enable bluetooth.service

# rfkill, unblock all
cat > /usr/lib/systemd/system/rfkill-unblock.service << EOF
[Unit]
Description=RFKill-Unblock All Devices
After=systemd-rfkill@.service
Before=bluetooth.service

[Service]
Type=oneshot
ExecStart=/usr/sbin/rfkill unblock all

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable rfkill-unblock.service

# pulse audio
# timer-based scheduling should be turned off
sed -i 's/load-module module-udev-detect/load-module module-udev-detect tsched=0/g' /etc/pulse/default.pa
echo "load-module module-switch-on-connect" >> /etc/pulse/default.pa
cp /etc/pulse/default.pa /etc/pulse/system.pa

cat > /usr/lib/systemd/system/pulseaudio.service << EOF
[Unit]
Description=pulseaudio service
After=dbus.service

[Service]
Type=simple
ExecStart=/usr/bin/pulseaudio --system --daemonize=no --disallow-exit
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable pulseaudio.service

/usr/sbin/usermod -G pulse-access root
/usr/sbin/usermod -a -G audio pulse

cat > /usr/bin/audio_setting.sh << EOF
#!/bin/sh

amixer sset "Digital Output Volume1 L (Manual Mode)" 120
amixer sset "Digital Output Volume1 R (Manual Mode)" 120
amixer sset "Mic Gain Control" 3
amixer sset "Mic Bias MUX" "IN1"
amixer sset "IN1 MUX" "Mic Bias"
amixer sset "Input Select MUX" "LIN1/RIN1"
amixer sset "ADC MUX1" "Mono"
amixer sset "MIC MUX" "AMIC"
amixer sset "ADCPF MUX" "ADC"
amixer sset "DACHP" "ON"
EOF
chmod 755 /usr/bin/audio_setting.sh

cat > /usr/lib/systemd/system/audiosetting.service << EOF
[Unit]
Description=alsa audio setting
After=alsa-state.service
ConditionFileNotEmpty=!/var/lib/alsa/asound.state

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/audio_setting.sh
ExecStartPost=/usr/bin/systemctl restart alsa-state.service
ExecStartPost=/usr/bin/sync

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable audiosetting.service

# pulseaudio settings for bluetooth a2dp_sink
set -i '/<allow own="org.pulseaudio.Server"\/>/a \ \ \ \ <allow send_interface="org.freedesktop.DBus.ObjectManager"/>' /etc/dbus-1/system.d/pulseaudio-system.conf
sed -i '/<allow own="org.pulseaudio.Server"\/>/a \ \ \ \ <allow send_destination="org.bluez"/>' /etc/dbus-1/system.d/pulseaudio-system.conf

sed -i '/<\/busconfig>/i \ \ <policy user="pulse">\n\ \ \ \ <allow send_destination="org.bluez"/>\n\ \ \ \ <allow send_interface="org.freedesktop.DBus.ObjectManager"/>\n\ \ <\/policy>\n'  /etc/dbus-1/system.d/bluetooth.conf

# Firmware install

# auto-load bcmdhd module
cat > /etc/modules-load.d/dhd.conf << EOF
dhd
EOF

cat > /etc/modprobe.d/dhd.conf  << EOF
options dhd firmware_path=/etc/wifi/fw.bin nvram_path=/etc/wifi/nvram.txt
EOF

# auto-load bcm4354 bt firmware
cat > /usr/lib/systemd/system/brcm-firmware.service << EOF
[Unit]
Description=BCM4354 Bluetooth firmware service
Before=bluetooth.target

[Service]
Type=forking
ExecStart=/etc/bluetooth/fwdown.sh
PIDFile=/run/brcm_patchram_plus.pid

[Install]
WantedBy=multi-user.target
EOF

# auto-load hci0 firmware
cat > /etc/udev/rules.d/10-local.rules << EOF
ACTION=="add", KERNEL=="hci0", RUN+="/etc/bluetooth/hciconf.sh"
EOF

systemctl daemon-reload
systemctl enable brcm-firmware.service

# adbd service for debugging purpose
cat > /usr/lib/systemd/system/adbd.service << EOF
[Unit]
Descriptions=Android debug bridge daemon

[Service]
Type=forking
ExecStart=/usr/bin/start_adbd.sh
PIDFile=/run/adbd.pid

[Install]
WantedBy=multi-user.target
EOF

# Enable timesyncd
systemctl enable systemd-timesyncd.service

# Enable systemd-resolved.service
systemctl enable systemd-resolved.service

# Install java alternatives
/usr/sbin/alternatives --install /usr/bin/java java /usr/java/default/jre/bin/java 1
/usr/sbin/alternatives --install /usr/bin/javaws javaws /usr/java/default/jre/bin/javaws 1
/usr/sbin/alternatives --install /usr/bin/javac javac /usr/java/default/bin/javac 1
/usr/sbin/alternatives --install /usr/bin/jar jar /usr/java/default/bin/jar 1

cat > /etc/profile.d/oracle-jdk.sh << EOF
export JAVA_HOME=/usr/java/default
export PATH=\$JAVA_HOME/bin:\$PATH
EOF
chmod +x /etc/profile.d/oracle-jdk.sh

# Sync after sshd key generation
echo "ExecStartPost=/usr/bin/sync" >> /usr/lib/systemd/system/sshd-keygen.service

%end

%post --nochroot
cp -rf prebuilt/wifi/* $INSTALL_ROOT
cp -rf prebuilt/bluetooth/* $INSTALL_ROOT
cp -rf prebuilt/adbd/* $INSTALL_ROOT
cp -rf prebuilt/openssl/* $INSTALL_ROOT
cp -rf prebuilt/domainManager/* $INSTALL_ROOT
cp -rf prebuilt/connman/var $INSTALL_ROOT
cp -rf prebuilt/connman/etc $INSTALL_ROOT
%end
