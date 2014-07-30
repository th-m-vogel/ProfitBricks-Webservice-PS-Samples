
########################################################################
# Copyright 2013 Thomas Vogel
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#########################################################################
# Code Repository: https://github.com/th-m-vogel/ProfitBricks-Webservice-PS-Samples
#########################################################################

## Set the URI to the WSLD
$pb_wsdl = "https://api.profitbricks.com/1.3/wsdl"

## connect the WDSL
$pb_api = New-WebServiceProxy -Uri $pb_wsdl -namespace ProfitbricksApiService -class ProfitbricksApiServiceClass

## use this line for interactive request of user credentials
$pb_creds = Get-Credential -Message "ProfitBricks Account"

## use the following thre code lines for
# file stored credentials. (password as encrypted String)
# to create stored credentials you may use
#   https://github.com/th-m-vogel/ProfitBricks-Webservice-PS-Samples/blob/master/Save-Password-as-encrypted-string.ps1
##
# $_password = Get-Content "$env:HOMEPATH\PB_API.pwd" | ConvertTo-SecureString 
# $_user = "username@domain.top"
# $pb_creds = New-Object System.Management.Automation.PsCredential($_user,$_password)
# end import password from file 
##

## add the credentials for api access (common)
$pb_api.Credentials = $pb_creds

################
# get List of all Datacenter availble inside yor account
################
Write-Host "Read DatacenterList from PB-API ..."
$DatacenterList = $pb_api.getAllDataCenters()
# Export Datacenterlist to CSV, XML and JSON
$DatacenterList | Export-Csv -Path "$env:HOMEPATH\DatacenterInventar\Datacenterlist.csv" -Delimiter ";" -NoTypeInformation
$DatacenterList | ConvertTo-Xml -As string -depth 5 -NoTypeInformation | Set-Content -path "$env:HOMEPATH\DatacenterInventar\Datacenterlist.xml"
$DatacenterList | ConvertTo-Json -depth 5| Set-Content -path "$env:HOMEPATH\DatacenterInventar\Datacenterlist.json"

################
# get List of all Images availble inside yor account
################
Write-Host "Read ImageList from PB-API ..."
$ImageList = $pb_api.getAllImages()
# Export Imagelist to CSV
$ImageList | Export-Csv -Path "$env:HOMEPATH\DatacenterInventar\Imagelist.csv" -Delimiter ";" -NoTypeInformation
$ImageList | ConvertTo-Xml -As string -depth 5 -NoTypeInformation | Set-Content -path "$env:HOMEPATH\DatacenterInventar\ImageList.xml"
$ImageList | ConvertTo-Json -depth 5| Set-Content -path "$env:HOMEPATH\DatacenterInventar\ImageList.json"

################
# get List of all Snapshots availble inside yor account
################
Write-Host "Read SnapshotList from PB-API ..."
$SnapshotList = $pb_api.getAllSnapshots()
# Export Imagelist to CSV
$SnapshotList | Export-Csv -Path "$env:HOMEPATH\DatacenterInventar\SnapshotList.csv" -Delimiter ";" -NoTypeInformation
$SnapshotList | ConvertTo-Xml -As string -depth 5 -NoTypeInformation | Set-Content -path "$env:HOMEPATH\DatacenterInventar\SnapshotList.xml"
$SnapshotList | ConvertTo-Json -depth 5| Set-Content -path "$env:HOMEPATH\DatacenterInventar\SnapshotList.json"

################
# get list of reserved IP Blocks
################
$IpBlockList = $pb_api.getAllPublicIpBlocks()
Write-Host "Read IpBlockList from PB-API ..."
$IpBlockList | Export-Csv -Path "$env:HOMEPATH\DatacenterInventar\IpBlockLis.csv" -Delimiter ";" -NoTypeInformation
$IpBlockList | ConvertTo-Xml -As string -depth 5 -NoTypeInformation | Set-Content -path "$env:HOMEPATH\DatacenterInventar\IpBlockList.xml"
$IpBlockList | ConvertTo-Json -depth 5| Set-Content -path "$env:HOMEPATH\DatacenterInventar\IpBlockList.json"

