#variables
$vCenter = @()
$sites = @("vcsa")
$domain = @("varu.local")
$user = @("florin@varu.local")
$password = Get-Content "C:\Users\florin\cred\my_pass.txt" | ConvertTo-SecureString 
$credential = New-Object System.Management.Automation.PsCredential($user, $password)
$oldDate = { $_.Created -le (Get-Date).AddDays(-$days) }
#$old_snapshots = { ([DateTime]::Now - $_.Created).TotalDays -lt $days }
$days = "30"
$logfile = "\\freenas.varu.local\NFS\Win16-SRV\vSphere\logs\log.txt"
$timestamp = Get-Date
$date = get-date -f MMddyyyy
$csvfile = Import-csv -path "C:\Users\florin\Documents\vSphere\remove-vms.csv"
$vms = $csvfile
$logpath = "\\freenas.varu.local\NFS\Win16-SRV\vSphere\logs"
 
# Verify the log folder exists.
If (!(Test-Path $logpath)) {
    Write-Host "Log path not found, creating folder."
    New-Item $logpath -Type Directory
}
 
#get array of sites and establishes connections to vcenters
foreach ($site in $sites) {
    $vCenter = $site + "." + $domain
    $message = "$timestamp Connecting to $vcenter"
    Write-Host $message
    Add-Content $logfile  $message
    
    #If you're not using a powershell credentials file to pass encrypted credentials to this script, uncomment -User <username> -Password <password>
	Connect-VIServer -Server $vCenter -Credential $credential  #-User <username> -Password <password>
    Write-Host `n
}
# Example:

 #Get-VM $vms.name | Get-Snapshot | Where-Object {$_.Created -le (Get-Date).AddDays(-0) }  | Select-Object VM, Name, Created | sort-object VM, Created

foreach ($vm in get-vm $vms.name) {
    
    #Write-Host "Current Snapshots for VM $vm"
    $snaps = get-snapshot -vm $vm | Where-Object $oldDate | Select-Object VM, Name, Created | sort-object  Created 
    $snapshotcount = $snaps | Measure-Object 
    $snapshotcounts = $snapshotcount.Count 
    $timestamp = Get-Date
    $message = "$timestamp Removing $snapshotcounts Snapshot(s) for VM $vm"
    Write-Host $message
    $snapslist = get-snapshot -vm $vm | Select-Object VM, Name, Created, @{Name = "Age"; Expression = { ((Get-Date) - $_.Created).Days } } 
    $totalsnaps = get-snapshot -vm $vm | Measure-Object
    $vmsnap = $totalsnaps.Count
    #Write-Output $snapslist
    Write-Output "$vmsnap snapshots before cleanup for VM $vm" | Out-File $logpath\Snapshots_$date.txt -Append
    Write-Output $snapslist | Out-File $logpath\Snapshots_$date.txt -Append
    Add-Content $logfile  $message
    ## Deltete the snapshots
    Get-Snapshot  $snaps.VM | Remove-Snapshot -Confirm:$false | Out-File $logfile -Append
    $timestamp = Get-Date
    $message = "$timestamp Removed $snapshotcounts Snapshot(s) for VM $vm"
    Write-Output $logfile  $message
    # check snaps after cleanup
    $snapslist = get-snapshot -vm $vm | Select-Object VM, Name, Created, @{Name = "Age"; Expression = { ((Get-Date) - $_.Created).Days } } 
    $totalsnaps = get-snapshot -vm $vm | Measure-Object
    $vmsnap = $totalsnaps.Count
    Write-Output "$vmsnap snapshots after cleanup for VM $vm" | Out-File $logpath\Snapshots_$date.txt -Append
    Write-Output $snapslist | Out-File $logpath\Snapshots_$date.txt -Append
}
Disconnect-VIServer -Confirm:$false -Server $vCenter
# Cleanup Snapshot logs older than 30 days.
Get-ChildItem -path $logpath -Recurse -Force | Where-Object {!$_.PSIsContainer -and $_.LastWriteTime -lt (Get-Date).AddDays(-$days)} | Remove-Item -Force



 

