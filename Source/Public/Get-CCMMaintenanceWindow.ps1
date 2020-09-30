function Get-CCMMaintenanceWindow {
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CCMMW')]
    param (
        [parameter(Mandatory = $false)]
        [ValidateSet('All Deployment Service Window',
            'Program Service Window',
            'Reboot Required Service Window',
            'Software Update Service Window',
            'Task Sequences Service Window',
            'Corresponds to non-working hours')]
        [string[]]$MWType = @('All Deployment Service Window', 'Software Update Service Window'),
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
        $MW_Type = @{
            1	=	'All Deployment Service Window'
            2	=	'Program Service Window'
            3	=	'Reboot Required Service Window'
            4	=	'Software Update Service Window'
            5	=	'Task Sequences Service Window'
            6	=	'Corresponds to non-working hours'
        }

        $RequestedTypesRaw = $MW_Type.Keys.Where( { $MW_Type[$_] -in $MWType } )
        $RequestedTypesFilter = [string]::Format('Type = {0}', [string]::Join(' OR Type =', $RequestedTypesRaw))
        #endregion Create hashtable for mapping MW types, and create CIM filter based on input params

        $getMaintenanceWindowSplat = @{
            Namespace = 'root\CCM\ClientSDK'
            ClassName = 'CCM_ServiceWindow'
            Filter    = $RequestedTypesFilter
        }
        $getTimeZoneSplat = @{
            Query = 'SELECT Caption FROM Win32_TimeZone'
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
                $TZ = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getTimeZoneSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getTimeZoneSplat @connectionSplat
                    }
                }
                $Result['TimeZone'] = $TZ.Caption

                [ciminstance[]]$ServiceWindows = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getMaintenanceWindowSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getMaintenanceWindowSplat @connectionSplat
                    }
                }

                if ($ServiceWindows -is [Object] -and $ServiceWindows.Count -gt 0) {
                    foreach ($ServiceWindow in $ServiceWindows) {
                        $Result['StartTime'] = ($ServiceWindow.StartTime).ToUniversalTime()
                        $Result['EndTime'] = ($ServiceWindow.EndTime).ToUniversalTime()
                        $Result['Duration'] = $ServiceWindow.Duration
                        $Result['DurationDescription'] = Get-StringFromTimespan -Seconds $ServiceWindow.Duration
                        $Result['MWID'] = $ServiceWindow.ID
                        $Result['Type'] = $MW_Type.Item([int]$($ServiceWindow.Type))
                        [PSCustomObject]$Result
                    }
                }
                else {
                    $Result['StartTime'] = $null
                    $Result['EndTime'] = $null
                    $Result['Duration'] = $null
                    $Result['DurationDescription'] = $null
                    $Result['MWID'] = $null
                    $Result['Type'] = "No ServiceWindow of type(s) $([string]::Join(', ',$RequestedTypesRaw))"
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