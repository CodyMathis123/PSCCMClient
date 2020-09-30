function Get-CCMSoftwareUpdateSettings {
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param(
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
        $getSoftwareUpdateSettingsSplat = @{
            Namespace = 'root\CCM\Policy\Machine\ActualConfig'
            Query     = 'SELECT * FROM CCM_SoftwareUpdatesClientConfig'
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

            [ciminstance[]]$Settings = switch ($Computer -eq $env:ComputerName) {
                $true {
                    Get-CimInstance @getSoftwareUpdateSettingsSplat @connectionSplat
                }
                $false {
                    Get-CCMCimInstance @getSoftwareUpdateSettingsSplat @connectionSplat
                }
            }
            if ($Settings -is [Object] -and $Settings.Count -gt 0) {
                foreach ($Setting in $Settings) {
                    $Result['ComponentName'] = $Setting.ComponentName
                    $Result['Enabled'] = $Setting.Enabled
                    $Result['WUfBEnabled'] = $Setting.WUfBEnabled
                    $Result['EnableThirdPartyUpdates'] = $Setting.EnableThirdPartyUpdates
                    $Result['EnableExpressUpdates'] = $Setting.EnableExpressUpdates
                    $Result['ServiceWindowManagement'] = $Setting.ServiceWindowManagement
                    $Result['ReminderInterval'] = $Setting.ReminderInterval
                    $Result['DayReminderInterval'] = $Setting.DayReminderInterval
                    $Result['HourReminderInterval'] = $Setting.HourReminderInterval
                    $Result['AssignmentBatchingTimeout'] = $Setting.AssignmentBatchingTimeout
                    $Result['BrandingSubTitle'] = $Setting.BrandingSubTitle
                    $Result['BrandingTitle'] = $Setting.BrandingTitle
                    $Result['ContentDownloadTimeout'] = $Setting.ContentDownloadTimeout
                    $Result['ContentLocationTimeout'] = $Setting.ContentLocationTimeout
                    $Result['DynamicUpdateOption'] = $Setting.DynamicUpdateOption
                    $Result['ExpressUpdatesPort'] = $Setting.ExpressUpdatesPort
                    $Result['ExpressVersion'] = $Setting.ExpressVersion
                    $Result['GroupPolicyNotificationTimeout'] = $Setting.GroupPolicyNotificationTimeout
                    $Result['MaxScanRetryCount'] = $Setting.MaxScanRetryCount
                    $Result['NEOPriorityOption'] = $Setting.NEOPriorityOption
                    $Result['PerDPInactivityTimeout'] = $Setting.PerDPInactivityTimeout
                    $Result['ScanRetryDelay'] = $Setting.ScanRetryDelay
                    $Result['SiteSettingsKey'] = $Setting.SiteSettingsKey
                    $Result['TotalInactivityTimeout'] = $Setting.TotalInactivityTimeout
                    $Result['UserJobPerDPInactivityTimeout'] = $Setting.UserJobPerDPInactivityTimeout
                    $Result['UserJobTotalInactivityTimeout'] = $Setting.UserJobTotalInactivityTimeout
                    $Result['WSUSLocationTimeout'] = $Setting.WSUSLocationTimeout
                    $Result['Reserved1'] = $Setting.Reserved1
                    $Result['Reserved2'] = $Setting.Reserved2
                    $Result['Reserved3'] = $Setting.Reserved3
                    [pscustomobject]$Result
                }
            }
        }
    }
}