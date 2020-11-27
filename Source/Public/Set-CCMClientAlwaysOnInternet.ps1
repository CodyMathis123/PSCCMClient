function Set-CCMClientAlwaysOnInternet {
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Enabled', 'Disabled')]
        [string]$Status,
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
        $Enablement = switch ($Status) {
            'Enabled' {
                1
            }
            'Disabled' {
                0
            }
        }
        $SetAlwaysOnInternetSplat = @{
            Force        = $true
            PropertyType = 'DWORD'
            Property     = 'ClientAlwaysOnInternet'
            Value        = $Enablement
            Key          = 'SOFTWARE\Microsoft\CCM\Security'
            RegRoot      = 'HKEY_LOCAL_MACHINE'
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

            try {
                Set-CCMRegistryProperty @SetAlwaysOnInternetSplat @connectionSplat
            }
            catch {
                Write-Error "Failure to set MEMCM ClientAlwaysOnInternet to $Enablement for $Computer - $($_.Exception.Message)"
            }
        }
    }
}