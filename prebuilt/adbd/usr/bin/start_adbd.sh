#!/bin/sh

echo adb > /sys/class/android_usb/android0/functions
echo 1 > /sys/class/android_usb/android0/enable

/usr/bin/adbd&
echo $! > /run/adbd.pid
