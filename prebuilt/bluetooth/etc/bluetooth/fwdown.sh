#!/bin/sh

function gen_bd_addr {
        [ -d /opt/.bd_addr ] || rm -f /opt/.bd_addr
        [ -d /etc/bluetooth/main.conf ] || rm -f /etc/bluetooth/main.conf

        macaddr=$(dd if=/dev/urandom bs=1024 count=1 2>/dev/null|md5sum|sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/00:\1:\2:\3:\4:\5/')
        echo $macaddr > /opt/.bd_addr
        chmod 400 /opt/.bd_addr
cat > /etc/bluetooth/main.conf << EOF
[General]
Name = $1
EOF
        sync
}

ARTIK5=`cat /proc/cpuinfo | grep -i EXYNOS3`

if [ "$ARTIK5" != "" ]; then
        TTY_NUM=0
	ARTIK_DEV=ARTIK5
else
        TTY_NUM=2
	ARTIK_DEV=ARTIK10
fi

if [ ! -f "/opt/.bd_addr" ]; then
        gen_bd_addr ${ARTIK_DEV}
fi

BD_ADDR=`cat /opt/.bd_addr`
if [ "$BD_ADDR" == "" ]; then
        gen_bd_addr ${ARTIK_DEV}
        BD_ADDR=`cat /opt/.bd_addr`
fi

pushd `dirname $0`

./brcm_patchram_plus --patchram ./BCM4354_003.001.012.0301.0000_Samsung_Artik_TEST_ONLY.hcd \
	--no2bytes --baudrate 3000000 \
	--use_baudrate_for_download /dev/ttySAC${TTY_NUM} \
	--bd_addr ${BD_ADDR} \
	--enable_hci &

echo $! > /run/brcm_patchram_plus.pid
