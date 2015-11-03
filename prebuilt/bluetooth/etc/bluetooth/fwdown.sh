#!/bin/sh

ARTIK5=`cat /proc/cpuinfo | grep -i EXYNOS3`

if [ "$ARTIK5" != "" ]; then
        TTY_NUM=0
	ARTIK_DEV=ARTIK5
else
        TTY_NUM=2
	ARTIK_DEV=ARTIK10
fi

if [ ! -f "/opt/.bd_addr" ]; then
	macaddr=$(dd if=/dev/urandom bs=1024 count=1 2>/dev/null|md5sum|sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\)\(..\).*$/\1:\2:\3:\4:\5:\6/')
        echo $macaddr > /opt/.bd_addr
        chmod 400 /opt/.bd_addr
cat > /etc/bluetooth/main.conf << EOF
[General]
Name = ${ARTIK_DEV}
EOF
fi

BD_ADDR=`cat /opt/.bd_addr`

pushd `dirname $0`

./brcm_patchram_plus --patchram ./BCM4354_003.001.012.0301.0000_Samsung_Artik_TEST_ONLY.hcd \
	--no2bytes --baudrate 3000000 \
	--use_baudrate_for_download /dev/ttySAC${TTY_NUM} \
	--bd_addr ${BD_ADDR} \
	--enable_hci &

echo $! > /run/brcm_patchram_plus.pid
