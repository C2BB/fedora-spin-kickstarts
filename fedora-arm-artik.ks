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
mariadb
mariadb-server

# Development
glibc-devel
glibc-headers
gcc
gcc-c++
pygobject2
python-dbus
json-c
dbus-python
opencv-devel

# Library
glib2

# multimedia
alsa-utils
pulseaudio
pulseaudio-utils
gstreamer-plugins-base
gstreamer-plugins-base-tools
gstreamer-plugins-good
gstreamer-plugins-bad
gstreamer-plugins-ugly
gstreamer-rtsp
gstreamer
gstreamer-tools

# graphics
libdrm
drm-utils
fbida
evtest

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
dnsmasq
openobex
iperf3

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
cp prebuilt/obexftp/*.rpm $INSTALL_ROOT
cp prebuilt/omxil/*.rpm $INSTALL_ROOT
cp prebuilt/open_jdk/*.rpm $INSTALL_ROOT

mkdir -p $INSTALL_ROOT/artik-plugin
cp prebuilt/artik-plugin/*.rpm $INSTALL_ROOT/artik-plugin

%end

%post

# install rpm
rm -f /etc/fstab
rpm -ivh --force --nodeps /*.rpm
rpm -ivh --force --nodeps /artik-plugin/*.rpm
rm -f /*.rpm
rm -rf /artik-plugin

echo "Import RPM GPG key"
rm -f /var/lib/rpm/__db*
releasever=$(rpm -q --qf '%{version}\n' fedora-release)
basearch=armhfp
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch

rpm -qa | sort

# Note that running rpm recreates the rpm db files which aren't needed/wanted
rm -f /var/lib/rpm/__db*

%end
