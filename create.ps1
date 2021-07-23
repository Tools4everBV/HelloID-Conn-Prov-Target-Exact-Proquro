#######################################################
# HelloID-Conn-Prov-Target-Exact-Proquro
#
# Version: 1.0.0.0
#######################################################
$VerbosePreference = "Continue"

# Initialize default value's
$config = $configuration | ConvertFrom-Json
$p = $person | ConvertFrom-Json
$success = $false
$auditLogs = New-Object Collections.Generic.List[PSCustomObject]

$account = [PSCustomObject]@{
    externalID            = $p.ExternalId
    firstName             = $p.Name.GivenName
    middleInitials        = $p.Name.Initials
    surName               = $p.Name.FamilyName
    email                 = $p.Contact.Business.Email
    telephone             = $p.Contact.Business.Phone.Fixed
    mobile                = $p.Contact.Business.Phone.Mobile
    loginName             = $p.UserName
    password              = ''
    passwordMustChange    = $true
    status                = 'active'
    profileUserExternalId = ''
} | ConvertTo-Json

#region Helper Functions
function Resolve-HTTPError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline
        )]
        [object]$ErrorObject
    )
    process {
        $HttpErrorObj = @{
            FullyQualifiedErrorId = $ErrorObject.FullyQualifiedErrorId
            MyCommand             = $ErrorObject.InvocationInfo.MyCommand
            RequestUri            = $ErrorObject.TargetObject.RequestUri
        }
        if ($ErrorObject.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') {
            $HttpErrorObj['ErrorMessage'] = $ErrorObject.ErrorDetails.Message
        } elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            $stream = $ErrorObject.Exception.Response.GetResponseStream()
            $stream.Position = 0
            $streamReader = New-Object System.IO.StreamReader $Stream
            $errorResponse = $StreamReader.ReadToEnd()
            $HttpErrorObj['ErrorMessage'] = $errorResponse
        }
        Write-Output "'$($HttpErrorObj.ErrorMessage)', TargetObject: '$($HttpErrorObj.RequestUri), InvocationCommand: '$($HttpErrorObj.MyCommand)"
    }
}
#endregion

if (-not($dryRun -eq $true)) {
    try {
        Write-Verbose "Creating account for '$($p.DisplayName)'"

        if ($($config.IsConnectionTls12)) {
            Write-Verbose 'Switching to TLS 1.2'
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
        }

        Write-Verbose 'Retrieving accessToken'
        $splatGetTokenParams = @{
            Uri     = "$($config.BaseUrl)/token"
            Headers = @{
                "Content-Type"  = "application/json"
                "Accept"        = "application/json"
                "Cache-Control" = "no-cache"
            }
            $body = @{
                "grant_type" = "password&username=$($config.UserName)&password=$($config.Password)&&apikey=$($config.ApiKey)"
            }
        }
        $accessToken = Invoke-RestMethod @splatGetTokenParams

        Write-Verbose 'Adding authorization headers'
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add("Content-Type", "application/json")
        $headers.Add("Accept", "application/json")
        $headers.Add("Cache-Control", "no-cache")
        $headers.Add("Authorization", "Bearer $accessToken")

        $splatParams = @{
            Uri      = "$($config.BaseUrl)/api/User/Update"
            Headers  = $headers
            Body     = $account
            Method   = 'POST'
        }
        $results = Invoke-RestMethod @splatParams
        $accountReference = $results.externalId
        $logMessage = "Account for '$($p.DisplayName)' successfully created. Correlation id: '$accountReference'"
        Write-Verbose $logMessage
        $success = $true
        $auditLogs.Add([PSCustomObject]@{
            Message = $logMessage
            IsError = $False
        })
    } catch {
        $ex = $PSItem
        if ( $($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
            $errorMessage = Resolve-HTTPError -Error $ex
            $auditMessage = "Account for '$($p.DisplayName)' not created. Error: $errorMessage"
        } else {
            $auditMessage = "Account for '$($p.DisplayName)' not created. Error: $($ex.Exception.Message)"
        }
        $auditLogs.Add([PSCustomObject]@{
            Message = $auditMessage
            IsError = $true
        })
        Write-Error $auditMessage
    }
}

$result = [PSCustomObject]@{
    Success          = $success
    Account          = $account
    AccountReference = $accountReference
    AuditLogs        = $auditLogs
}

Write-Output $result | ConvertTo-Json -Depth 10
