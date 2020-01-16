function Invoke-CCMResetPolicy {
    <#
    .SYNOPSIS
        Invokes a ResetPolicy for the MEMCM client
    .DESCRIPTION
        This function will force a complete policy reset on a client for multiple computers using CIM queries.
        You can provide an array of computer names, or cimsessions, or you can pass them through the pipeline.
    .PARAMETER ResetType
        Determins the policy reset type.

        'Purge' will wipe all policy from the machine, forcing a complete redownload, and rebuilt.

        'ForceFull' will simply force the next policy refresh to be a full instead of a delta.

        https://docs.microsoft.com/en-us/previous-versions/system-center/developer/cc143785%28v%3dmsdn.10%29
    .PARAMETER CimSession
        Provides CimSession to perform a policy reset on
    .PARAMETER ComputerName
        Provides computer names to perform a policy reset on
    .EXAMPLE
        C:\PS> Invoke-CCMResetPolicy
            Reset the policy on the local machine and restarts CCMExec
    .NOTES
        FileName:    Invoke-CCMResetPolicy.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2019-10-30
        Updated:     2020-01-11
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Purge', 'ForceFull')]
        [string]$ResetType = 'Purge',
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
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
        $invokeCIMPowerShellSplat = @{
            FunctionsToLoad = 'Invoke-CCMResetPolicy'
        }
        $ConnectionSplat = @{ }
    }
    process {
        foreach ($Connection in (Get-Variable -Name $PSCmdlet.ParameterSetName -ValueOnly)) {
            $Computer = switch ($PSCmdlet.ParameterSetName) {
                'ComputerName' {
                    Write-Output -InputObject $Connection
                    switch ($Connection -eq $env:ComputerName) {
                        $false {
                            if ($ExistingCimSession = Get-CimSession -ComputerName $Connection -ErrorAction Ignore) {
                                Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
                                $ConnectionSplat.Remove('ComputerName')
                                $ConnectionSplat['CimSession'] = $ExistingCimSession
                            }
                            else {
                                Write-Verbose "No active CimSession found for $Connection - falling back to -ComputerName parameter for CIM cmdlets"
                                $ConnectionSplat.Remove('CimSession')
                                $ConnectionSplat['ComputerName'] = $Connection
                            }
                        }
                        $true {
                            $ConnectionSplat.Remove('CimSession')
                            $ConnectionSplat.Remove('ComputerName')
                            Write-Verbose 'Local computer is being queried - skipping computername, and cimsession parameter'
                        }
                    }
                }
                'CimSession' {
                    Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
                    Write-Output -InputObject $Connection.ComputerName
                    $ConnectionSplat.Remove('ComputerName')
                    $ConnectionSplat['CimSession'] = $Connection
                }
            }
            $Result = [System.Collections.Specialized.OrderedDictionary]::new()
            $Result['ComputerName'] = $Computer
            $Result['PolicyReset'] = $false
            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [ResetType = '$ResetType']", "Reset CCM Policy")) {
                try {
                    $Invocation = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Invoke-CimMethod @policyResetSplat
                        }
                        $false {
                            $invokeCIMPowerShellSplat['ScriptBlock'] = [scriptblock]::Create([string]::Format('Invoke-CCMResetPolicy -ResetType {0}', $ResetType))
                            Invoke-CIMPowerShell @invokeCIMPowerShellSplat @ConnectionSplat
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