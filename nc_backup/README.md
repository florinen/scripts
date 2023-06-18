# Update Nextcloud 
## Use this script to update Nextcloud version. If anything goes wrong it will rollback to previous version.



1. Clone the repo scripts:
```
git clone https://github.com/florinen/scripts.git
```
2. Run the script and follow the prompt selecting nextcloud version. 
```
bash $(find $HOME -name cloud_upgrade.sh)
```

## Notes:
If the script fails will automaticaly rollback. In the case that is not happening troubleshoot and if you want to manualy trigger rollback, change the variable value of 'NC_TARGET_VER' to anything, comment out all the lines in between "STARTING the UPGRADE" and  "Rolling back if upgrade fails" and run the script again.
This should revert back to previous version of Nextcloud. 