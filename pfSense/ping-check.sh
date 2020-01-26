#!/bin/sh

# HOSTS can be either you ISP or google.com
HOSTS="google.com"
COUNT=2

echo "Pinging.."
echo "HOSTS: " $HOSTS
echo "COUNT: " $COUNT
######
for myHost in $HOSTS
do
  counting=$(ping -c $COUNT $myHost | grep 'received' | awk -F',' '{ print $2 }' | awk '{ print $1 }' )
  echo "counting: " $counting

  if [ $counting -eq 2 ]; then
   echo "Ping OK"

  else
   # network down
   # Save RRD data
   /etc/rc.backup_rrd.sh
   #Reboot
   echo "Reboot!"
   reboot
fi
done
exit 0
