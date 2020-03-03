function Set-CCMLoggingConfiguration {
    <#
        .SYNOPSIS
            Set ConfigMgr client log configuration from computers via CIM
        .DESCRIPTION
            This function will allow you to set the ConfigMgr client log configuration for multiple computers using CIM queries.
            You can provide an array of computer names, or cimsessions, or you can pass them through the pipeline.
        .PARAMETER LogLocation
            The location of MEMCM log files. Setting this will not take complete affect until the CCMExec service is restarted.
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
        .PARAMETER PSSession
            Provides PSSession to set log configuration for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
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
            Updated:     2020-03-03
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateScript( { Test-Path -Path $_ -PathType Container -ErrorAction Stop } )]
        [string]$LogLocation,
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
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [Alias('Session')]      
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession,
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [ValidateSet('CimSession', 'PSSession')]
        [string]$ConnectionPreference
    )
    begin {
        $setLogConfigSplat = @{
            Namespace   = 'root\ccm'
            ClassName   = 'SMS_Client'
            MethodName  = 'SetGlobalLoggingConfiguration'
            ErrorAction = 'Stop'
        }

        $SetLogLocationSplat = @{
            Force        = $true
            PropertyType = 'String'
            Property     = 'LogDirectory'
            Value        = $LogLocation
            Key          = 'SOFTWARE\Microsoft\CCM\Logging\@Global'
            RegRoot      = 'HKEY_LOCAL_MACHINE'
        }

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

        $LogConfigArgs = @{ }
        switch ($PSBoundParameters.Keys) {
            'LogLevel' {
                $LogConfigArgs['LogLevel'] = [uint32]$LogLevelInt
            }
            'LogMaxSize' {
                $LogConfigArgs['LogMaxSize'] = [uint32]$LogMaxSize
            }
            'LogMaxHistory' {
                $LogConfigArgs['LogMaxHistory'] = [uint32]$LogMaxHistory
            }
            'DebugLogging' {
                $LogConfigArgs['DebugLogging'] = [bool]$DebugLogging
            }
        }
        $setLogConfigSplat['Arguments'] = $LogConfigArgs
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

            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [LogLevel = '$LogLevel'] [LogMaxSize = '$LogMaxSize'] [LoxMaxHistory = '$LoxMaxHistory'] [DebugLogging = '$DebugLogging']", "Set-CCMLoggingConfiguration")) {
                $Result = [ordered]@{ }
                $Result['ComputerName'] = $Computer
                $Result['LogConfigChanged'] = $false

                try {
                    $LogConfigChanged = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Invoke-CimMethod @setLogConfigSplat
                        }
                        $false {
                            $invokeCommandSplat = @{
                                ArgumentList = $setLogConfigSplat
                                ScriptBlock  = {
                                    param($setLogConfigSplat)
                                    Invoke-CimMethod @setLogConfigSplat
                                }
                            }
                            Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                        }
                    }
                    if ($LogConfigChanged) {
                        Write-Verbose "Successfully configured log options on $Computer via the 'SetGlobalLoggingConfiguration' CIM method"
                        $Result['LogConfigChanged'] = $true
                    }
                    switch ($PSBoundParameters.ContainsKey('LogLocation')) {
                        $true {
                            $LogLocationChanged = Set-CCMRegistryProperty @SetLogLocationSplat @connectionSplat
                            Write-Warning "The CCMExec service needs restarted for log location changes to take full affect."
                            $Result['LogLocationChanged'] = $LogLocationChanged[$Computer]
                        }
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