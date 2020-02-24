function Get-CCMCurrentWindowAvailableTime {
    <#
        .SYNOPSIS
            Return the time left in the current window based on input.
        .DESCRIPTION
            This function uses the GetCurrentWindowAvailableTime method of the CCM_ServiceWindowManager CIM class. It will allow you to
            return the time left in the current window based on your input parameters.

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
        .PARAMETER CimSession
            Provides CimSession to gather Maintenance Window information info from
        .PARAMETER ComputerName
            Provides computer names to gather Maintenance Window information info from
        .PARAMETER PSSession
            Provides a PSSession to gather Maintenance Window information info from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the funtion. This is ultimately going to result in the function running faster. The typicaly usecase is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determins what type of connection / command
            the ComputerName paramter is passed to.
        .EXAMPLE
            C:\PS> Get-CCMCurrentWindowAvailableTime
                Return the available time fro the default MWType of 'Software Update Service Window' with fallback
                based on client settings and 'Software Update Service Window' availability.
        .EXAMPLE
            C:\PS> Get-CCMCurrentWindowAvailableTime -ComputerName 'Workstation1234','Workstation4321' -MWType 'Task Sequences Service Window'
                Return the available time left in a current 'Task Sequences Service Window' for 'Workstation1234','Workstation4321'
        .NOTES
            FileName:    Get-CCMCurrentWindowAvailableTime.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-02-01
            Updated:     2020-02-23
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
        [bool]$FallbackToAllProgramsWindow,
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

        $getCurrentWindowTimeLeft = @{
            Namespace  = 'root\CCM\ClientSDK'
            ClassName  = 'CCM_ServiceWindowManager'
            MethodName = 'GetCurrentWindowAvailableTime'
            Arguments  = @{ }
        }
        $getUpdateMWExistenceSplat = @{
            Namespace = 'root\CCM\ClientSDK'
            Query     = 'SELECT Duration FROM CCM_ServiceWindow WHERE Type = 4'
        }
        $getSoftwareUpdateFallbackSettingsSplat = @{
            Namespace = 'root\CCM\Policy\Machine\ActualConfig'
            Query     = 'SELECT ServiceWindowManagement FROM CCM_SoftwareUpdatesClientConfig'
        }
        $invokeCommandSplat = @{
            FunctionsToLoad = 'Get-CCMCurrentWindowAvailableTime', 'Get-CCMConnection'
        }

        $StringArgs = @(switch ($PSBoundParameters.Keys) {
                'FallbackToAllProgramsWindow' {
                    [string]::Format('-FallbackToAllProgramsWindow ${0}', $FallbackToAllProgramsWindow)
                }
            })
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
                switch ($Computer -eq $env:ComputerName) {
                    $true {
                        $HasUpdateMW = $null -ne (Get-CimInstance @getUpdateMWExistenceSplat @connectionSplat).Duration
                        $FallbackSetting = (Get-CimInstance @getSoftwareUpdateFallbackSettingsSplat @connectionSplat).ServiceWindowManagement

                        foreach ($MW in $MWType) {
                            $MWFallback = switch ($FallbackToAllProgramsWindow) {
                                $true {
                                    switch ($MWType) {
                                        'Software Update Service Window' {
                                            switch ($FallbackSetting -ne $FallbackToAllProgramsWindow) {
                                                $true {
                                                    Write-Warning 'Requested fallback setting does not match the computers fallback setting for software updates'
                                                }
                                            }
                                            switch ($HasUpdateMW) {
                                                $true {
                                                    $FallbackSetting -and $HasUpdateMW
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
                                            switch ($HasUpdateMW) {
                                                $true {
                                                    $FallbackSetting -and $HasUpdateMW
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
                            $getCurrentWindowTimeLeft['Arguments']['FallbackToAllProgramsWindow'] = [bool]$MWFallback
                            $getCurrentWindowTimeLeft['Arguments']['ServiceWindowType'] = [uint32]$MW_Type[$MW]
                            $TimeLeft = Invoke-CimMethod @getCurrentWindowTimeLeft @connectionSplat
                            $TimeLeftTimeSpan = New-TimeSpan -Seconds $TimeLeft.WindowAvailableTime
                            $Result['MaintenanceWindowType'] = $MW
                            $Result['FallbackToAllProgramsWindow'] = $MWFallback
                            $Result['WindowAvailableTime'] = [string]::Format('{0} day(s) {1} hour(s) {2} minute(s) {3} second(s)', $TimeLeftTimeSpan.Days, $TimeLeftTimeSpan.Hours, $TimeLeftTimeSpan.Minutes, $TimeLeftTimeSpan.Seconds)
                            [pscustomobject]$Result
                        }
                    }
                    $false {
                        $ScriptBlock = [string]::Format('Get-CCMCurrentWindowAvailableTime {0} {1}', [string]::Join(' ', $StringArgs), [string]::Format("-MWType '{0}'", [string]::Join("', '", $MWType)))
                        $invokeCommandSplat['ScriptBlock'] = [scriptblock]::Create($ScriptBlock)
                        Invoke-CCMCommand @invokeCommandSplat @connectionSplat
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