lang en_US.UTF-8
keyboard us

bootloader --disabled
cmdline
rootpw root

part / --size=2000 --label=rootfs --fstype ext4

services --enabled=ssh --disabled=network

repo --name=fedora --mirrorlist=http://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
repo --name=updates --mirrorlist=http://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch
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
java-1.8.0-openjdk
terminus-fonts-console
glibc-all-langpacks

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
strace
gdb
tcpdump

# Library
glib2

# multimedia
alsa-utils
pulseaudio
pulseaudio-utils

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
connman
mosquitto

iotivity
srcx-mqtt
srcx-mqttsnclient
srcx-securitycoap
wakaama

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

artik-plugin
artik-plugin-bluetooth-common
artik-plugin-network-common
artik-plugin-audio-common
artik-plugin-usb-common
artik-plugin-zigbee-common
artik-plugin-wifi-common

bluez
bluez-hid2hci
bluez-libs
bluez-obexd
obexftp
obexftp-libs
pulseaudio-module-bluetooth

%end

%post --nochroot
%end

%post

echo "Import RPM GPG key"
rm -f /var/lib/rpm/__db*
releasever=$(rpm -q --qf '%{version}\n' fedora-release)
basearch=armhfp
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch

rpm -qa | sort

# Note that running rpm recreates the rpm db files which aren't needed/wanted
rm -f /var/lib/rpm/__db*

%end
