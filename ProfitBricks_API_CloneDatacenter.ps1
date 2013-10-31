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
########################################################################
# Code Repository: https://github.com/th-m-vogel/ProfitBricks-Webservice-PS-Samples
########################################################################
# PowerShell Module: https://github.com/th-m-vogel/ProfitBricks-PS-cmdlet
########################################################################

## Import the PBAPI PowerShell Module
import-module ProfitBricksSoapApi

## use this line for interactive request of user credentials
$creds = Get-Credential -Message "ProfitBricks Account"

## use the following thre code lines for
# file stored credentials. (password as encrypted String)
# to create stored credentials you may use
#   https://github.com/th-m-vogel/ProfitBricks-Webservice-PS-Samples/blob/master/Save-Password-as-encrypted-string.ps1
##
# $_password = Get-Content "$env:HOMEPATH\PB_API.pwd" | ConvertTo-SecureString 
# $_user = "username@domain.top"
# $creds = New-Object System.Management.Automation.PsCredential($_user,$_password)
# end import password from file 

## initialise the PB-API Service using the given Credentials
Open-PBApiService -Credentials $creds

################
# configuration section
################

$srcDCid = Get-PBDatacenterIdentifiers | Where-Object {$_.DatacenterName -eq "Master"}
$targetDCname = "My New Master Copy"
$UseExistingSnapshots = $true
$CleanupSnapshots = $false

################
# end configuration section
################

################
## create a function to wait for a ready to use datacenter
################
function CheckProvisioningState { 
    param (
        [Parameter( Mandatory=$true, Position=0 )]
        [String]
        $_DataCenterID
        ,
        [Parameter( Mandatory=$true, Position=1 )]
        [Int]
        $_Delay
    )

    write-host -NoNewline "Wait for Datacenter $_DataCenterID to change status to available, check every $_Delay seconds "
    $_waittime = 0
    do {
        start-sleep -s $_Delay
        $_waittime += $_Delay
        write-host -NoNewline "." 
    } while ( (Get-PBDatacenterState $_DataCenterID) -ne "AVAILABLE" )
    Write-Host " done! in $_waittime Seconds"
}

## request source DataCenter configuration
$srcDC = Get-PBDatacenter $srcDCid.dataCenterId

################
# create Snapshots from source datacenter
################
# The Hash SnapshotTable will associate StorageID in 
# SourceDatacenter and SnapshotID
$SnapshotTable = @{}
$SnaphotStatus = @{}
# Get List of existing Snapshots
$StoredSnaphosts = $null
$StoredSnaphosts = Get-PBSnapshots
# loop for all storages in Datacenter
foreach ($storage in $srcDC.storages) {
    Write-Host -NoNewline "Evaluate" $storage.storageName 
    # Check if there is an existing snapshot we can use
    if ( $UseExistingSnapshots -and ($existing = $StoredSnaphosts | Where-Object {$_.snapshotname -eq $storage.storageId -and $_.region -eq $srcDC.region}) ) {
        ## select newes snapshot - unsafe for now, now real timestamop in storageobject
        $existing = ($existing | Sort-Object -Property description -Descending)[0]
        Write-Host " ... Use existing Snapshot" $existing.description
        # Update SnapshotTable, associate existing Snapshot to StorageID
        $SnapshotTable += @{$storage.storageId = $existing.snapshotId }
        # Update SnapshotStatus, set status to existing
        $SnaphotStatus += @{$existing.snapshotId = "EXITING"}
    } else {
        # is the storage connected to a Server ?
        if ( $storage.serverIds ){
            Write-Host " mounted by Server" $storage.serverIds[0]
            # create warning if the connected server is running
            if ((Get-PBServer -serverId $storage.serverIds[0]).virtualMachineState -eq "RUNNING") {
                Write-Host "## Warning: Server" $storage.serverIds "is running while Snapshot is created!"
            }
        } else {
            Write-Host "    not mounted by any Server"
        }
        Write-Host "    Request new Snapshot for Storage" $storage.storageName "using StorageID" $storage.storageId
        # Create snapshot
        $Snapshot = New-PBSnapshot -storageId $storage.storageId -snapshotName $storage.storageId -description ("Auto created cloning snapshot from " + $storage.storageName + " at " + (Get-Date).ToString())
        # update SnapshotTable, associate existing Snapshot to StorageID
        $SnapshotTable += @{$storage.storageId = $Snapshot.snapshotId }
        # Update SnapshotStatus, set status to requested
        $SnaphotStatus += @{$Snapshot.snapshotId = "REQUESTED"}

    }
}

################
# wait for for snapshots to finish
################

$_snapshotToGo = $SnaphotStatus.Count 
Write-Host -NoNewline "Wait for Snapshots to be available, check every 60 seconds. Snapshots not finished: "
do {
    Sleep 60
    # update snapshotstatus for snapshots in state available
    foreach ($_snapshot in (Get-PBSnapshots | Where-Object {($_.provisioningState -eq "AVAILABLE") -and ($_.SnapshotId -in $SnaphotStatus.Keys )})) {
        # Remove the allready availible snaphot from statustable
        $SnaphotStatus.Remove($_snapshot.SnapshotId)
    }
    $_snapshotToGo = $SnaphotStatus.Count
    Write-Host -NoNewline "$_snapshotToGo, "
} while ($_snapshotToGo)
Write-Host "done!"

