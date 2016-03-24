# ARTIK Fedora Root file system
## Contents
1. [Introduction](#1-introduction)
2. [License](#2-license)
3. [Directory structure](#3-directory-structure)
4. [Build guide](#4-build-guide)

## 1. Introduction
This 'fedora-spin-kickstarts' repository helps to create an ARTIK Fedora root
file system. The artik fedora is based on fedora 22 arm version and customized
for ARTIK5(artik520) and ARTIK10(artik1020) boards.
(Unfortunately, the fedora arm version can be only generated from the arm
machine such as odroid xu3 and artik10 board. You can also try it on the
qemu-system-arm)

---
## 2. License
The software is distributed under the GPLv3 because the 'spin-kickstarts' of
fedora is also under GPLv3.

---
## 3. Directory structure
### kickstart file
The kickstart file is an automated installation method to install Fedora or
Red Hat Enterprise Linux. If you want to modify or add a new package, you can
refer 'pykickstart' wiki page.(https://github.com/rhinstaller/pykickstart/blob/master/docs/kickstart-docs.rst)
### directory structure
+ fedora-arm-artik.ks : kickstart file for artik fedora image
+ prebuilt : prebuilt binaries or rpm packages

---
## 4. Build guide
### 4.1 Prerequisites(You can skip this stage if you're making an image on ARM board)
#### 4.1.1 Download a Fedora minimal image
```
mkdir artik-fedora
cd artik-fedora
wget http://download.fedoraproject.org/pub/fedora/linux/releases/22/Images/armhfp/Fedora-Minimal-armhfp-22-3-sda.raw.xz
unxz -v Fedora-Minimal-armhfp-22-3-sda.raw.xz
```

#### 4.1.2 Install 'libguestfs-tools' to extract the boot files and expand the disk image
```
sudo apt-get install libguestfs-tools
qemu-img resize Fedora-Minimal-armhfp-22-3-sda.raw +10G
```

#### 4.1.3 Archive 'spin-kickstarts'
```
cd ~/fedora-spin-kickstarts
git archive --format=tar.gz --prefix=spin-kickstarts/ HEAD > ../spin-kickstarts.tar.gz
```

#### 4.1.4 Copy the archive into qemu image
```
cd ~/artik-fedora
sudo virt-copy-in -a Fedora-Minimal-armhfp-22-3-sda.raw ~/spin-kickstarts.tar.gz /root/
```

#### 4.1.4 Run 'qemu-system-arm' with prebuilt kernel
```
sudo apt-get install qemu-system-arm
sudo virt-copy-out -a Fedora-Minimal-armhfp-22-3-sda.raw /boot .

sudo qemu-system-arm -machine vexpress-a15 -m 4096 -nographic -net nic -net user \
	     -append "console=ttyAMA0,115200n8 rw root=/dev/mmcblk0p3 rootwait physmap.enabled=0" \
	     -kernel boot/vmlinuz-4.0.4-301.fc22.armv7hl \
	     -initrd boot/initramfs-4.0.4-301.fc22.armv7hl.img \
	     -dtb boot/dtb-4.0.4-301.fc22.armv7hl/vexpress-v2p-ca15_a7.dtb \
	     -sd Fedora-Minimal-armhfp-22-3-sda.raw
# The first booting is so long and you'll need to set up the initial setting.
Initial setup of Fedora 22 (Twenty Two)

	 1) [x] Language settings                 2) [!] Timezone settings
	         (English (United States))                (Timezone is not set.)
	 3) [!] Root password                     4) [!] User creation
	         (Password is not set.)                   (No user will be created)
# You should set Timezone and Root password and you don't need to create a user
# If you complete the configurations, choice 'c' to continue boot up.

# To resize the last filesystem(mmcblk0p3)
fdisk /dev/mmcblk0<<_EOF_
p
d
3
n
p
3



w
_EOF_

partprobe
resize2fs /dev/mmcblk0p3
```

### 4.2 Generate an artik image
(If you have an ARM board and skip 4.1 stage, you'll need (#4.1.3) and copy it into your board through scp or microSD.)

#### 4.2.1 Download an appliance-tools
```
dnf install appliance-tools tar
# You have to wait long time until completing rpm repository update.

# Disable firewall setting
sed -i '/FirewallConfig/s/^/\#/' /usr/lib/python2.7/site-packages/imgcreate/creator.py

# Do not archive xz format
sed -i 's/rc = subprocess\.call(\[\"xz\"/rc = 0\#/' /usr/lib/python2.7/site-packages/appcreate/appliance.py
sed -i 's/\.xz//g' /usr/lib/python2.7/site-packages/appcreate/appliance.py
```

#### 4.2.2 Run appliance-creator
```
tar xf spin-kickstarts.tar.gz
cd spin-kickstarts
appliance-creator -c fedora-arm-artik.ks -d -v --logfile /tmp/appliance.log -o ../output --format raw --name fedora-arm-artik --version 22 --vmem=2048 -t /tmp --release fedora-arm-artik
```

To exit from qemu shell, use Ctrl+'a' and 'x' key

#### 4.2.3 Copy the 'fedora-arm-artik.raw.xz' file into Host PC
+ qemu-arm-system
```
sudo virt-copy-out -a Fedora-Minimal-armhfp-22-3-sda.raw /root/output/fedora-arm-artik/fedora-arm-artik-sda.raw .
```
+ arm board
```
scp root@{board_ip}:/root/output/fedora-arm-artik/fedora-arm-artik-sda.raw .
```

#### 4.2.4 Extract rootfs files and archive them
Extract rootfs files using guestfish
```
sudo guestfish << _EOF_
add fedora-arm-artik-sda.raw
run
mount /dev/sda1 /
tar-out / rootfs.tar
_EOF_
```
Compress the archive using gzip
```
gzip rootfs.tar
```

Now, you can use the 'rootfs.tar.gz' for build-artik.
