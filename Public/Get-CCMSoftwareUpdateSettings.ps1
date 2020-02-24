function Get-CCMSoftwareUpdateSettings {
    <#
        .SYNOPSIS
            Get software update settings for a computer
        .DESCRIPTION
            Uses CIM to find software update settings for a computer. This includes various configs
            that are set in the MEMCM Console Client Settings
        .PARAMETER CimSession
            Computer CimSession(s) which you want to get software update settings for
        .PARAMETER ComputerName
            Computer name(s) which you want to get software update settings for
        .PARAMETER PSSession
            PSSessions which you want to get software update settings for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the funtion. This is ultimately going to result in the function running faster. The typicaly usecase is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName paramter is passed to.
        .EXAMPLE
            PS C:\> Get-CCMSoftwareUpdateSettings -Computer Testing123
                Will return all software update settings deployed to Testing123
        .NOTES
            FileName:    Get-CCMSoftwareUpdateSettings.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-29
            Updated:     2020-02-23
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param(
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