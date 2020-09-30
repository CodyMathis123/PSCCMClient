function Get-CCMClientVersion {
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [Alias('Session')]      
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession,
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [ValidateSet('CimSession', 'PSSession')]
        [string]$ConnectionPreference
    )
    begin {
        $getClientVersionSplat = @{
            Namespace = 'root\CCM'
            Query     = 'SELECT ClientVersion FROM SMS_Client'
        }
    }
    process {
        foreach ($Connection in (Get-Variable -Name $PSCmdlet.ParameterSetName -ValueOnly)) {
            $getConnectionInfoSplat = @{
                $PSCmdlet.ParameterSetName = $Connection
            }
            switch ($PSBoundParameters.ContainsKey('ConnectionPreference')) {
                $true {
                    $getConnectionInfoSplat['Prefer'] = $ConnectionPreference
                }
            }
            $ConnectionInfo = Get-CCMConnection @getConnectionInfoSplat
            $Computer = $ConnectionInfo.ComputerName
            $connectionSplat = $ConnectionInfo.connectionSplat
            $Result = [ordered]@{ }
            $Result['ComputerName'] = $Computer

            try {
                [ciminstance[]]$Currentversion = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getClientVersionSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getClientVersionSplat @connectionSplat
                    }
                }
                if ($Currentversion -is [Object] -and $Currentversion.Count -gt 0) {
                    foreach ($SMSClient in $Currentversion) {
                        $Result['ClientVersion'] = $SMSClient.ClientVersion
                        [PSCustomObject]$Result
                    }
                }
                else {
                    Write-Warning "No client version found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}