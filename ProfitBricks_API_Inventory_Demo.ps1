﻿########################################################################
# THIS SOFTWARE IS PROVIDED “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
########################################################################
# Consume ProfitBricks SOAP-Api using Powershell
# This is for demonstration purpose only
#
# This example does not include any error or exeption handling
########################################################################
# (c) ProfitBricks, 2013, Autor: Thomas Vogel
########################################################################

## Set the URI to the WSLD
$pb_wsdl = "https://api.profitbricks.com/1.2/wsdl"

## connect the WDSL
$pb_api = New-WebServiceProxy -Uri $pb_wsdl -namespace ProfitBricks -class pbApiClass

## interactive request user credidentials
# $pb_creds = Get-Credential -Message "ProfitBricks Account"
$_password = Get-Content "$env:HOMEPATH\PB_API.pwd" | ConvertTo-SecureString 
$_user = "thomas.vogel@profitbricks.com"
## Crate a credidentioal Object
$pb_creds = New-Object System.Management.Automation.PsCredential($_user,$_password)

## common - add credidentials for api access
$pb_api.Credentials = $pb_creds

## common - add credidentials for api access
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
# get datacenter inventory Option 1
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


#DCid	DCname ID	Type	Name	Status	Cores	Ram	Size	Connected LastModified
################
# get datacenter inventory Option 1
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
            $properties | Add-Member -Type NoteProperty -Name Size -Value ""
            $properties | Add-Member -Type NoteProperty -Name Connected -Value ""
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
            $properties | Add-Member -Type NoteProperty -Name Connected -Value $Storage.serverIds[0]
            $properties | Add-Member -Type NoteProperty -Name LastModified -Value $Storage.lastModificationTime
        $DC_Items += $properties
    }
}
$DC_Items | Export-Csv -Path "$env:HOMEPATH\DatacenterInventar\DatacenterInventory_Short.csv" -Delimiter ";" -NoTypeInformation
Write-Host "done ..."
