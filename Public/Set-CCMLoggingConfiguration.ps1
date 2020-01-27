function Set-CCMLoggingConfiguration {
    <#
    .SYNOPSIS
        Set ConfigMgr client log configuration from computers via CIM
    .DESCRIPTION
        This function will allow you to set the ConfigMgr client log configuration for multiple computers using CIM queries.
        You can provide an array of computer names, or cimsessions, or you can pass them through the pipeline.
    .PARAMETER LogLevel
        Preferred logging level, either Default, or Verbose
    .PARAMETER LogMaxSize
        Maximum log size in Bytes
    .PARAMETER LogMaxHistory
        Max number of logs to retain
    .PARAMETER DebugLogging
        Set debug logging to on, or off
    .PARAMETER CimSession
        Provides CimSession to set log configuration for
    .PARAMETER ComputerName
        Provides computer names to set log configuration for
    .EXAMPLE
        C:\PS> Set-CCMLoggingConfiguration -LogLevel Verbose
            Sets local computer to use Verbose logging
    .EXAMPLE
        C:\PS> Set-CCMLoggingConfiguration -ComputerName 'Workstation1234','Workstation4321' -LogMaxSize 8192000 -LogMaxHistory 2
            Configure the client to have a max log size of 8mb and retain 2 log files for Workstation1234, and Workstation4321
    .NOTES
        FileName:    Set-CCMLoggingConfiguration.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-01-11
        Updated:     2020-01-25
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Default', 'Verbose', 'None')]
        [string]$LogLevel,
        [Parameter(Mandatory = $false)]
        [int]$LogMaxSize,
        [Parameter(Mandatory = $false)]
        [int]$LogMaxHistory,
        [Parameter(Mandatory = $false)]
        [bool]$DebugLogging,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        $setLogConfigSplat = @{
            Namespace   = 'root\ccm'
            ClassName   = 'SMS_Client'
            MethodName  = 'SetGlobalLoggingConfiguration'
            ErrorAction = 'Stop'
        }
        $invokeCIMPowerShellSplat = @{
            FunctionsToLoad = 'Set-CCMLoggingConfiguration'
        }
        $ConnectionSplat = @{ }
        $LogConfigArgs = @{ }
        $LogLevelInt = switch ($LogLevel) {
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
        $StringArgs = switch ($PSBoundParameters.Keys) {
            'LogLevel' {
                $LogConfigArgs['LogLevel'] = [uint32]$LogLevelInt
                [string]::Format('-LogLevel {0}', $LogLevel)
            }
            'LogMaxSize' {
                $LogConfigArgs['LogMaxSize'] = [uint32]$LogMaxSize
                [string]::Format('-LogMaxSize {0}', $LogMaxSize)
            }
            'LogMaxHistory' {
                $LogConfigArgs['LogMaxHistory'] = [uint32]$LogMaxHistory
                [string]::Format('-LogMaxHistory {0}', $LogMaxHistory)
            }
            'DebugLogging' {
                $LogConfigArgs['DebugLogging'] = [bool]$DebugLogging
                [string]::Format('-DebugLogging {0}', $DebugLogging)
            }
        }
        $setLogConfigSplat['Arguments'] = $LogConfigArgs
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
            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [LogLevel = '$LogLevel'] [LogMaxSize = '$LogMaxSize'] [LoxMaxHistory = '$LoxMaxHistory'] [DebugLogging = '$DebugLogging']", "Set-CCMLoggingConfiguration")) {
                $Result = [System.Collections.Specialized.OrderedDictionary]::new()
                $Result['ComputerName'] = $Computer
                $Result['LogConfigChanged'] = $false

                try {
                    $Invocation = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Invoke-CimMethod @setLogConfigSplat
                        }
                        $false {
                            $ScriptBlock = [string]::Format('Set-CCMLoggingConfiguration {0}', [string]::Join(' ', $StringArgs))
                            $invokeCIMPowerShellSplat['ScriptBlock'] = [scriptblock]::Create($ScriptBlock)
                            Invoke-CIMPowerShell @invokeCIMPowerShellSplat @ConnectionSplat
                        }
                    }
                    if ($Invocation) {
                        Write-Verbose "Successfully configured log options on $Computer via the 'SetGlobalLoggingConfiguration' CIM method"
                        $Result['LogConfigChanged'] = $true
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