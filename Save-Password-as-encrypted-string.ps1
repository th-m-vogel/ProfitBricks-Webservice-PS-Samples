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
# Stor credentials.password to encrypted string
# only the same user is able to use the encrypted string
# if the script has to run on a differemt account, 
# ConverFrom-SecureString and ConvertTo-SecureStrimg
# does require the -key parameter
#    http://technet.microsoft.com/en-us/library/hh849818.aspx
# 
# This is for demonstration purpose only
#
# This example does not include any error or exeption handling
########################################################################
# (c) ProfitBricks, 2013, Autor: Thomas Vogel
########################################################################

## request credentials
$creds = Get-Credential -Message "Enter credentials"

## save credentials.password as encrypted secure string
$creds.Password | ConvertFrom-SecureString | Set-Content "$env:HOMEPATH\PB_API.pwd"

## done ...