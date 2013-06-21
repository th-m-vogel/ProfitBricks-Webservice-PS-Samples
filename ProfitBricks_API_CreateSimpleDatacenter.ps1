########################################################################
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
########################################################################
# Consume ProfitBricks SOAP-Api using Powershell
# This is for demonstration purpose only
#
# This example does not include any error or exeption handling
#
# Code Repository: https://github.com/th-m-vogel/ProfitBricks-Webservice-PS-Samples
########################################################################
# (c) ProfitBricks, 2013, Autor: Thomas Vogel
########################################################################

## Set the URI to the PB-API WSLD
$pb_wsdl = "https://api.profitbricks.com/1.2/wsdl"

## connect the WDSL
$pb_api = New-WebServiceProxy -Uri $pb_wsdl -namespace ProfitBricks -class pbApiClass

## use this line for interactive request of user credidentials
$pb_creds = Get-Credential -Message "ProfitBricks Account"

## use the following thre code lines for
# file stored credidentials. (password as encrypted String)
# to create stored Credidentials you may use
#   https://github.com/th-m-vogel/ProfitBricks-Webservice-PS-Samples/blob/master/Save-Password-as-encrypted-string.ps1
##
# $_password = Get-Content "$env:HOMEPATH\PB_API.pwd" | ConvertTo-SecureString 
# $_user = "username@domain.top"
# $pb_creds = New-Object System.Management.Automation.PsCredential($_user,$_password)
# end import password from file 

## add the credidentials for api access (common)
$pb_api.Credentials = $pb_creds

################
# initialisation done. $pb_api is a instance crated regarding WSDL
# try $pb_api | gm ...
################

## create a function to wait for a ready to use datacenter
function CheckProvisioningState { 
    param ($_DataCenterID)
    write-host -NoNewline "Wait for Datacenter to change status to availible ..."
    do {
        $_DC = $pb_api.getDataCenter($_DataCenterID)
        if ($_DC.provisioningStateSpecified -and ($_DC.provisioningState -ne "AVAILABLE")) {
            write-host -NoNewline "." 
            start-sleep -s 1
            $_DC = $pb_api.getDataCenter($_DataCenterID)
        } 
    } while ($_DC.provisioningStateSpecified -and ($_DC.provisioningState -ne "AVAILABLE"))
    Write-Host " done ..."
}

################
# now we are ready to consume the PB-API
################

## Specify Region to use
$my_region = "EUROPE"

## get list of all availible Images
$pb_images = $pb_api.getAllImages()
## Pick the Windows Server 2012 imag
$image = $pb_images | Where-Object {($_.ImageName -eq "windows-2012-server-4.13.img") -and ($_.region -eq $my_region)}
write-host "Will use the followinmg Image to create a new Server:" $image.imageName

################
# Create a new Datacenter
################

## create a new and empty Datacenter
Write-host "Create the new Datacenter ..."
$DatacenterResponse = $pb_api.createDataCenter("My New API created Datacenter",$my_region,$true)

## create a StorageRequest
$StorageRequest = New-Object ProfitBricks.createStorageRequest
$StorageRequest.dataCenterId = $DatacenterResponse.dataCenterId
$StorageRequest.storageName = "WindowsServer Drive C"
$StorageRequest.size = 40
$StorageRequest.mountImageId = $image.imageId
$StorageRequest.profitBricksImagePassword = "asdfghjk"
## invoke the createStorage methode
Write-Host "Create the Storage Device ..."
$StorageResponse = $pb_api.createStorage($StorageRequest)

## create a ServerRequest
$ServerRequest = New-Object ProfitBricks.createServerRequest
$ServerRequest.dataCenterId = $DatacenterResponse.dataCenterId
$ServerRequest.cores = 2
$ServerRequest.ram = 4096
$ServerRequest.serverName = "Windows2012 Server"
$ServerRequest.bootFromStorageId = $StorageResponse.storageId
$ServerRequest.internetAccess = $true
## invoke the createServer methode
Write-host "Create the new Server using the newly created Storage as boot device ..."
$ServerResponse = $pb_api.createServer($ServerRequest)

## and  check provisioning state
CheckProvisioningState($DatacenterResponse.dataCenterId)

## Set the Name for the newly create network card (cosmetics ...)
Write-host "Set a name to the newly created Nic ..."
$NicResponse = $pb_api.updateNic(@{nicId=$pb_api.getServer($ServerResponse.ServerID).nics[0].nicId;nicName="Lan0"})
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