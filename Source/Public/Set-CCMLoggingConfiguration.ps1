function Set-CCMLoggingConfiguration {
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Default', 'Verbose', 'None')]
        [string]$LogLevel,
        [Parameter(Mandatory = $false)]
        [int]$LogMaxSize,
        [Parameter(Mandatory = $false)]
        [int]$LogMaxHistory,
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
        $BaseLogConfigSplat = @{
            Force        = $true
            PropertyType = 'String'
            Key          = 'SOFTWARE\Microsoft\CCM\Logging\@Global'
            RegRoot      = 'HKEY_LOCAL_MACHINE'
        }

        #region Format some parameters if provided
        switch ($PSBoundParameters.Keys) {
            '^LogDirectory$' {
                $LogDirectory = $LogDirectory.TrimEnd('\')
            }
            '^LogLevel$' {
                $LogLevel = switch ($LogLevel) {
                    'None' {
                        2
                    }
                    'Default' {
                        1
                    }
                    'Verbose' {
                        0
                    }
                }
            }
        }
        #endregion Format some parameters if provided
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

            if ($PSCmdlet.ShouldProcess([string]::Join(' ', $PSBoundParameters.Keys), "Set-CCMLoggingConfiguration")) {
                $Result = [ordered]@{ }
                $Result['ComputerName'] = $Computer
                $Result['LogConfigChanged'] = $false

                try {
                    switch -regex ($PSBoundParameters.Keys) {
                        "^LogDirectory$|^LogLevel$|^LogMaxSize$|^LogMaxHistory$" { 
                            $BaseLogConfigSplat['Property'] = $PSItem
                            $BaseLogConfigSplat['Value'] = Get-Variable -Name $PSItem -ValueOnly -Scope Local
                            Set-CCMRegistryProperty @BaseLogConfigSplat @connectionSplat
                        }
                    }
                    Write-Warning "The CCMExec service needs restarted for log location changes to take full affect."
                    $Result['LogConfigChanged'] = $true
                }
                catch {
                    $ErrorMessage = $_.Exception.Message
                    Write-Error $ErrorMessage
                    [pscustomobject]$Result
                }
                [pscustomobject]$Result
            }
        }
    }
}