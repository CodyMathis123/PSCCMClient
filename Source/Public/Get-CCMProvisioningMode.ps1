function Get-CCMProvisioningMode {
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
        $getCIMRegistryPropertySplat = @{
            RegRoot  = 'HKEY_LOCAL_MACHINE'
            Key      = 'Software\Microsoft\CCM\CcmExec'
            Property = 'ProvisioningMode', 'ProvisioningEnabledTime', 'ProvisioningMaxMinutes'
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

            $Return = [ordered]@{ }
            $Return['ComputerName'] = $Computer
            try {
                $ProvisioningModeInfo = Get-CCMRegistryProperty @getCIMRegistryPropertySplat @connectionSplat
                if ($ProvisioningModeInfo -is [object]) {
                    $Return['ProvisioningMode'] = $ProvisioningModeInfo.$Computer.ProvisioningMode
                    $EnabledTime = switch ([string]::IsNullOrWhiteSpace($ProvisioningModeInfo.$Computer.ProvisioningEnabledTime)) {
                        $false {
                            [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($ProvisioningModeInfo.$Computer.ProvisioningEnabledTime))
                        }
                    }
                    $Return['ProvisioningEnabledTime'] = $EnabledTime
                    $Return['ProvisioningMaxMinutes'] = $ProvisioningModeInfo.$Computer.ProvisioningMaxMinutes
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
            [pscustomobject]$Return
        }
    }
}
