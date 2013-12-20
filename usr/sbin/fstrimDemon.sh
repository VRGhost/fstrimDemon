#!/bin/bash

if [ "${MODE}" = "DEBUG" ]; then
	source "${ETC_PATH}/conf.d/fstrimDemon"
else
	# Deployment mode
	source /etc/conf.d/fstrimDemon
fi


SLEEP_CMD="sleep"
# SLEEP_CMD="echo debug: SLEEP"

# We divide sleep for smaller portions in order to protect
# against being awaken when computer resume from suspension
function vigilantSleep()
{
	local VAL=${1%?}

	if   [[ "$1" == *s ]] ; then
		local MULTIPLEXER=1
	elif   [[ "$1" == *m ]] ; then
		local MULTIPLEXER=60
	elif [[ "$1" == *h ]] ; then
		local MULTIPLEXER=60*60
	elif [[ "$1" == *d ]] ; then
		local MULTIPLEXER=24*60*60
	else
		local MULTIPLEXER=1
		local VAL=${1}
	fi

	let "HOURS= ${VAL} * ${MULTIPLEXER} / ${SLEEP_CHUNK}"
	let " REST= ${VAL} * ${MULTIPLEXER} % ${SLEEP_CHUNK}"

	for i in $(seq 1 ${HOURS}) ; do
		${SLEEP_CMD} ${SLEEP_CHUNK}
	done

	${SLEEP_CMD} ${REST}
}


U_MAX_CPU_LOAD=$(echo "$(nproc) * ${MAX_CPU_LOAD}" | bc -l)

function waitForLowCpuLoad()
{
	local CPU_LOAD=$(cut -f 1 -d" " /proc/loadavg)
	while [ $(echo "${CPU_LOAD} > ${U_MAX_CPU_LOAD}" | bc -l) -eq 1 ] ; do
		local CPU_LOAD=$(cut -f 1 -d" " /proc/loadavg)
		vigilantSleep 5m
	done
}

function listSSDs()
{
	
	# Return array of all hardware devices that supports TRIM
	for name in /dev/sd[a-z]
	do
		if [[ -n $(hdparm -I "${name}" 2>&1 | grep 'TRIM supported') ]]; then 
			echo ${name}
		fi
	done
	return ${RV}
}

function listTrimmableMounts()
{
	for hdd in $(listSSDs)
	do
		mount -l | grep -E "^${hdd}[0-9]*[[:space:]]" | sed -E 's/^.*on (.*) type.*$/\1/g'
	done
}

function doTRIM()
{
	waitForLowCpuLoad
	for mount in $(listTrimmableMounts)
	do
		fstrim -v "${mount}"
	done
}

##############################

if [ "$1" == "one_shot" ]; then
	doTRIM
	exit 0
fi

echo `date`: FSTRIM DEMON STARTED
echo ----------------------------
vigilantSleep ${SLEEP_AT_START}

while true ; do
	echo `date`: RUN FSTRIM FOR ${TRIM_DIR}
	doTRIM
	echo ----------------------------
	vigilantSleep ${SLEEP_BEFORE_REPEAT}
done
