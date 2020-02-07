function Reset-CCMLoggingConfiguration {
    <#
    .SYNOPSIS
        Reset ConfigMgr client log configuration for computers via CIM
    .DESCRIPTION
        This function will allow you to reset the ConfigMgr client log configuration for multiple computers using CIM queries.
        You can provide an array of computer names, or cimsessions, or you can pass them through the pipeline.

        The reset will set the log director to <client install directory\logs, max log size to 250000 byes, log level to 1, and max log history to 1
    .PARAMETER CimSession
        Provides CimSession to reset log configuration for
    .PARAMETER ComputerName
        Provides computer names to reset log configuration for
    .EXAMPLE
        C:\PS> Reset-CCMLoggingConfiguration
            Resets local computer client logging configuration
    .NOTES
        FileName:    Reset-CCMLoggingConfiguration.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-01-11
        Updated:     2020-01-18
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        $resetLogConfigSplat = @{
            Namespace   = 'root\ccm'
            ClassName   = 'SMS_Client'
            MethodName  = 'ResetGlobalLoggingConfiguration'
            ErrorAction = 'Stop'
        }
        $invokeCIMPowerShellSplat = @{
            FunctionsToLoad = 'Reset-CCMLoggingConfiguration'
        }
        $ConnectionSplat = @{ }
    }
    process {
        foreach ($Connection in (Get-Variable -Name $PSCmdlet.ParameterSetName -ValueOnly)) {
            $getConnectionInfoSplat = @{
                $PSCmdlet.ParameterSetName = $Connection
            }
            $ConnectionInfo = Get-CCMConnection @getConnectionInfoSplat
            $Computer = $ConnectionInfo.ComputerName
            $connectionSplat = $ConnectionInfo.connectionSplat
            $Result = [ordered]@{ }
            $Result['ComputerName'] = $Computer
            $Result['LogConfigChanged'] = $false
            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer']", "Reset-CCMLoggingConfiguration")) {
                try {
                    $Invocation = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Invoke-CimMethod @resetLogConfigSplat
                        }
                        $false {

                            $invokeCIMPowerShellSplat['ScriptBlock'] = [scriptblock]::Create('Reset-CCMLoggingConfiguration')
                            Invoke-CIMPowerShell @invokeCIMPowerShellSplat @ConnectionSplat
                        }
                    }
                    if ($Invocation) {
                        Write-Verbose "Successfully reset log options on $Computer via the 'ResetGlobalLoggingConfiguration' CIM method"
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