# Update Nextcloud 
## Use this script to update Nextcloud version. If anything goes wrong it will rollback to previous version.

## This script only works if you upgrade minor versions, on major versions DB usualy gets updated to and because of that this script will fail.
## Example of minor version this script can be used with: 19.0.6 >> 19.0.7
## Example o majos version 19.0.8 >> 20.0.6. In this case use browser to do the upgrade after that, update your DB table and then you can use this script. 

1. Clone the repo scripts:
```
git clone https://github.com/florinen/scripts.git
```
2. Before running "upgrade_nc.sh" make sure you are backing up first by running "backup_cloud.sh"
```
./scripts/nc_backup/backup_cloud.sh
```
3. Change the version of nextcloud to the one you want to upgrade (Do Not Downgrade From Already Existing Version, Only UPGRADE). Change PHP version to match the one that is already running. 
```
vim scripts/nc_backup/upgrade_nc.sh 
Ex: 
NC_TARGET_VER="18.07"
PHP_VER="7.3"
```
4. Run the script. 
```
./scripts/nc_backup/upgrade_nc.sh
```

## Notes:
If the script fails will automaticaly rollback. In the case that is not happening troubleshoot and if you want to manualy trigger rollback, change the variable value of 'NC_TARGET_VER' to anything, comment out all the lines in between "STARTING the UPGRADE" and  "Rolling back if upgrade fails" and run the script again.
This should revert back to previous version of Nextcloud. 

## Executing one script to backup and upgrade NC. After cloning repo:
```
bash $HOME/scripts/nc_backup/cloud_upgrade.sh
```
