#!/bin/sh
# file /etc/domainManager/.domain_startup.sh
#

. /etc/domainManager/domain.conf

pids=$(ps | grep $shortName | awk '{print $1}')
pid=($pids)

if [ ! -n "${pid}" ]; then

	$dirName/$fileName $maxClientCnt $printOption $psk $tcpPort $tlsPort &

else

	echo "DomainManager Server is already running ... "

fi
