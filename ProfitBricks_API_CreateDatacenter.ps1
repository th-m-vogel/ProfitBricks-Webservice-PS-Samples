﻿########################################################################
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
########################################################################
# Code Repository: https://github.com/th-m-vogel/ProfitBricks-Webservice-PS-Samples
########################################################################

## Set the URI to the PB-API WSLD
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

## add the credentials for api access (common)
$pb_api.Credentials = $pb_creds

################
# initialisation done. $pb_api is a instance crated regarding WSDL
# try $pb_api | gm ...
################

## create a function to wait for a ready to use datacenter
##
function CheckProvisioningState { 
    param ($_DataCenterID)
    write-host -NoNewline "Wait for Datacenter to change status to available, check every 10 seconds  ..."
    do {
        write-host -NoNewline "." 
        start-sleep -s 10
        $_DC = $pb_api.getDataCenter($_DataCenterID)
    } while ($_DC.provisioningStateSpecified -and ($_DC.provisioningState -ne "AVAILABLE"))
    Write-Host " done ..."
}

################
# now we are ready to consume the PB-API
################

## Specify Region to use
$my_region = "EUROPE"

## get list of all available Images
$pb_images = $pb_api.getAllImages()
## Pick the Windows Server 2012 imag
$image = $pb_images | Where-Object {($_.ImageName -like "windows-2012-server-*") -and ($_.region -eq $my_region)}
write-host "Will use the followinmg Image to create a new Server:" $image.imageName

################
# Create a new Datacenter
################

## create a new and empty Datacenter
Write-host "Create the new Datacenter ..."
$DatacenterResponse = $pb_api.createDataCenter("My New API created Datacenter",$my_region,$true)

## create a StorageRequest
$StorageRequest = New-Object ProfitbricksApiService.createStorageRequest
$StorageRequest.dataCenterId = $DatacenterResponse.dataCenterId
$StorageRequest.storageName = "WindowsServer Drive C"
$StorageRequest.size = 40
$StorageRequest.mountImageId = $image.imageId
$StorageRequest.profitBricksImagePassword = "asdfghjk"
## invoke the createStorage methode
Write-Host "Create the Storage Device ..."
$StorageResponse = $pb_api.createStorage($StorageRequest)

## create a ServerRequest
$ServerRequest = New-Object ProfitbricksApiService.createServerRequest
$ServerRequest.dataCenterId = $DatacenterResponse.dataCenterId
$ServerRequest.cores = 2
$ServerRequest.ram = 4096
$ServerRequest.serverName = "Windows2012 Server"
## invoke the createServer methode
Write-host "Create the new Server using the newly created Storage as boot device ..."
$ServerResponse = $pb_api.createServer($ServerRequest)

## Connect Storage to Server
$ConnectRequest = New-Object ProfitbricksApiService.connectStorageRequest
$ConnectRequest.serverId = $ServerResponse.serverId
$ConnectRequest.storageId = $StorageResponse.storageId
## invoke the connectStorageToServer methode
$ConnectResponse = $pb_api.connectStorageToServer($ConnectRequest)

## Create NIC
$NicRequest = New-Object ProfitbricksApiService.createNicRequest
$NicRequest.serverId = $ServerResponse.serverId
$NicRequest.lanId = 1
$NicRequest.nicName = "Nic01"
## invoke the createNic methode
$NicResponse = $pb_api.createNic($NicRequest)

## Connect the Lan to the Internet
$InternetResponse = $pb_api.SetInternetAccess($DatacenterResponse.dataCenterId,1,$true,$true)


## and  check provisioning state until Datacenter is provisioned
CheckProvisioningState($DatacenterResponse.dataCenterId)

## Set the Name for the newly create network card (cosmetics ...)
Write-host "Primary IP is: "$pb_api.getServer($ServerResponse.ServerID).nics[0].Ips[0]

## Datacenter is ready
Write-Host "Your new Datacenter is ready for Use."
Write-Host "It may take additional time for your server to boot for the 1st time!"

## Export Datacenter as XML
$Datacenter_AsXML = $pb_api.getDataCenter($DatacenterResponse.dataCenterId) | ConvertTo-Xml -As string -depth 10
Write-Host $Datacenter_AsXML
#
# Test only, clear Datacenter 
# $pb_api.clearDataCenter($DatacenterResponse.dataCenterId)