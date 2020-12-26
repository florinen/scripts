# Windoes PowerShell scripts that deletes VM's snapshots:

1. First you will have to run script "create_encrypted_pass.ps1" to generate the password in windows.
Clone the repo "git@github.com:florinen/scripts.git" in windows and then execute the script by right click on it or from powerShell change Dir to the location of the script and execute it:
```
    .\create_encrypted_pass.ps1
```
2. Open the Task Scheduler in windows and create a task for the script "delete_snapshots.ps1" to be executed at your desired interval using credentials created earlier.
In the same task scheduler create a second task to copy "remove-vms.csv" file from shared location to server in order to update the VM's name that snapshots will be deleted.
The windows script file to be executed for copy file is "copy_file.bat"
If you need to update the VM's that snapshots will be removed add/delete in "remove-vms.csv" file and is shared for easy access.
Just make sure the name of the VM in the csv file matches the name of the VM's snapshot.








