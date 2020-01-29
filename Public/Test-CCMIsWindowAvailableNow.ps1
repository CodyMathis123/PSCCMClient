function Test-CCMIsWindowAvailableNow {
    <#
    .SYNOPSIS
        Determine if a window is available now for the provided runtime and MWType
    .DESCRIPTION
        This function uses the IsWindowAvailableNow method of the CCM_ServiceWindowManager CIM class. It will allow you to
        determine if a deployment will run based on your input parameters.

        It also will determine your client settings for software updates to appropriately fall back to an 'All Deployment Service Window'
        according to both your settings, and whether a 'Software Update Service Window' is available
    .PARAMETER MWType
        Specifies the types of MW you want information for. Defaults to 'Software Update Service Window'. Valid options are below
            'All Deployment Service Window',
            'Program Service Window',
            'Reboot Required Service Window',
            'Software Update Service Window',
            'Task Sequences Service Window',
            'Corresponds to non-working hours'
    .PARAMETER MaxRunTime
        The max run time (in seconds) that will be passed to the IsWindowAvailableNow method. This is defined for the
        applications, programs, and updates you deploy. For software updates, you would want the cumulative
        max run time of all updates in a SUG.
    .PARAMETER CimSession
        Provides CimSession to gather Maintenance Window information info from
    .PARAMETER ComputerName
        Provides computer names to gather Maintenance Window information info from
    .EXAMPLE
        C:\PS> Test-CCMIsWindowAvailableNow
            Return information about the default MWType of 'Software Update Service Window' with a runtime of 0, and fallback
            based on client settings and 'Software Update Service Window' availability.
    .EXAMPLE
        C:\PS> Test-CCMIsWindowAvailableNow -ComputerName 'Workstation1234','Workstation4321' -MWType 'Task Sequences Service Window' -MaxRunTime 3600
            Return information on whether a task sequence with a run time of 3600 seconds can currently run on 'Workstation1234','Workstation4321'
    .NOTES
        FileName:    Test-CCMIsWindowAvailableNow.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-01-29
        Updated:     2020-01-29
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
        [parameter(Mandatory = $false)]
        [ValidateSet('All Deployment Service Window',
            'Program Service Window',
            'Reboot Required Service Window',
            'Software Update Service Window',
            'Task Sequences Service Window',
            'Corresponds to non-working hours')]
        [string[]]$MWType = 'Software Update Service Window',
        [Parameter(Mandatory = $false)]
        [int]$MaxRuntime,
        [Parameter(Mandatory = $false)]
        [bool]$FallbackToAllProgramsWindow,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        $connectionSplat = @{ }
        #region Create hashtable for mapping MW types
        $MW_Type = @{
            'All Deployment Service Window'    = 1
            'Program Service Window'           = 2
            'Reboot Required Service Window'   = 3
            'Software Update Service Window'   = 4
            'Task Sequences Service Window'    = 5
            'Corresponds to non-working hours' = 6
        }
        #endregion Create hashtable for mapping MW types

        $getMWFallbackSplat = @{
            Namespace = 'root\CCM\Policy\Machine\ActualConfig'
            Query     = 'SELECT ServiceWindowManagement FROM CCM_SoftwareUpdatesClientConfig'
        }
        $testInMWSplat = @{
            Namespace  = 'root\CCM\ClientSDK'
            ClassName  = 'CCM_ServiceWindowManager'
            MethodName = 'IsWindowAvailableNow'
            Arguments  = @{
                MaxRuntime = [uint32]$MaxRuntime
            }
        }
        $getCurrentWindowTimeLeft = @{
            Namespace  = 'root\CCM\ClientSDK'
            ClassName  = 'CCM_ServiceWindowManager'
            MethodName = 'GetCurrentWindowAvailableTime'
            Arguments  = @{ }
        }
        $invokeCIMPowerShellSplat = @{
            FunctionsToLoad = 'Test-CCMIsWindowAvailableNow', 'Get-CCMMaintenanceWindow', 'Get-CCMSoftwareUpdateSettings'
        }

        $StringArgs = @(switch ($PSBoundParameters.Keys) {
                'MaxRuntime' {
                    [string]::Format('-MaxRuntime {0}', $MaxRuntime)
                }
                'FallbackToAllProgramsWindow' {
                    [string]::Format('-FallbackToAllProgramsWindow {0}', $FallbackToAllProgramsWindow)
                }
            })
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
                                $connectionSplat.Remove('ComputerName')
                                $connectionSplat['CimSession'] = $ExistingCimSession
                            }
                            else {
                                Write-Verbose "No active CimSession found for $Connection - falling back to -ComputerName parameter for CIM cmdlets"
                                $connectionSplat.Remove('CimSession')
                                $connectionSplat['ComputerName'] = $Connection
                            }
                        }
                        $true {
                            $connectionSplat.Remove('CimSession')
                            $connectionSplat.Remove('ComputerName')
                            Write-Verbose 'Local computer is being queried - skipping computername, and cimsession parameter'
                        }
                    }
                }
                'CimSession' {
                    Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
                    Write-Output -InputObject $Connection.ComputerName
                    $connectionSplat.Remove('ComputerName')
                    $connectionSplat['CimSession'] = $Connection
                }
            }
            $Result = [System.Collections.Specialized.OrderedDictionary]::new()
            $Result['ComputerName'] = $Computer

            try {
                switch ($Computer -eq $env:ComputerName) {
                    $true {
                        foreach ($MW in $MWType) {
                            $MWFallback = switch ($FallbackToAllProgramsWindow) {
                                $true {
                                    switch ($MWType) {
                                        'Software Update Service Window' {
                                            $Setting = (Get-CCMSoftwareUpdateSettings @connectionSplat).ServiceWindowManagement
                                            switch ($Setting -ne $FallbackToAllProgramsWindow) {
                                                $true {
                                                    Write-Warning 'Requested fallback setting does not match the computers fallback setting for software updates'
                                                }
                                            }
                                            $HasUpdateMW = $null -ne (Get-CCMMaintenanceWindow @connectionSplat -MWType 'Software Update Service Window').Duration
                                            switch ($HasUpdateMW) {
                                                $true {
                                                    $Setting -and $HasUpdateMW
                                                }
                                                $false {
                                                    $true
                                                }
                                            }
                                        }
                                        default {
                                            $FallbackToAllProgramsWindow
                                        }
                                    }
                                }
                                $false {
                                    switch ($MWType) {
                                        'Software Update Service Window' {
                                            $Setting = (Get-CimInstance @getMWFallbackSplat @connectionSplat).ServiceWindowManagement
                                            $HasUpdateMW = $null -ne (Get-CCMMaintenanceWindow @connectionSplat -MWType 'Software Update Service Window').Duration
                                            switch ($HasUpdateMW) {
                                                $true {
                                                    $Setting -and $HasUpdateMW
                                                }
                                                $false {
                                                    $true
                                                }
                                            }
                                        }
                                        default {
                                            $false
                                        }
                                    }
                                }
                            }
                            $testInMWSplat['Arguments']['FallbackToAllProgramsWindow'] = [bool]$MWFallback
                            $testInMWSplat['Arguments']['ServiceWindowType'] = [uint32]$MW_Type[$MW]
                            $CanProgramRunNow = Invoke-CimMethod @testInMWSplat @connectionSplat
                            if ($CanProgramRunNow -is [Object]) {
                                $getCurrentWindowTimeLeft['Arguments']['FallbackToAllProgramsWindow'] = [bool]$MWFallback
                                $getCurrentWindowTimeLeft['Arguments']['ServiceWindowType'] = [uint32]$MW_Type[$MW]
                                # ENHANCE - This should be a Get-CCMCurrentWindowAvailableTime function
                                $TimeLeft = Invoke-CimMethod @getCurrentWindowTimeLeft @connectionSplat
                                $TimeLeftTimeSpan = New-TimeSpan -Seconds $TimeLeft.WindowAvailableTime
                                $Result['MaintenanceWindowType'] = $MW
                                $Result['CanProgramRunNow'] = $CanProgramRunNow.CanProgramRunNow
                                $Result['FallbackToAllProgramsWindow'] = $MWFallback
                                $Result['MaxRunTime'] = $MaxRuntime
                                $Result['WindowAvailableTime'] = [string]::Format('{0} day(s) {1} hour(s) {2} minute(s) {3} second(s)', $TimeLeftTimeSpan.Days, $TimeLeftTimeSpan.Hours, $TimeLeftTimeSpan.Minutes, $TimeLeftTimeSpan.Seconds)
                                [pscustomobject]$Result
                            }
                        }
                    }
                    $false {
                        $ScriptBlock = [string]::Format('Test-CCMIsWindowAvailableNow {0} {1}', [string]::Join(' ', $StringArgs), [string]::Format("-MWType '{0}'", [string]::Join("', '", $MWType)))
                        $invokeCIMPowerShellSplat['ScriptBlock'] = [scriptblock]::Create($ScriptBlock)
                        Invoke-CIMPowerShell @invokeCIMPowerShellSplat @ConnectionSplat
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