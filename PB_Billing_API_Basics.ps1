########################################################################
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
# Some basic interaction with the IONOS Billing API
# 
# This is for demonstration purpose only
#
# This example does not include any error or exeption handling
########################################################################
# (c) ProfitBricks/IONOS, 2013...2020, Autor: Thomas Vogel
########################################################################

# Webservice URI
$BaseUri = "https://api.ionos.com/billing" 

### use this lines for interactive request of user credentials
# $Credential = Get-Credential -Message "IONOS Professional Cloud Account"
# $_password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( ($Credential.Password) ))
# $_user = $Credential.UserName

### credentials from an encrypted password file (see also Save-Password-as-encrypted-string.ps1)
$_password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( (Get-Content "$env:HOMEPATH\PB_API.pwd" | ConvertTo-SecureString) ))
$_user = "thomas.vogel@profitbricks.com"

### set Username and Password in plain text
# $_user = "thomas.vogel@profitbricks.com"
# $_password = "cleartext_password_here"

######### Initialisation section

### Convert username and password to an Base64 encoded String
$AuthStringBase64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($_user):$($_password)")) 

### Create an object to store http headers in
$Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
# Add Authorization Header
$Headers.Add("AUTHORIZATION", "Basic $AuthStringBase64");

### Some additional variables for the script
# Define your own UserAgent (if you want)
$UserAgent = "Thomas cheap PowerShell Client for IONOS Billing API"

######### Work with the API

### Find available Profiles - should only be one if you are not a reseller
$Profile = Invoke-RestMethod -Uri "$BaseUri/profile" -Headers $Headers -Method Get -UserAgent $UserAgent
Write-Host "#### $BaseUri/profile Found the following valid Companies / Contracts:"
$Companies = $profile.companies | Sort-Object -Property contractid
$Companies | Format-Table

### Show available data per contract
foreach ($company in $Companies ) {
    $contract = $company.contractId
    Write-Host " "
    Write-Host "########################################################################################################"
    Write-Host "Getting available data for customerID " $company.customerId " contract $contract"

    ### get products
    $Products = $null
    $Products = Invoke-RestMethod -Uri "$BaseUri/$contract/products" -Headers $Headers -Method Get -UserAgent $UserAgent -ErrorAction SilentlyContinue    

    ### Show available Usage
    $Usage = $null
    Write-Host "#### Found the following valid Usage at $BaseUri/$contract/usage :"
    $Usage = Invoke-RestMethod -Uri "$BaseUri/$contract/usage" -Headers $Headers -Method Get -UserAgent $UserAgent 

    if ($Usage.datacenters) {
        foreach ($dc in $Usage.datacenters) {
            Write-Host "   #### in Datacenter" $dc.id $dc.name
            $dc.meters | Format-Table
        }
        Add-Member -InputObject $company -MemberType NoteProperty -Name "HasUsage" -Value "Yes"
    } else {
        Write-Host "... Nothing found"
    }

    
    ### Show available Invoices
    $Invoices = $null
    Write-Host "#### Found the following valid Invoices at $BaseUri/$contract/invoices :" 
    $Invoices = Invoke-RestMethod -Uri "$BaseUri/$contract/invoices" -Headers $Headers -Method Get -UserAgent $UserAgent 
    if ($Invoices.invoices) {
        $Invoices.invoices | Format-Table
        Add-Member -InputObject $company -MemberType NoteProperty -Name "HasInvoices" -Value "Yes"
    } else {
        Write-Host "... Nothing found"
    }
    Write-Host ""

    ### Retrive the last availabe Invoice
    if ($Invoices.invoices.count -gt 0) {
        Write-Host "#### Last invoice with ID" $Invoices.invoices[$Invoices.invoices.count-2].id "from" $Invoices.invoices[$Invoices.invoices.count-2].date "at" $BaseUri/$contract/invoices/$($invoices.invoices[$Invoices.invoices.count-2].id)
        $Invoice = Invoke-RestMethod -Uri "$BaseUri/$contract/invoices/$($invoices.invoices[$Invoices.invoices.count-1].id)" -Headers $Headers -Method Get -UserAgent $UserAgent
        $Invoice.datacenters | Format-Table
    } 
}

exit 

#export Products
foreach ($product  in $Products.products ) {
    Add-Member -InputObject $product -MemberType NoteProperty -Name price -value $product.unitCost.quantity
    Add-Member -InputObject $product -MemberType NoteProperty -Name curency -value $product.unitCost.unit
}

$Products.products | Select-Object -Property meterId,meterDesc,unit,price,curency | Export-Csv -Path Produktstammdaten-ProfitBricks-IaaS.csv -Force -Delimiter ";" -NoTypeInformation

exit
