function Invoke-CCMResetPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Purge', 'ForceFull')]
        [string]$ResetType = 'Purge',
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
        $uFlags = switch ($ResetType) {
            'Purge' {
                1
            }
            'ForceFull' {
                0
            }
        }
        $policyResetSplat = @{
            MethodName = 'ResetPolicy'
            Namespace  = 'root\ccm'
            ClassName  = 'sms_client'
            Arguments  = @{
                uFlags = [uint32]$uFlags
            }
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
            $Result['PolicyReset'] = $false
            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [ResetType = '$ResetType']", "Reset CCM Policy")) {
                try {
                    $Invocation = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Invoke-CimMethod @policyResetSplat
                        }
                        $false {
                            $invokeCommandSplat = @{
                                ArgumentList = $policyResetSplat
                                ScriptBlock  = {
                                    param($policyResetSplat)
                                    Invoke-CimMethod @policyResetSplat
                                }
                            }
                            Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                        }
                    }
                    if ($Invocation) {
                        Write-Verbose "Successfully invoked policy reset on $Computer via the 'ResetPolicy' CIM method"
                        $Result['PolicyReset'] = $true
                    }
                    [pscustomobject]$Result
                }
                catch {
                    $ErrorMessage = $_.Exception.Message
                    Write-Error $ErrorMessage
                }
            }
        }
    }
}