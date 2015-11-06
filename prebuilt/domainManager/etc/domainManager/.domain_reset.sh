#!/bin/sh
# file /etc/domainManager/.domain_reset.sh
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

file1="$dirName/.D_c_list"
file2="$dirName/.D_l_list"
file3="$dirName/.D_s_list"
file4="$dirName/.D_key"

if [ -f $file1 ]; then
rm -f $file1
fi

if [ -f $file2 ]; then
rm -f $file2
fi

if [ -f $file3 ]; then
rm -f $file3
fi

if [ -f $file4 ]; then
rm -f $file4
fi

else

echo 'bye!'

fi
