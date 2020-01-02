function Get-CCMServiceWindow {
    <#
    .SYNOPSIS
        Get ConfigMgr Service Window information from computers via WMI
    .DESCRIPTION
        This function will allow you to gather Service Window information from multiple computers using WMI queries. You can provide an array of computer names,
        or you can pass them through the pipeline. You are also able to specify the Service Window Type (SWType) you wish to query for, and pass credentials.
        What is returned is the data from the 'ActualConfig' section of WMI on the computer. The data returned will include the 'schedules' as well as
        the schedule type. Note that the schedules are not really 'human readable' and can be passed into ConvertFrom-CCMSchedule to convert
        them into a readable object. This is the equivalent of the 'Convert-CMSchedule' cmdlet that is part of the SCCM PowerShell module, but
        it does not require the module and it is much faster.
    .PARAMETER ComputerName
        Provides computer names to gather SW info from.
    .PARAMETER SWType
        Specifies the types of SW you want information for. Valid options are below
            'All Deployment Service Window',
            'Program Service Window',
            'Reboot Required Service Window',
            'Software Update Service Window',
            'Task Sequences Service Window',
            'Corresponds to non-working hours'
    .PARAMETER Credential
        Provides optional credentials to use for the WMI cmdlets.
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
        Updated:     2019-12-31
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
        [Alias('Computer', 'PSComputerName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [parameter(Mandatory = $false)]
        [ValidateSet('All Deployment Service Window',
            'Program Service Window',
            'Reboot Required Service Window',
            'Software Update Service Window',
            'Task Sequences Service Window',
            'Corresponds to non-working hours')]
        [Alias('MWType')]
        [string[]]$SWType = @('All Deployment Service Window', 'Software Update Service Window'),
        [parameter(Mandatory = $false)]
        [pscredential]$Credential
    )
    begin {
        #region Create hashtable for mapping MW types, and create WMI filter based on input params
        $SW_Type = @{
            1	=	'All Deployment Service Window'
            2	=	'Program Service Window'
            3	=	'Reboot Required Service Window'
            4	=	'Software Update Service Window'
            5	=	'Task Sequences Service Window'
            6	=	'Corresponds to non-working hours'
        }

        $RequestedTypesRaw = $SW_Type.Keys.Where( { $SW_Type[$_] -in $SW_Type } )

        $RequestedTypesFilter = [string]::Format('ServiceWindowType = {0}', [string]::Join(' OR ServiceWindowType =', $RequestedTypesRaw))
        #endregion Create hashtable for mapping MW types, and create WMI filter based on input params
        $getWmiObjectServiceWindowSplat = @{
            Namespace = 'root\CCM\Policy\Machine\ActualConfig'
            Class     = 'CCM_ServiceWindow'
            Filter    = $RequestedTypesFilter
        }
    }
    process {
        foreach ($Computer in $ComputerName) {
            $Result = [System.Collections.Specialized.OrderedDictionary]::new()
            $Result['ComputerName'] = $Computer
            $getWmiObjectServiceWindowSplat['ComputerName'] = $Computer

            try {
                [System.Management.ManagementObject[]]$ServiceWindows = Get-WmiObject @getWmiObjectServiceWindowSplat
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
                    $Result['ServiceWindowType'] = "No ServiceWindow of type(s) $($RequestedTypesRaw -join ', ')"
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