#################################################
# HelloID-Conn-Prov-Target-Exact-Proquro-Create
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

#region functions
function Resolve-ExactProquroError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]
        $ErrorObject
    )
    process {
        $httpErrorObj = [PSCustomObject]@{
            ScriptLineNumber = $ErrorObject.InvocationInfo.ScriptLineNumber
            Line             = $ErrorObject.InvocationInfo.Line
            ErrorDetails     = $ErrorObject.Exception.Message
            FriendlyMessage  = $ErrorObject.Exception.Message
        }
        if ($ErrorObject.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') {
            $httpErrorObj.ErrorDetails = $ErrorObject.ErrorDetails.Message
        }
        # Response is null when no connection could be made (wrong BaseUrl or port, host down, TLS failure)
        elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException' -and $ErrorObject.Exception.Response) {
            $stream = $ErrorObject.Exception.Response.GetResponseStream()
            $stream.Position = 0
            $streamReader = New-Object System.IO.StreamReader $stream
            $httpErrorObj.ErrorDetails = $streamReader.ReadToEnd()
        }
        $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails
        Write-Output $httpErrorObj
    }
}
#endregion

try {
    # Initial Assignments
    $outputContext.AccountReference = 'Currently not available'

    # No lookup of an existing account: Exact Proquro creates or updates the user on the same call
    $lifecycleProcess = 'CreateAccount'

    Write-Information 'Retrieving accessToken'
    $splatGetTokenParams = @{
        Uri         = "$($actionContext.Configuration.BaseUrl)/token"
        Method      = 'POST'
        ContentType = 'application/x-www-form-urlencoded'
        Headers     = @{
            'Accept'        = 'application/json'
            'Cache-Control' = 'no-cache'
        }
        Body        = @{
            grant_type = 'password'
            username   = $actionContext.Configuration.UserName
            password   = $actionContext.Configuration.Password
            apikey     = $actionContext.Configuration.ApiKey
        }
    }
    $accessToken = (Invoke-RestMethod @splatGetTokenParams).access_token
    if (-not $accessToken) { throw 'No access_token in token response' }

    $headers = @{
        'Content-Type'  = 'application/json'
        'Accept'        = 'application/json'
        'Cache-Control' = 'no-cache'
        'Authorization' = "Bearer $accessToken"
    }

    # Process
    switch ($lifecycleProcess) {
        'CreateAccount' {
            # Fixed mapping values arrive as strings, the API expects a boolean
            $body = $actionContext.Data | Select-Object -Property * -ExcludeProperty passwordMustChange
            $body | Add-Member -NotePropertyName passwordMustChange -NotePropertyValue ([string]$actionContext.Data.passwordMustChange -eq 'true')

            Write-Information 'Creating and correlating Exact Proquro account'
            $splatCreateParams = @{
                Uri         = "$($actionContext.Configuration.BaseUrl)/api/User/Update"
                Method      = 'POST'
                Headers     = $headers
                # UTF-8 bytes: Windows PowerShell 5.1 would send a string body as ISO-8859-1
                ContentType = 'application/json; charset=utf-8'
                Body        = [System.Text.Encoding]::UTF8.GetBytes(($body | ConvertTo-Json))
            }

            if (-not($actionContext.DryRun -eq $true)) {
                $createdAccount = Invoke-RestMethod @splatCreateParams

                # Fall back to the mapped externalID when the response has none; never report success without a reference
                $accountReference = if ($createdAccount.externalId) { $createdAccount.externalId } else { $actionContext.Data.externalID }
                if (-not $accountReference) { throw 'No externalId in the response and no externalID in the mapped data' }
                $outputContext.Data = $actionContext.Data
                $outputContext.AccountReference = $accountReference
            }
            else {
                Write-Information '[DryRun] Create and correlate Exact Proquro account, will be executed during enforcement'
            }
            $auditLogMessage = "Create account was successful. AccountReference is: [$($outputContext.AccountReference)]"
            break
        }
    }

    $outputContext.success = $true
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Action  = $lifecycleProcess
            Message = $auditLogMessage
            IsError = $false
        })
}
catch {
    $outputContext.success = $false
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-ExactProquroError -ErrorObject $ex
        $auditLogMessage = "Could not create or correlate Exact Proquro account: [$($actionContext.Data.externalID)]. Error: $($errorObj.FriendlyMessage)"
        Write-Warning "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
    }
    else {
        $auditLogMessage = "Could not create or correlate Exact Proquro account: [$($actionContext.Data.externalID)]. Error: $($ex.Exception.Message)"
        Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Action  = 'CreateAccount'
            Message = $auditLogMessage
            IsError = $true
        })
}
