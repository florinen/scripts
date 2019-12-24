
#variables
$vCenter = @()
$sites = @("vcsa")
$domain = @("varu.local")
$user = @("florin@varu.local")
$password = Get-Content "C:\Users\Desktop\esxi\encrypted_pass\my_pass.txt" | ConvertTo-SecureString 
$credential = New-Object System.Management.Automation.PsCredential($user,$password)
#get array of sites and establishes connections to vcenters
foreach ($site in $sites) {
  	$vCenter = $site + "." + $domain

	#If you're not using a powershell credentials file to pass encrypted credentials to this script, uncomment -User <username> -Password <password>
	
  	Connect-VIServer -Server $vCenter -Credential $credential  #-User <username> -Password <password>

	$vmhosts=get-view -ViewType hostsystem -Property name,parent
	$hostshash=@{}
	$vmhosts|%{$hostshash.Add($_.moref.toString(),$_.name)}
	$clusters=get-view -viewtype ClusterComputeResource -Property name
	$clustershash=@{}
	$clusters|%{$clustershash.Add($_.moref.toString(),$_.name)}
	$hoststoclusterhash=@{}
	$vmhosts|%{$hoststoclusterhash.add($_.moref.toString(),$clustershash.($_.Parent.ToString()))}
	$vms=get-view -viewtype virtualmachine -property name, runtime.host, runtime.powerstate, guest.hostname, guest.net
    
    $report = $vms | ForEach-Object {
	 
	 [PSCustomObject]@{
	   
	   "Name" = $_.name
	   
	 }
	}
	#send output to csv and disconnect from vcenter 
	$report | Sort-Object Host | export-csv -path "C:\Users\Desktop\esxi\logs\remove-vms.csv" -NoTypeInformation -UseCulture
	
	Disconnect-VIServer -Confirm:$false -Server $vCenter
	
	<#
	Write event log on completetion per site.  
	note: if running for first time you will need to run powershell as administrator and run commands:
	'New-EventLog –LogName Application –Source Get-VMpowerstate_AndHostStatus'
	'Write-EventLog -LogName Application -Source Get-VMpowerstate_AndHostStatus -EventId 007 -EntryType Information -Message "Get-VMpowerstate_AndHostStatus for vCenter $site completed successfully."'
	#>
	
	Write-EventLog -LogName Application -Source Get-VMpowerstate_AndHostStatus -EventId 007 -EntryType Information -Message "Get-VMpowerstate_AndHostStatus for vCenter $site completed successfully."
}
