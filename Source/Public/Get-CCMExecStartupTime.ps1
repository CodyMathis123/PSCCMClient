function Get-CCMExecStartupTime {
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
        $getCCMExecServiceSplat = @{
            Query = "SELECT State, ProcessID from Win32_Service WHERE Name = 'CCMExec'"
        }
        $getCCMExecProcessSplat = @{ }
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
                [ciminstance[]]$CCMExecService = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getCCMExecServiceSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getCCMExecServiceSplat @connectionSplat
                    }
                }
                if ($CCMExecService -is [Object] -and $CCMExecService.Count -gt 0) {
                    foreach ($Service in $CCMExecService) {
                        $getCCMExecProcessSplat['Query'] = [string]::Format("Select CreationDate from Win32_Process WHERE ProcessID = '{0}'", $Service.ProcessID)
                        [ciminstance[]]$CCMExecProcess = switch ($Computer -eq $env:ComputerName) {
                            $true {
                                Get-CimInstance @getCCMExecProcessSplat @connectionSplat
                            }
                            $false {
                                Get-CCMCimInstance @getCCMExecProcessSplat @connectionSplat
                            }
                        }
                        if ($CCMExecProcess -is [Object] -and $CCMExecProcess.Count -gt 0) {
                            foreach ($Process in $CCMExecProcess) {
                                $Result['ServiceState'] = $Service.State
                                $Result['StartupTime'] = $Process.CreationDate
                                [pscustomobject]$Result
                            }
                        }
                    }
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}