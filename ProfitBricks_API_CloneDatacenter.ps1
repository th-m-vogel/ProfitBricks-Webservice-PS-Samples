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
# PowerShell Module: https://github.com/th-m-vogel/ProfitBricks-PS-cmdlet
########################################################################

## Import the PBAPI PowerShell Module
import-module ProfitBricksSoapApi

## use this line for interactive request of user credentials
# $creds = Get-Credential -Message "ProfitBricks Account"


## use the following thre code lines for
# file stored credentials. (password as encrypted String)
# to create stored credentials you may use
#   https://github.com/th-m-vogel/ProfitBricks-Webservice-PS-Samples/blob/master/Save-Password-as-encrypted-string.ps1
##
# $_password = Get-Content "$env:HOMEPATH\PB_API.pwd" | ConvertTo-SecureString 
# $_user = "username@domain.top"
# $pb_creds = New-Object System.Management.Automation.PsCredential($_user,$_password)
# end import password from file 

$_password = Get-Content "$env:HOMEPATH\PB_API.pwd" | ConvertTo-SecureString 
$_user = "thomas.vogel@profitbricks.com"
## Crate a credidentioal Object
$creds = New-Object System.Management.Automation.PsCredential($_user,$_password)

## initialise the PB-API Service using the given Credentials
Open-PBApiService -Credentials $creds

################
# configuration section
################

$srcDCid = Get-PBDatacenterIdentifiers | Where-Object {$_.DatacenterName -eq "GehtdochOnPremise"}
$targetDCname = "MY New Cloned Datacenter"

################
# end configuration section
################

## gequest source DataCenter configuration
$srcDC = Get-PBDatacenter $srcDCid.dataCenterId

################
# create Snapshots from source datacenter
################
$SnapshotTable = @{}
foreach ($storage in $srcDC.storages) {
    Write-Host -NoNewline "Cloning" $storage.storageName 
    if ( $storage.serverIds ){
        Write-Host " mounted by Server" $storage.serverIds[0]
        if ((Get-PBServer -serverId $storage.serverIds[0]).virtualMachineState -eq "RUNNING") {
            Write-Host "## Warning: Server" $storage.serverIds "is running while Snapshot is created!"
        }
    } else {
        Write-Host " not mounted by any Server"
    }
    $Snapshot = New-PBSnapshot -storageId $storage.storageId -snapshotName $storage.storageId -description ("Auto created cloning snapshot from " + $storage.storageName + " at " + (Get-Date).ToString())
    $SnapshotTable += @{$storage.storageId = $Snapshot.snapshotId }
}

################
# wait for for snapshots to finish
################

Write-Host -NoNewline "Wait for Snapshots to be available, check every 60 seconds "
do {
    Sleep 60
    Write-Host -NoNewline "."
} while (Get-PBSnapshots | Where-Object {($_.provisioningState -ne "AVAILABLE") -and ($_.SnapshotId -in $SnapshotTable.Values )})
Write-Host " finished!"

################
# create the new Datacenter
################

Write-Host "Create the new Datacenter $targetDCname"
$newDC = New-PBDatacenter -dataCenterName $targetDCname -Region $srcDC.region

################
# create the Storages
################
$StorageTable = @{}
foreach ($Storage in $srcDC.storages) {
    Write-Host -NoNewline "Create new Storage" $storage.storageName "size" $storage.size "GB ..."
    $NewStorage = New-PBStorage -dataCenterId $newDC.dataCenterId -size $storage.size -storageName $storage.storageName 
    Write-Host "and apply snapshot from source storage" $storage.storageId
    $RestoreSnapshot = Restore-PBSnapshot -storageId $NewStorage.StorageId -snapshotId $SnapshotTable.Item($storage.storageId)
    $StorageTable += @{$storage.storageId = $NewStorage.storageId}
}

################
# Create the Servers
################
$internet = @{}
foreach ($server in $srcDC.servers) {
    Write-Host "Create Server" $server.serverName "using" $server.cores  "cores and" ($server.ram/1024) "GB RAM"
    $NewServer = New-PBServer -dataCenterId $newDC.dataCenterId -serverName $server.serverName -cores $server.cores -ram $server.ram -availabilityZone $server.availabilityZone -osType $server.osType
    Write-Host "    Add nics to the server"
    foreach ($nic in $server.nics) {
        $newNic = New-PBNic -serverId $NewServer.serverId -nicName $nic.nicName -dhcpActive $nic.dhcpActive -lanId $nic.lanId
        if ($nic.internetAccess -and !$internet.item($nic.lanid)) {
            $setInternet = Set-PBInternetAccess -datacenterId $newDC.dataCenterId -lanId $nic.lanId -internetAccess $true
            $internet += @{$nic.lanid = $true}
        }
    }
    Write-Host "    Connect storages to the server"
    foreach ($storage in $server.connectedStorages) {
        $storageconnect = Connect-PBStorageToServer -serverId $NewServer.serverId -storageId $StorageTable.item($storage.storageId) -busType $storage.busType
    }
}

################
# Thats all, wait für provisioning finished
################
Write-Host -NoNewline "Wait for Datacenter to be available, check every 60 seconds "
do {
    Sleep 60
    Write-Host -NoNewline "."
} while ( (Get-PBDatacenterState $newDC.dataCenterId) -ne "AVAILABLE" )

Write-Host " Done !!!"

################
# Cleanup Snapshots
################
Write-Host "Cleaning up Snapshots"
$null = Get-PBSnapshots | Remove-PBSnapshot 