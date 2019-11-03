#!/usr/bin/env bash

# dependencies:
#	  bluez
#	  rfcomm
#	  stty

get_btclock_string_from_date() {
	if [ $# -lt 1 ]
	then
		local datestr="$( date -R )"
	else
		local datestr="$1"
	fi

	local year=$( date --date "$datestr" +%y )
	local month=$( date --date "$datestr" +%m )
	local day=$( date --date "$datestr" +%d )
	local hour=$( date --date "$datestr" +%H )
	local minute=$( date --date "$datestr" +%M )
	local second=$( date --date "$datestr" +%S )
	local dayofweek=0$(( $( date --date "$datestr" +%u ) - 1 ))

	echo T=$year$month$day$hour$minute$second$dayofweek
}

get_btclock_mac() {
	local devicename="$1"

	if [ $# -lt 1 ]
	then
		echo "usage: get_btclock_mac <bluetooth device name>" 1>&2
		return
	fi

	# try to determine mac from paired devices list first
	local mac=$( bluetoothctl paired-devices | grep "$devicename" | sed "s/Device \([^ ]*\) $devicename/\1/" )

	if [ "$mac" == "" ]
	then
		# try to discover btclock
		echo "bluetooth clock is not paired. Scanning for device \"$devicename\"..." 1>&2
		( echo scan on; sleep 30; scan off ) | bluetoothctl
		local mac=$( bluetoothctl devices | grep "$devicename" | sed "s/Device \([^ ]*\) $devicename/\1/" )
	fi

	echo $mac
}

is_btclock_paired() {
	local mac="$1"

	if [ $# -lt 1 ]
	then
		echo "usage: is_btclock_paired <mac>" 1>&2
		return
	fi

	bluetoothctl paired-devices | grep "$mac" > /dev/null
}

pair_with_btclock() {
	local mac="$1"

	if [ $# -lt 1 ]
	then
		echo "usage: pair_with_btclock <mac>" 1>&2
		return
	fi

	bluetoothctl pair $mac
}

BTCLOCK_NAME="BT Clock"

echo -n "determining MAC of device \"BT Clock\"... " 1>&2
mac=$( get_btclock_mac "${BTCLOCK_NAME}" )
echo "$mac" 1>&2

if [ "$mac" == "" ]
then
	echo "failed to discover device \"${BTCLOCK_NAME}\"" 1>&2
	exit 1
fi

if ! is_btclock_paired "$mac" && ! pair_with_btclock "$mac"
then
	echo "failed to pair with device \"${BTCLOCK_NAME}\" ($mac)" 1>&2
	exit 1
fi

# bind /dev/rfcomm0to bt device
rfcomm bind rfcomm0 "$mac"

# apply serial settings
stty -F /dev/rfcomm0 9600

# send T=... string for current system time to btclock
get_btclock_string_from_date > /dev/rfcomm0
# read and print output for at most 3 seconds
cat /dev/rfcomm0 & sleep 3; kill $!

# release /dev/rfcomm0
rfcomm release rfcomm0