################
# get Public IP Block details
################
foreach ($IpBlock in $IpBlockList){
    $_filename = "IpBlock." + $IpBlock.blockid
    $IpBlock.publicips | Export-Csv -Path "$env:HOMEPATH\DatacenterInventar\$_filename.csv" -Delimiter ";" -NoTypeInformation
    $IpBlock | ConvertTo-Xml -As string -depth 5 -NoTypeInformation | Set-Content -path "$env:HOMEPATH\DatacenterInventar\$_filename.xml"
    $IpBlock | ConvertTo-Json -depth 5| Set-Content -path "$env:HOMEPATH\DatacenterInventar\$_filename.json"
}


################
# get datacenter inventory - Option 1
################
Write-Host "Enumerate Datacenter Inventory for export as CSV and XML ..."
foreach ($Datacenter in $DatacenterList){
    Write-Host " ... working datacenter:" $Datacenter.dataCenterName "using Datacenter ID:" $Datacenter.dataCenterId
    $_Datacenter = $pb_api.getDataCenter($Datacenter.dataCenterId)
    # Export Servers
    $_filename = "Datacenter.Servers." + $_Datacenter.dataCenterID
    $_Datacenter.servers | Select-Object * -Exclude connectedStorages,ips,nics,romDrives | Export-Csv -Path "$env:HOMEPATH\DatacenterInventar\$_filename.csv" -Delimiter ";" -NoTypeInformation
    $_Datacenter.servers | ConvertTo-Xml -As string -depth 5 -NoTypeInformation | Set-Content -path "$env:HOMEPATH\DatacenterInventar\$_filename.xml"
    $_Datacenter.servers | ConvertTo-Json -depth 5| Set-Content -path "$env:HOMEPATH\DatacenterInventar\$_filename.json"
    # Export Storages
    $_filename = "Datacenter.Storages." + $_Datacenter.dataCenterID
    $_Datacenter.storages | Select-Object * -Exclude mountImage,serverIds | Export-Csv -Path "$env:HOMEPATH\DatacenterInventar\$_filename.csv" -Delimiter ";" -NoTypeInformation
    $_Datacenter.storages | ConvertTo-Xml -As string -depth 5 -NoTypeInformation | Set-Content -path "$env:HOMEPATH\DatacenterInventar\$_filename.xml"
    $_Datacenter.storages | ConvertTo-Json -depth 5| Set-Content -path "$env:HOMEPATH\DatacenterInventar\$_filename.json"
    # export Datacenter
    $_filename = "Datacenter." + $_Datacenter.dataCenterID
    $_Datacenter | ConvertTo-Xml -As string -depth 5 -NoTypeInformation | Set-Content -path "$env:HOMEPATH\DatacenterInventar\$_filename.xml"
    $_Datacenter | ConvertTo-Json -depth 5| Set-Content -path "$env:HOMEPATH\DatacenterInventar\$_filename.json"
}
Write-Host "done ..."