################
# create the new Datacenter
################

Write-Host "Create the new Datacenter $targetDCname"
$newDC = New-PBDatacenter -dataCenterName $targetDCname -Region $srcDC.region

################
# create the Storages
################
# The Hash StorageTable will associate StorageID in 
# SourceDatacenter and new created StorageID 
# in TargetDatacenter
$StorageTable = @{}
foreach ($Storage in $srcDC.storages) {
    Write-Host -NoNewline "Create new Storage" $storage.storageName "size" $storage.size "GB ..."
    # create the new Storage using properties from existing storage
    $NewStorage = New-PBStorage -dataCenterId $newDC.dataCenterId -size $storage.size -storageName $storage.storageName 
    Write-Host " and apply snapshot from source storage" $storage.storageId
    # Restore Snapshot. Use SnapshotTable to identify snapshot to use
    $RestoreSnapshot = Restore-PBSnapshot -storageId $NewStorage.StorageId -snapshotId $SnapshotTable.Item($storage.storageId)
    # update SnapshotTable, associate existing StorageID to new StorageID
    $StorageTable += @{$storage.storageId = $NewStorage.storageId}
}

################
# wait for provisioning finished
################
CheckProvisioningState $newDC.dataCenterId 60

################
# Create the Servers
################
# The Hash InternetTable will associate LanID in 
# SourceDatacenter and the Internet 
# connection status for the lanID
$InternetTable = @{}
# The Hash ServerTable will associate ServerID in 
# SourceDatacenter and new created ServerID 
# in TargetDatacenter
$ServerTable = @{}
foreach ($server in $srcDC.servers) {
    Write-Host "Create Server" $server.serverName "using" $server.cores  "cores and" ($server.ram/1024) "GB RAM"
    # create the new server using the properties from the srcDC
    $NewServer = New-PBServer -dataCenterId $newDC.dataCenterId -serverName $server.serverName -cores $server.cores -ram $server.ram -availabilityZone $server.availabilityZone -osType $server.osType
    # update ServerTable, associate existing ServerID to new ServerID
    $ServerTable += @{$server.serverId = $NewServer.serverId}
    Write-Host "    Add nics to the server"
    # Resore NICs
    foreach ($nic in $server.nics) {
        $newNic = New-PBNic -serverId $NewServer.serverId -nicName $nic.nicName -dhcpActive $nic.dhcpActive -lanId $nic.lanId
        # Restore internet connection status for the LAN (if not allready done)
        if ($nic.internetAccess -and !$InternetTable.item($nic.lanid)) {
            $setInternet = Set-PBInternetAccess -datacenterId $newDC.dataCenterId -lanId $nic.lanId -internetAccess $true
            # update InternetTable flag the Lan as Internet Connected
            $InternetTable += @{$nic.lanid = $true}
        }
    }
    Write-Host "    Connect CD-ROM to the server"
    # Resore mounted ISO Images
    foreach ($cdrom in $Server.romdrives) {
        if ($cdrom.bootDevice) {
            # use image as Bootdevice if it was bootdevice for the source server
            Write-Host "        Set Bootdevice to CD-Rom Image" $cdrom.imageId
            $storageconnect = Set-PBServer -serverId $NewServer.serverId -bootFromImageId $cdrom.imageId
        } else {
            # or just connect the image
            Write-Host "        Connect data CD-ROM Image" $cdrom.imageId
            $storageconnect = Mount-PBRomdrive -serverId $NewServer.serverId -imageId $cdrom.imageId -deviceNumber $cdrom.deviceNumber
        }
    }
    Write-Host "    Connect storages to the server"
    # restore the Storage connections
    foreach ($storage in $server.connectedStorages) {
        if ($storage.bootDevice) {
            Write-Host "        Set Bootdevice to" $StorageTable.item($storage.storageId)
            $storageconnect = Set-PBServer -serverId $NewServer.serverId -bootFromStorageId $StorageTable.item($storage.storageId)
        } else {
            Write-Host "        Connect data storage" $StorageTable.item($storage.storageId)
            $storageconnect = Connect-PBStorageToServer -serverId $NewServer.serverId -storageId $StorageTable.item($storage.storageId) -busType $storage.busType -deviceNumber $storage.deviceNumber
        }
    }
}

################
# Create the Loadbalancers
################
# not implemented yet
################
#foreach ($loadbalancer in $srcDC.loadBalancers ) {
#    $balancedserver = @()
#    foreach ($server in $loadbalancer.balancedServers) {
#        $balancedserver += $ServerTable.item($server.serverId) 
#    }
#    Write-Host "Create Loadbalancer" $loadbalancer.loadBalancerName "on Network" $loadbalancer.lanId "balancing" $balancedserver
#    # CReate Loadbalancer and assign balanced Servers
#    $NewLoadbalancer = New-PBLoadBalancer -dataCenterId $newDC.dataCenterId -loadBalancerName $loadbalancer.loadBalancerName -lanId $loadbalancer.lanId -serverIds $balancedserver
#}

################
# Thats all, wait for provisioning finished
################
CheckProvisioningState $newDC.dataCenterId 60

################
# Cleanup Snapshots
################
if ($CleanupSnapshots) {
    Write-Host -NoNewline "Cleaning up Snapshots ... "
    $null = $SnapshotTable.Values | Remove-PBSnapshot 
    Write-Host "done!"
}
