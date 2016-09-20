lang en_US.UTF-8
keyboard us

bootloader --disabled
cmdline
rootpw root

part / --size=2000 --label=rootfs --fstype ext4

services --enabled=ssh --disabled=network

repo --name=fedora --baseurl=http://download.fedoraproject.org/pub/fedora/linux/releases/$releasever/Everything/$basearch/os/
repo --name=updates --baseurl=http://download.fedoraproject.org/pub/fedora/linux/updates/$releasever/$basearch/ --excludepkgs=bluez,bluez-hid2hci,bluez-libs,bluez-obexd
repo --name=rpmfusion-free --baseurl=http://download1.rpmfusion.org/free/fedora/releases/$releasever/Everything/$basearch/os/
repo --name=rpmfusion-free-updates --baseurl=http://download1.rpmfusion.org/free/fedora/updates/$releasever/$basearch/

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
iotivity-service
iotivity-test
wakaama
libcoap

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
artik-plugin-license
artik-plugin-bluetooth-common
artik-plugin-network-common
artik-plugin-audio-common
artik-plugin-usb-common
artik-plugin-wifi-common

zigbeed
libartik-sdk-base
libartik-sdk-zigbee

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

sed -i 's/^metalink.*/&\nexclude=bluez*,libdrm,sbc/' /etc/yum.repos.d/fedora-updates.repo

rpm -qa | sort

# Note that running rpm recreates the rpm db files which aren't needed/wanted
rm -f /var/lib/rpm/__db*

%end
