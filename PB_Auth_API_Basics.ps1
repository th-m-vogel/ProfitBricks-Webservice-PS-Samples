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
# Some basic interaction with the IONOS Auth API
# 
# This is for demonstration purpose only
#
# This example does not include any error or exeption handling
########################################################################
# (c) ProfitBricks/IONOS, 2013...2020, Autor: Thomas Vogel
########################################################################

# Webservice URI
$BaseUri = "https://api.ionos.com/auth/v1" 

### use this lines for interactive request of user credentials
#$Credential = Get-Credential -Message "IONOS Professional Cloud Account"
#$_password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( ($Credential.Password) ))
#$_user = $Credential.UserName

### credentials from an encrypted password file (see also Save-Password-as-encrypted-string.ps1)
$_password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( (Get-Content "$env:HOMEPATH\PB_API.pwd" | ConvertTo-SecureString) ))
$_user = "thomas.vogel@profitbricks.com"

### credentials from an encrypted password file (see also Save-Password-as-encrypted-string.ps1)
#$_password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( (Get-Content "$env:HOMEPATH\PB_API.pwd" | ConvertTo-SecureString) ))
#$_user = "thomas.vogel@profitbricks.com"

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
$UserAgent = "Thomas cheap PowerShell Client for IONOS Auth API v0.1"

######### helper fuction to decode JWT tokens
function Parse-JWTtoken {
 
    [cmdletbinding()]
    param([Parameter(Mandatory=$true)][string]$token)
 
    #Validate as per https://tools.ietf.org/html/rfc7519
    #Access and ID tokens are fine, Refresh tokens will not work
    if (!$token.Contains(".") -or !$token.StartsWith("eyJ")) { Write-Error "Invalid token" -ErrorAction Stop }
 
    #Header
    $tokenheader = $token.Split(".")[0].Replace('-', '+').Replace('_', '/')
    #Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0
    while ($tokenheader.Length % 4) { Write-Verbose "Invalid length for a Base-64 char array or string, adding ="; $tokenheader += "=" }
    Write-Verbose "Base64 encoded (padded) header:"
    Write-Verbose $tokenheader
    #Convert from Base64 encoded string to PSObject all at once
    Write-Verbose "Decoded header:"
    [System.Text.Encoding]::ASCII.GetString([system.convert]::FromBase64String($tokenheader)) | ConvertFrom-Json | fl | Out-Default
 
    #Payload
    $tokenPayload = $token.Split(".")[1].Replace('-', '+').Replace('_', '/')
    #Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0
    while ($tokenPayload.Length % 4) { Write-Verbose "Invalid length for a Base-64 char array or string, adding ="; $tokenPayload += "=" }
    Write-Verbose "Base64 encoded (padded) payoad:"
    Write-Verbose $tokenPayload
    #Convert to Byte array
    $tokenByteArray = [System.Convert]::FromBase64String($tokenPayload)
    #Convert to string array
    $tokenArray = [System.Text.Encoding]::ASCII.GetString($tokenByteArray)
    Write-Verbose "Decoded array in JSON format:"
    Write-Verbose $tokenArray
    #Convert from JSON to PSObject
    $tokobj = $tokenArray | ConvertFrom-Json
    Write-Verbose "Decoded Payload:"
    
    return $tokobj
}


######### Work with the API

### Find available Tokens
$Response = Invoke-RestMethod -Uri "$BaseUri/tokens" -Headers $Headers -Method Get -UserAgent $UserAgent
Write-Host "#### $BaseUri/profile Found the following valid Tokens:"

$Response.tokens

exit

### cleanup tokens
if ($Response.tokens.Count -gt 0) {
    foreach ($Token in $Response.tokens) {
        $Content = Invoke-RestMethod -Uri $Token.href -Headers $Headers -Method Delete -UserAgent $UserAgent
        $Content
    }
} 

exit

## Generate a Token
$Token = Invoke-RestMethod -Uri "$BaseUri/tokens/generate" -Headers $Headers -Method Get -UserAgent $UserAgent
$TokenString64 = $Token.token

Write-Host "Token as String: " $TokenString64

Parse-JWTtoken $TokenString64 | ConvertTo-Json
