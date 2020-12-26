Function Get-VMKLinuxDrivers {
    param (
        # Parameter help description
        [Parameter(Mandatory=$true)]
        [string]$Cluster
    )
    $vmhosts = Get-VMHost | where {$_.ConnectionState -eq "Connected"}
    $results = @()
    foreach ($vmhost in $vmhosts) {
        Write-Host "Checking $($vmhost.name) ..."
        $esxcli = Get-EsxCli -VMHost $vmhost -V2
        $modules = $esxcli.system.module.list.invoke() | where {$_.IsLoaded -eq $true}
        $VMKLinuxDrivers = @()
        foreach ($module in $modules) {
            $moduleName = $esxcli.system.module.get.CreateArgs()
            $moduleName.module = $module.name
            $vmkernelModule = $esxcli.system.module.get.Invoke($moduleName) 

            if($vmkernelModule.RequiredNamespaces -match "com.vmware.driverAPI") {

            }
        }
        if($VMKLinuxDrivers -ne $null) {
            $tmp = [PSCustomObject]@{
                VMHost = $vmhost.name;
                VMKLinuxDriver = ($VMKLinuxDrivers -join ",")
            }
            $results += $tmp
        }
    }
    $results | Sort-Object -Property VMHost | FT
}


