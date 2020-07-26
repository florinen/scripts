## pfSense

1. Login to pfsense with ssh, select "8" for shell command
2. Go to: /usr/local/bin
3. create file, vi ping-check.sh and paste the content of 'ping-check.sh" then save and qiut
4. chmod 700 ping-check.sh
5. exit
6. You can go into pfSense web interface and install 'Cron' package, then add the cronJob there. I istalled from CLI with 'crontab -e'
7. crontab -e and paste:
```
SHELL=/bin/sh
PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin
# Order of crontab fields
# minute        hour    mday    month   wday    command

*/5 * * * *  /usr/local/bin/ping-check.sh
```
## Test it out.
Unplug WAN cable from modem. pfSense router should reboot after 5 minutes because ping fails