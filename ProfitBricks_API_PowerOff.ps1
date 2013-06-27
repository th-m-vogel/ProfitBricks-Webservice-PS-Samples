########################################################################
# Consume ProfitBricks SOAP-Api using Powershell
# some simple steps to get you DCD Inventory
######
# Thomad Vogel, ProfitBricks, (c) 2013
########################################################################

## Set the URI to the WSLD
$pb_wsdl = "https://api.profitbricks.com/1.2/wsdl"

## connect the WDSL
$pb_api = New-WebServiceProxy -Uri $pb_wsdl -namespace ProfitBricks -class pbApiClass

## use file stored credentials - use in script
# restore data
$_password = Get-Content "$env:HOMEPATH\PB_API.pwd" | ConvertTo-SecureString 
$_user = "thomas.vogel@profitbricks.com"
$pb_creds = New-Object System.Management.Automation.PsCredential($_user,$_password)
$pb_api.Credentials = $pb_creds

## get Datacenter to handle
$DC = $pb_api.getAllDataCenters() | Where-Object {$_.dataCenterName -eq "Powertest"} 

foreach ($Server in $pb_api.getDataCenter($DC.dataCenterId).servers | Sort-Object -Property ServerName ) {
    if ($pb_api.getServer($server.serverId).virtualMachineState -eq "RUNNING") {
        Write-Host "Working on Server " $Server.serverName
        $Response = $pb_api.shutdownServer($Server.serverId)
    }
} 



