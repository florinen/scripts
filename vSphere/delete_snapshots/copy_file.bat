
:: Reference link: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/robocopy
 
:: robocopy \\\freenas.varu.local\NFS\Win16-SRV\vSphere\scripts\ *.csv C:\Users\florin\Documents\vSphere /copyall /PURGE /r:5 /w:5 /v

:: This line will copy any csv file from shared a location to a destination:

robocopy \\freenas.varu.local\NFS\Win16-SRV\vSphere\scripts\ *.csv C:\Users\florin\Documents\vSphere  /PURGE /r:5 /w:5 /v /xo

