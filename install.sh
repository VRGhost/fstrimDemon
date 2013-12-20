#!/bin/bash

echo Installing fstrimDaemon...
read -p "What mode of installation do you prefer? [C]ron/S[tandalone]" -n 1 -r
echo

if [[ ${REPLY} =~ ^[Cc]$ ]]
then
    MODE="CRON"
elif [[ ${REPLY} =~ ^[Ss]$ ]]
then
    MODE="ALONE"
else
    echo "Unable to parse reply ${REPLY}"
    exit 1
fi

DIR=`dirname $0`

cp -fv usr/sbin/fstrimDaemon.sh /usr/sbin/fstrimDaemon.sh
RES=$?
if [ "$RES" != "0" ]; then
	echo Must be root to install fstrimDaemon
	exit $RES
fi
chmod 755 /usr/sbin/fstrimDaemon.sh

if [ ! -e /etc/fstrimDaemon ]; then
	cp -v etc/conf.d/fstrimDaemon /etc/fstrimDaemon
fi

if [[ "${MODE}" = "ALONE" ]]; then
    cp -fv etc/init.d/fstrimDaemon /etc/init.d/fstrimDaemon
    chmod 755 /etc/init.d/fstrimDaemon
elif [[ "${MODE}" = "CRON" ]]; then
    cp -fv etc/cron.daily/fstrimDaemon /etc/cron.daily/fstrimDaemon
    chmod 755 /etc/cron.daily/fstrimDaemon
fi

echo
echo Find more information in README.md
echo
