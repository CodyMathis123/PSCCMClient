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
        .PARAMETER PSSession
            Provides PSSession to reset log configuration for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the funtion. This is ultimately going to result in the function running faster. The typicaly usecase is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determins what type of connection / command
            the ComputerName paramter is passed to.
        .EXAMPLE
            C:\PS> Reset-CCMLoggingConfiguration
                Resets local computer client logging configuration
        .NOTES
            FileName:    Reset-CCMLoggingConfiguration.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-11
            Updated:     2020-02-23
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession,
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [ValidateSet('CimSession', 'PSSession')]
        [string]$ConnectionPreference
    )
    begin {
        $resetLogConfigSplat = @{
            Namespace   = 'root\ccm'
            ClassName   = 'SMS_Client'
            MethodName  = 'ResetGlobalLoggingConfiguration'
            ErrorAction = 'Stop'
        }
        $invokeCommandSplat = @{
            FunctionsToLoad = 'Reset-CCMLoggingConfiguration', 'Get-CCMConnection'
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
            $Result['LogConfigChanged'] = $false
            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer']", "Reset-CCMLoggingConfiguration")) {
                try {
                    $Invocation = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Invoke-CimMethod @resetLogConfigSplat
                        }
                        $false {

                            $invokeCommandSplat['ScriptBlock'] = [scriptblock]::Create('Reset-CCMLoggingConfiguration')
                            Invoke-CCMCommand @invokeCommandSplat @connectionSplat
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