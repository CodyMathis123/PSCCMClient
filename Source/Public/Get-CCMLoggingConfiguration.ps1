function Get-CCMLoggingConfiguration {
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
        $getLogInfoSplat = @{
            Namespace   = 'root\ccm\policy\machine\actualconfig'
            ClassName   = 'CCM_Logging_GlobalConfiguration'
            ErrorAction = 'Stop'
        }
        $getLogLocationSplat = @{
            Property = 'LogDirectory'
            Key      = 'SOFTWARE\Microsoft\CCM\Logging\@Global'
            RegRoot  = 'HKEY_LOCAL_MACHINE'
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
                [array]$CimResult = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getLogInfoSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getLogInfoSplat @connectionSplat
                    }
                }
                if ($CimResult -is [Object] -and $CimResult.Count -gt 0) {
                    foreach ($Object in $CimResult) {
                        $Result['LogDirectory'] = (Get-CCMRegistryProperty @getLogLocationSplat @connectionSplat)[$Computer].LogDirectory
                        $Result['LogMaxSize'] = $Object.LogMaxSize
                        $Result['LogMaxHistory'] = $Object.LogMaxHistory
                        $Result['LogLevel'] = $Object.LogLevel
                        $Result['LogEnabled'] = $Object.LogEnabled
                        [PSCustomObject]$Result
                    }
                }
                else {
                    $Result['LogDirectory'] = $null
                    $Result['LogMaxSize'] = $null
                    $Result['LogMaxHistory'] = $null
                    $Result['LogLevel'] = $null
                    $Result['LogEnabled'] = $null
                    [PSCustomObject]$Result
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}