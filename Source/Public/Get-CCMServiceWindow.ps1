function Get-CCMServiceWindow {
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