################
# get datacenter inventory - Option 2
################
Write-Host "Enumerate Datacenter Inventory for export as single, customized CSV ..."
# The array DC_Items will hold the informations exported to CSV later on
$DC_Items = @()
foreach ($Datacenter in $DatacenterList){
    Write-Host " ... working datacenter:" $Datacenter.dataCenterName "using Datacenter ID:" $Datacenter.dataCenterId
    $_Datacenter = $pb_api.getDataCenter($Datacenter.dataCenterId)
    # Export Servers
    #
    # for each server only selected properties are assigned to the properties Object
    # each set of properties is added to the DC_Items aray
    foreach ($Server in $_Datacenter.servers){
        $properties = $null
        $properties = New-Object System.Object
            $properties | Add-Member -Type NoteProperty -Name DCid -Value $_Datacenter.dataCenterId
            $properties | Add-Member -Type NoteProperty -Name DCname -Value $_Datacenter.dataCenterName
            $properties | Add-Member -Type NoteProperty -Name Location -Value $_Datacenter.location
            $properties | Add-Member -Type NoteProperty -Name ID -Value $Server.ServerId
            $properties | Add-Member -Type NoteProperty -Name Type -Value "Server"
            $properties | Add-Member -Type NoteProperty -Name Name -Value $Server.ServerName
            $properties | Add-Member -Type NoteProperty -Name Status -Value $Server.virtualMachineState
            $properties | Add-Member -Type NoteProperty -Name Cores -Value $Server.cores
            $properties | Add-Member -Type NoteProperty -Name Ram -Value $Server.ram
            $properties | Add-Member -Type NoteProperty -Name Nic0_MAC -Value $Server.Nics[0].macAddress
            # if 1st NIC does have a assigned IP, note the 1st assigned IP
            if ( $Server.Nics[0].ips.Count -gt 0 ) {
                $properties | Add-Member -Type NoteProperty -Name Nic0_primary_IP -Value $Server.Nics[0].ips[0]
            } else {
                $properties | Add-Member -Type NoteProperty -Name Nic0_primary_IP -Value ""
            }
            # if DHCP is disabled for 1st NIC, note this to the Nic0_primary_IP property 
            if ( $Server.Nics[0].dhcpActive -eq $false ) {
                $properties | Add-Member -Type NoteProperty -Name Nic0_primary_IP -Value "dhcp_off" -Force
            }  
            $properties | Add-Member -Type NoteProperty -Name OS_type -Value $Server.osType
            $properties | Add-Member -Type NoteProperty -Name Size -Value ""
            $properties | Add-Member -Type NoteProperty -Name Connected_To -Value ($Server.connectedStorages.Count.ToString() + " Storages")
            $properties | Add-Member -Type NoteProperty -Name Created -Value $Server.creationTime
            $properties | Add-Member -Type NoteProperty -Name LastModified -Value $Server.lastModificationTime
        $DC_Items += $properties
    }
    # Export Storage
    #
    # same way as allready done for the servers
    foreach ($Storage in $_Datacenter.storages){
        $properties = $null
        $properties = New-Object System.Object
            $properties | Add-Member -Type NoteProperty -Name DCid -Value $_Datacenter.dataCenterId
            $properties | Add-Member -Type NoteProperty -Name DCname -Value $_Datacenter.dataCenterName
            $properties | Add-Member -Type NoteProperty -Name LOcation -Value $_Datacenter.location
            $properties | Add-Member -Type NoteProperty -Name ID -Value $Storage.StorageId
            $properties | Add-Member -Type NoteProperty -Name Type -Value "Storage"
            $properties | Add-Member -Type NoteProperty -Name Name -Value $Storage.StorageName
            $properties | Add-Member -Type NoteProperty -Name Status -Value $Storage.provisioningState
            $properties | Add-Member -Type NoteProperty -Name Size -Value $Storage.size
            $properties | Add-Member -Type NoteProperty -Name OS_type -Value $Storage.ostype
            if ( $Storage.serverIds.Count -gt 0 ) {
                $properties | Add-Member -Type NoteProperty -Name Connected_To -Value $Storage.serverIds[0]
            }
            $properties | Add-Member -Type NoteProperty -Name Created -Value $Storage.creationTime
            $properties | Add-Member -Type NoteProperty -Name LastModified -Value $Storage.lastModificationTime
        $DC_Items += $properties
    }
}
# Export the DC_Items Array to CSV File. 
# For systems running locale EN, please remove the -Delimiter option
# For Systems running different local than DE a different delimiter for CSV export may apply
$DC_Items | Export-Csv -Path "$env:HOMEPATH\DatacenterInventar\DatacenterInventory_Short.csv" -Delimiter ";" -NoTypeInformation
Write-Host "done ..."
