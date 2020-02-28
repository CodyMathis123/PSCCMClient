function Get-CCMServiceWindow {
    <#
        .SYNOPSIS
            Get ConfigMgr Service Window information from computers via CIM
        .DESCRIPTION
            This function will allow you to gather Service Window information from multiple computers using CIM queries. Note that 'ServiceWindows' are object
            that describe the schedule for a maintenance window, such as the recurrence, and date / time information. You can provide an array of computer names,
            or you can pass them through the pipeline. You are also able to specify the Service Window Type (SWType) you wish to query for, and pass credentials.
            What is returned is the data from the 'ActualConfig' section of WMI on the computer. The data returned will include the 'schedules' as well as
            the schedule type. Note that the schedules are not really 'human readable' and can be passed into ConvertFrom-CCMSchedule to convert
            them into a readable object. This is the equivalent of the 'Convert-CMSchedule' cmdlet that is part of the SCCM PowerShell module, but
            it does not require the module and it is much faster.
        .PARAMETER SWType
            Specifies the types of SW you want information for. Valid options are below
                'All Deployment Service Window',
                'Program Service Window',
                'Reboot Required Service Window',
                'Software Update Service Window',
                'Task Sequences Service Window',
                'Corresponds to non-working hours'
        .PARAMETER CimSession
            Provides CimSessions to gather Service Window information info from
        .PARAMETER ComputerName
            Provides computer names to gather Service Window information info from
        .PARAMETER PSSession
            Provides PSSessions to gather Service Window information info from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the funtion. This is ultimately going to result in the function running faster. The typicaly usecase is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Get-CCMSchedule
                Return all the 'All Deployment Service Window', 'Software Update Service Window' Maintenance Windows for the local computer. These are the two default MW types
                that the function looks for
        .EXAMPLE
            C:\PS> Get-CCMSchedule -ComputerName 'Workstation1234','Workstation4321' -SWType 'Software Update Service Window'
                Return all the 'Software Update Service Window' Maintenance Windows for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMSchedule.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2019-12-12
            Updated:     2020-02-27
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
        [Alias('MWType')]
        [string[]]$SWType = @('All Deployment Service Window', 'Software Update Service Window'),
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
        #region Create hashtable for mapping MW types, and create CIM filter based on input params
        $SW_Type = @{
            1	=	'All Deployment Service Window'
            2	=	'Program Service Window'
            3	=	'Reboot Required Service Window'
            4	=	'Software Update Service Window'
            5	=	'Task Sequences Service Window'
            6	=	'Corresponds to non-working hours'
        }

        $RequestedTypesRaw = $SW_Type.Keys.Where( { $SW_Type[$_] -in $SWType } )

        $RequestedTypesFilter = [string]::Format('ServiceWindowType = {0}', [string]::Join(' OR ServiceWindowType =', $RequestedTypesRaw))
        #endregion Create hashtable for mapping MW types, and create CIM filter based on input params
        $getServiceWindowSplat = @{
            Namespace = 'root\CCM\Policy\Machine\ActualConfig'
            ClassName = 'CCM_ServiceWindow'
            Filter    = $RequestedTypesFilter
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

            try {
                [ciminstance[]]$ServiceWindows = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getServiceWindowSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getServiceWindowSplat @connectionSplat
                    }
                }
                if ($ServiceWindows -is [Object] -and $ServiceWindows.Count -gt 0) {
                    foreach ($ServiceWindow in $ServiceWindows) {
                        $Result['Schedules'] = $ServiceWindow.Schedules
                        $Result['ServiceWindowID'] = $ServiceWindow.ServiceWindowID
                        $Result['ServiceWindowType'] = $SW_Type.Item([int]$($ServiceWindow.ServiceWindowType))
                        [PSCustomObject]$Result
                    }
                }
                else {
                    $Result['Schedules'] = $null
                    $Result['ServiceWindowID'] = $null
                    $Result['ServiceWindowType'] = "No ServiceWindow of type(s) $([string]::Join(', ', $RequestedTypesRaw))"
                    [PSCustomObject]$Result
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}