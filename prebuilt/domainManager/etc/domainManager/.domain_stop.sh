#!/bin/sh
# file /etc/domainManager/.domain_stop.sh
#

. /etc/domainManager/domain.conf

if [ $shortName != "q" ]; then

pids=$(ps | grep $shortName | awk '{print $1}')
pid=($pids)

while [ -n "${pid}" ]; do 

kill -9 ${pid[0]}

pids=$(ps | grep $shortName | awk '{print $1}')
pid=($pids)

done

else

echo 'bye!'

fi
