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

# Destinatio Folder for CSV Data
$ExportPath = "$env:HOMEPATH\Documents\_Billing_Export"

#
# different metodes for credential handling
#
### credentials from an encrypted password file (see also Save-Password-as-encrypted-string.ps1)
$_pwfile = "$env:HOMEPATH\PB_API.pwd"
$_user = "thomas.vogel@profitbricks.com"
### get encrypted password
$_password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( (Get-Content $_pwfile | ConvertTo-SecureString) ))

### how to create an password file uning SecureString
# $_creds = Get-Credential -Message "Enter credentials"
# $_creds.Password | ConvertFrom-SecureString | Set-Content $_pwfile

### set Username and Password in plain text
# $_user = "username_here"
# $_password = "cleartext_password_here"

### use this lines for interactive request of user credentials
# $Credential = Get-Credential -Message "IONOS IaaS Account"
# $_password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( ($Credential.Password) ))
# $_user = $Credential.UserName


######### Initialisation section

### Convert username and password to an Base64 encoded String
$AuthStringBase64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($_user):$($_password)")) 

### Create an object to store http headers in
$Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
# Add Authorization Header
$Headers.Add("AUTHORIZATION", "Basic $AuthStringBase64");

### Some additional variables for the script
# Define your own UserAgent (if you want)
$UserAgent = "Thomas cheap PowerShell Client for IONOS Billing API v0.1"

# Invoice to get - posting periond (last month)
$LastMonth = ((Get-Date).AddMonths(-1)).ToString("yyyy-MM")

# initialize Exportdata
$ExportData = @()
$ExportRaw  = @()

### Some additional variables for the script
# Webservice URI
$BaseUri = "https://api.ionos.com/billing" 


### culture handling - for handling number/date formats and CSV separators
# data from API is "en-EN", used for conversion
$en = New-Object system.globalization.cultureinfo("en-EN")
$de = New-Object system.globalization.cultureinfo("de-DE")
# target culture is "de-DE"
Set-Culture $de

#
#
#
#
### Find available Profiles - this is only one, your contract, if you are not a reseller
$Profile = Invoke-RestMethod -Uri "$BaseUri/profile" -Headers $Headers -Method Get -UserAgent $UserAgent
Write-Host "#### Found the following valid Companies:"
$Companies = $profile.companies | Sort-Object -Property contractid
$Companies | Format-Table


#
#
#
#
### get available data per contract
foreach ($company in $Companies ) {
    $contract = $company.contractId
    #
    ### get products
    $Products = $null
    $Products = Invoke-RestMethod -Uri "$BaseUri/$contract/products" -Headers $Headers -Method Get -UserAgent $UserAgent -ErrorAction SilentlyContinue    
    #
    ### get available Invoices
    $Invoices = $null
    $Invoices = Invoke-RestMethod -Uri "$BaseUri/$contract/invoices" -Headers $Headers -Method Get -UserAgent $UserAgent 
    if ( -not $Invoices.invoices ) {
        Write-Host $company.contractId $company.resellerRef "Has NO Invoices - going to next contract"
        # skip cutomers without Invoices available
        continue
    }
    #
    ### Retrive the last Month availabe Invoice
    $ActiveInvoice = $Invoices.invoices | Where-Object {$_.date -eq $LastMonth}
    if ($ActiveInvoice) {
        Write-Host "Contract Nr.:" $company.contractId "Last invoice with ID" $ActiveInvoice.id "from" $ActiveInvoice.date 
        $Invoice = Invoke-RestMethod -Uri "$BaseUri/$contract/invoices/$($ActiveInvoice.id)" -Headers $Headers -Method Get -UserAgent $UserAgent

        # process each datacenter
        foreach ($datacenter in $Invoice.datacenters ) {
            # Read datacenters
            foreach ($meter in $datacenter.meters) {
                # Build import Record per product in datacenter
                Write-Host $datacenter.name
                $line = @{
                    Customer_ID = $company.customerId
                    Contract_ID = $company.contractId
                    Reseller_Reference = $company.resellerRef
                    Datacenter_Name = $datacenter.name
                    Datacenter_Location = $datacenter.location
                    Datacenter_UUID = $datacenter.id
                    Product_Number = $meter.meterId
                    Product_Name = $meter.meterDesc
                    Product_Group = $meter.productGroup
                    Product_Amount = $meter.quantity.quantity
                    Product_Unit = $meter.quantity.unit
                    Product_Unit_Price = $meter.rate.quantity
                    Product_Price = $meter.amount.quantity
                    Product_Price_Unit = $meter.amount.unit
                    StartDate = $Invoice.metadata.startDate.ToDateTime($en.DateTimeFormat)
                    EndDate = $Invoice.metadata.endDate.ToDateTime($en.DateTimeFormat)
                }
                $line.StartDate = $line.StartDate.ToShortDateString()
                $line.EndDate = $line.EndDate.ToShortDateString()
                $ExportData += New-Object psobject -Property $line
            }
            # build import record for rebate
            $line = @{
                Customer_ID = $company.customerId
                Contract_ID = $company.contractId
                Reseller_Reference = $company.resellerRef
                Datacenter_Name = $datacenter.name
                Datacenter_Location = $datacenter.location
                Datacenter_UUID = $datacenter.id
                Product_Name = "Rebate"
                Product_Group = $datacenter.productGroup
                Product_Price = $datacenter.rebate.amount.quantity
                Product_Price_Unit = $datacenter.rebate.amount.unit
                StartDate = $Invoice.metadata.startDate.ToDateTime($en.DateTimeFormat)
                EndDate = $Invoice.metadata.endDate.ToDateTime($en.DateTimeFormat)
            }
            $line.StartDate = $line.StartDate.ToShortDateString()
            $line.EndDate = $line.EndDate.ToShortDateString()
            $ExportData += New-Object psobject -Property $line
        }
    } 
}


### for demonstartion purpose we just export to CSV, you could also directly write the data to a database or ERP API
$ExportFile = "$ExportPath\IAAS_$LastMonth.csv"

$ExportData | Select-Object Customer_ID,Contract_ID,Reseller_Reference,Datacenter_Name,Datacenter_Location,Datacenter_UUID,Product_Number,Product_Name,Product_Group,Product_Amount,Product_Unit,Product_Unit_Price,Product_Price,Product_Price_Unit,StartDate,EndDate | Export-Csv -Path $ExportFile -Delimiter ";" -NoTypeInformation 

Write-Host "CSV Billing data written to: $ExportFile .... This windows will close in 5 seconds"

# sleep 5

exit

#
# itemized data per datacenter https://api.ionos.com/billing/{contract}/utilisation/{period}´
#
$utilization = Invoke-RestMethod -Uri "$BaseUri/$contract/utilization/$($LastMonth)" -Headers $Headers -Method Get -UserAgent $UserAgent

