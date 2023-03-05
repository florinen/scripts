# Write Progress variables
$Activity = "Backing up the ESXi Host firmware to your destination"
$ID = 1
$Task = "Please wait, backing up..."

$vCenter = @()
$sites = @("vcsa")
$domain = @("varu.local")
$user = @("florin@varu.local")
$password = Get-Content "C:\Users\fnenciu\cred\my_pass.txt" | ConvertTo-SecureString 
$credential = New-Object System.Management.Automation.PsCredential($user, $password)
$clusterName = "MyCL"
# $oldDate = { $_.Created -le (Get-Date).AddDays(-$days) }
# $days = "15"
#$logfile = "\\freenas.varu.local\NFS\Win16-SRV\vSphere\logs\log.txt"
# $timestamp = Get-Date
# $date = get-date -f MMddyyyy
$destinationpath = "\\freenas.varu.local\NFS\ESXi-configBackups"


# Load the PowerCLI SnapIn
Add-PSSnapin VMware.VimAutomation.Core -ea "SilentlyContinue"
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

# Collect Username and Password as Credential
# $Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $vCenterUser,$vCenterUserPassword

# Write the Progress in the PowerShell console
Write-Progress -ID $ID -Activity $Activity -Status $Task
# Connect to the vCenter Server with collected credentials
foreach ($site in $sites) {
    $vCenter = $site + "." + $domain
    # $message = "$timestamp Connecting to $vcenter"
    # Write-Host $message
    # Add-Content $logfile  $message
    
    #If you're not using a powershell credentials file to pass encrypted credentials to this script, uncomment -User <username> -Password <password>
	Connect-VIServer -Server $vCenter -Credential $credential  #-User <username> -Password <password>
    Write-Host "Connected to your vCenter server $vCenter" -ForegroundColor Green
    
    #Write-Host `n
}


# Backing up the ESXi host firmware to the desired path

$vmHosts = Get-Cluster -Name $clusterName | Get-VMHost

foreach ($vmhost in $vmHosts)

{

    $vmhost | Get-VMHostService | Where-Object { $_.Key -eq "TSM-SSH" } | Start-VMHostService

}
Write-Host "Successfully enabled SSH for the hosts $vmHosts " -ForegroundColor Green

foreach ($vmhost in Get-VMHost) 
{
     Get-VMHostFirmware -VMHost $vmhost -BackupConfiguration -DestinationPath $destinationpath 
}

#Get-VMHost | Get-VMHostFirmware -BackupConfiguration -DestinationPath $destinationpath

foreach ($vmhost in $vmHosts)

{

    $vmhost | Get-VMHostService | Where-Object { $_.Key -eq "TSM-SSH" } | Stop-VMHostService -confirm:$false

}
Write-Host "Successfully disabled SSH for the hosts $vmHosts " -ForegroundColor Green

Write-Host "Successfully backed up the configuration of the host of $vCenter to $destinationpath" -ForegroundColor Green

# Disconnecting from the vCenter Server
Disconnect-VIServer -Confirm:$false
Write-Host "Disconnected from your vCenter Server $vCenter - have a great day :)" -ForegroundColor Green
