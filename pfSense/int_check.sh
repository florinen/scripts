#!/bin/sh

#=====================================================================
# pingtest.sh, v1.0.1
# Created 2009 by Bennett Lee
# Released to public domain
# https://forum.netgate.com/topic/16217/howto-ping-hosts-and-reset-reboot-on-failure/2
# (1) Attempts to ping several hosts to test connectivity.  After
#     first successful ping, script exits.
# (2) If all pings fail, resets interface and retries all pings.
# (3) If all pings fail again after reset, then reboots pfSense.
#
# History
# 1.0.1   Added delay to ensure interface resets (thx ktims).
# 1.0.0   Initial release.
#=====================================================================

#=====================================================================
# USER SETTINGS
#
# Set multiple ping targets separated by space.  Include numeric IPs
# (e.g., remote office, ISP gateway, etc.) for DNS issues which
# reboot will not correct.
ALLDEST="google.com yahoo.com 24.93.40.36 8.8.8.8"
# Interface to reset, usually your WAN
BOUNCE=vmx0

# Log file
LOGFILE=/root/pingtest.log
#=====================================================================

COUNT=3
while [ $COUNT -le 4 ]
do

	for DEST in $ALLDEST
	do
		echo `date +%Y%m%d.%H%M%S` "Pinging $DEST" >> $LOGFILE
        # editet in line 40 "ping -c1 $DEST >/dev/null 2>/dev/null" to "ping -I OPT1 -c1 $DEST >/dev/null 2>/dev/null"
		ping -c1 $DEST >/dev/null 2>/dev/null
		if [ $? -eq 0 ]
		then
			echo `date +%Y%m%d.%H%M%S` "Ping $DEST OK." >> $LOGFILE
			exit 0
		fi
	done

	if [ $COUNT -le 3 ]
	then
		echo `date +%Y%m%d.%H%M%S` "All pings failed. Resetting interface $BOUNCE." >> $LOGFILE
		/sbin/ifconfig $BOUNCE down
		# Give interface time to reset before bringing back up
		sleep 10
		/sbin/ifconfig $BOUNCE up
		# Give WAN time to establish connection
		sleep 60
	else
		echo `date +%Y%m%d.%H%M%S` "All pings failed twice. Rebooting..." >> $LOGFILE
		/sbin/shutdown -r now >> $LOGFILE
		exit 1
	fi
    #((count++))
	COUNT=`expr $COUNT + 1`
done
