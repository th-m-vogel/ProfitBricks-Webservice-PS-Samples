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
$pb_wsdl = "https://api.profitbricks.com/1.2/wsdl"

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
# Export Datacenterlist to CSV
$DatacenterList | Export-Csv -Path "$env:HOMEPATH\DatacenterInventar\Datacenterlist.csv" -Delimiter ";" -NoTypeInformation

################
# get List of all Images availble inside yor account
################
Write-Host "Read ImageList from PB-API ..."
$ImageList = $pb_api.getAllImages()
# Export Imagelist to CSV
$ImageList | Export-Csv -Path "$env:HOMEPATH\DatacenterInventar\Imagelist.csv" -Delimiter ";" -NoTypeInformation


################
# get list of reserved IP Blocks
################
$IpBlockList = $pb_api.getAllPublicIpBlocks()
Write-Host "Read IpBlockList from PB-API ..."
$IpBlockList | Export-Csv -Path "$env:HOMEPATH\DatacenterInventar\IpBlockLis.csv" -Delimiter ";" -NoTypeInformation
################
# get Public IP Block details
################
foreach ($IpBlock in $IpBlockList){
    $_filename = "IpBlock." + $IpBlock.blockid + ".csv"
    $IpBlock.publicips | Export-Csv -Path "$env:HOMEPATH\DatacenterInventar\$_filename" -Delimiter ";" -NoTypeInformation
}


################
# get datacenter inventory - Option 1
################
Write-Host "Enumerate Datacenter Inventory for export as CSV and XML ..."
foreach ($Datacenter in $DatacenterList){
    $_Datacenter = $pb_api.getDataCenter($Datacenter.dataCenterId)
    Write-Host " ... working datacenter:" $_Datacenter.dataCenterName "using Datacenter ID:" $_Datacenter.dataCenterId
    # Export Servers
    $_filename = "Datacenter.Servers." + $_Datacenter.dataCenterID + ".csv"
    $_Datacenter.servers | Select-Object * -Exclude connectedStorages,ips,nics,romDrives | Export-Csv -Path "$env:HOMEPATH\DatacenterInventar\$_filename" -Delimiter ";" -NoTypeInformation
    # Export Storages
    $_filename = "Datacenter.Storages." + $_Datacenter.dataCenterID + ".csv"
    $_Datacenter.storages | Select-Object * -Exclude mountImage,serverIds | Export-Csv -Path "$env:HOMEPATH\DatacenterInventar\$_filename" -Delimiter ";" -NoTypeInformation
    # export Datacenter as XML
    $_filename = "Datacenter." + $_Datacenter.dataCenterID + ".xml"
    $_Datacenter | ConvertTo-Xml -As string -depth 5 -NoTypeInformation | Set-Content -path "$env:HOMEPATH\DatacenterInventar\$_filename"
}
Write-Host "done ..."

################
# Properties to request
# DCid	DCname ID	Type	Name	Status	Cores	Ram	Nic0_MAC Nic0_promary_IP Size	Connected_To Created LastModified
################
# get datacenter inventory - Option 2
################
Write-Host "Enumerate Datacenter Inventory for export as single, customized CSV ..."
$DC_Items = @()
foreach ($Datacenter in $DatacenterList){
    $_Datacenter = $pb_api.getDataCenter($Datacenter.dataCenterId)
    Write-Host " ... working datacenter:" $_Datacenter.dataCenterName "using Datacenter ID:" $_Datacenter.dataCenterId
    # Export Servers
    foreach ($Server in $_Datacenter.servers){
        $properties = $null
        $properties = New-Object System.Object
            $properties | Add-Member -Type NoteProperty -Name DCid -Value $_Datacenter.dataCenterId
            $properties | Add-Member -Type NoteProperty -Name DCname -Value $_Datacenter.dataCenterName
            $properties | Add-Member -Type NoteProperty -Name ID -Value $Server.ServerId
            $properties | Add-Member -Type NoteProperty -Name Type -Value "Server"
            $properties | Add-Member -Type NoteProperty -Name Name -Value $Server.ServerName
            $properties | Add-Member -Type NoteProperty -Name Status -Value $Server.virtualMachineState
            $properties | Add-Member -Type NoteProperty -Name Cores -Value $Server.cores
            $properties | Add-Member -Type NoteProperty -Name Ram -Value $Server.ram
            $properties | Add-Member -Type NoteProperty -Name Nic0_MAC -Value $Server.Nics[0].macAddress
            if ( $Server.Nics[0].ips.Count -gt 0 ) {
                $properties | Add-Member -Type NoteProperty -Name Nic0_primary_IP -Value $Server.Nics[0].ips[0]
            } else {
                $properties | Add-Member -Type NoteProperty -Name Nic0_primary_IP -Value ""
            }    
            $properties | Add-Member -Type NoteProperty -Name Size -Value ""
            $properties | Add-Member -Type NoteProperty -Name Connected_To -Value ""
            $properties | Add-Member -Type NoteProperty -Name Created -Value $Server.creationTime
            $properties | Add-Member -Type NoteProperty -Name LastModified -Value $Server.lastModificationTime
        $DC_Items += $properties
    }
    foreach ($Storage in $_Datacenter.storages){
        $properties = $null
        $properties = New-Object System.Object
            $properties | Add-Member -Type NoteProperty -Name DCid -Value $_Datacenter.dataCenterId
            $properties | Add-Member -Type NoteProperty -Name DCname -Value $_Datacenter.dataCenterName
            $properties | Add-Member -Type NoteProperty -Name ID -Value $Storage.StorageId
            $properties | Add-Member -Type NoteProperty -Name Type -Value "Storage"
            $properties | Add-Member -Type NoteProperty -Name Name -Value $Storage.StorageName
            $properties | Add-Member -Type NoteProperty -Name Status -Value $Storage.provisioningState
            $properties | Add-Member -Type NoteProperty -Name Size -Value $Storage.size
            $properties | Add-Member -Type NoteProperty -Name Connected_To -Value $Storage.serverIds[0]
            $properties | Add-Member -Type NoteProperty -Name Created -Value $Storage.creationTime
            $properties | Add-Member -Type NoteProperty -Name LastModified -Value $Storage.lastModificationTime
        $DC_Items += $properties
    }
}
$DC_Items | Export-Csv -Path "$env:HOMEPATH\DatacenterInventar\DatacenterInventory_Short.csv" -Delimiter ";" -NoTypeInformation
Write-Host "done ..."
