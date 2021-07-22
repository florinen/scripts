#!/bin/sh
EMAIL_ADDRESS="nenfl@yahoo.com"
filename="bigfiles"
find / -maxdepth 6 -type f -size +500M > $filename
count=`cat bigfiles | wc -l`
echo $count
# if [ $? -ne 0 ]
# then
#   date >> $filename
#   mail -s "Large log files found on server" EMAIL_ADDRESS < $filename
# fi