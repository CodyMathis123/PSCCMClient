function Get-CCMMaintenanceWindow {
    <#
    .SYNOPSIS
        Get ConfigMgr Maintenance Window information from computers via WMI
    .DESCRIPTION
        This function will allow you to gather maintenance window information from multiple computers using WMI queries. You can provide an array of computer names,
        or you can pass them through the pipeline. You are also able to specify the Maintenance Window Type (MWType) you wish to query for, and pass credentials.
    .PARAMETER ComputerName
        Provides computer names to gather MW info from.
    .PARAMETER MWType
        Specifies the types of MW you want information for. Valid options are below
            'All Deployment Service Window',
            'Program Service Window',
            'Reboot Required Service Window',
            'Software Update Service Window',
            'Task Sequences Service Window',
            'Corresponds to non-working hours'
    .PARAMETER Credential
        Provides optional credentials to use for the WMI cmdlets.
    .EXAMPLE
        C:\PS> Get-CCMMaintenanceWindow
            Return all the 'All Deployment Service Window', 'Software Update Service Window' Maintenance Windows for the local computer. These are the two default MW types
            that the function looks for
    .EXAMPLE
        C:\PS> Get-CCMMaintenanceWindow -ComputerName 'Workstation1234','Workstation4321' -MWType 'Software Update Service Window'
            Return all the 'Software Update Service Window' Maintenance Windows for Workstation1234, and Workstation4321
    .NOTES
        FileName:    Get-CCMMaintenanceWindow.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2019-08-14
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
        [string[]]$MWType = @('All Deployment Service Window', 'Software Update Service Window'),
        [parameter(Mandatory = $false)]
        [pscredential]$Credential
    )
    begin {
        #region Create hashtable for mapping MW types, and create WMI filter based on input params
        $MW_Type = @{
            1	=	'All Deployment Service Window'
            2	=	'Program Service Window'
            3	=	'Reboot Required Service Window'
            4	=	'Software Update Service Window'
            5	=	'Task Sequences Service Window'
            6	=	'Corresponds to non-working hours'
        }

        $RequestedTypesRaw = foreach ($One in $MWType) {
            $MW_Type.Keys.Where( { $MW_Type[$_] -eq $One } )
        }
        $RequestedTypesFilter = [string]::Format('Type = {0}', [string]::Join(' OR Type =', $RequestedTypesRaw))
        #endregion Create hashtable for mapping MW types, and create WMI filter based on input params

        $getWmiObjectServiceWindowSplat = @{
            Namespace = 'root\CCM\ClientSDK'
            Class     = 'CCM_ServiceWindow'
            Filter    = $RequestedTypesFilter
        }
        $getWmiObjectTimeZoneSplat = @{
            Query = 'SELECT Caption FROM Win32_TimeZone'
        }
        if ($PSBoundParameters.ContainsKey('Credential')) {
            $getWmiObjectServiceWindowSplat['Credential'] = $Credential
            $getWmiObjectTimeZoneSplat['Credential'] = $Credential
        }
    }
    process {
        foreach ($Computer in $ComputerName) {
            $Result = [System.Collections.Specialized.OrderedDictionary]::new()
            $Result['ComputerName'] = $Computer
            $getWmiObjectServiceWindowSplat['ComputerName'] = $Computer
            $getWmiObjectTimeZoneSplat['ComputerName'] = $Computer

            try {
                $Result['TimeZone'] = (Get-WmiObject @getWmiObjectTimeZoneSplat ).Caption

                [System.Management.ManagementObject[]]$ServiceWindows = Get-WmiObject @getWmiObjectServiceWindowSplat
                if ($ServiceWindows -is [Object] -and $ServiceWindows.Count -gt 0) {
                    foreach ($ServiceWindow in $ServiceWindows) {
                        $Result['StartTime'] = [System.Management.ManagementDateTimeConverter]::ToDateTime($ServiceWindow.StartTime).ToUniversalTime()
                        $Result['EndTime'] = [System.Management.ManagementDateTimeConverter]::ToDateTime($ServiceWindow.EndTime).ToUniversalTime()
                        $Result['Duration'] = $ServiceWindow.Duration
                        $Result['MWID'] = $ServiceWindow.ID
                        $Result['Type'] = $MW_Type.Item([int]$($ServiceWindow.Type))
                        [PSCustomObject]$Result
                    }
                }
                else {
                    $Result['StartTime'] = $null
                    $Result['EndTime'] = $null
                    $Result['Duration'] = $null
                    $Result['MWID'] = $null
                    $Result['Type'] = "No ServiceWindow of type(s) $($RequestedTypesRaw -join ', ')"
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