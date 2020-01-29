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
    .EXAMPLE
        PS C:\> Get-CCMSoftwareUpdateSettings -Computer Testing123
            Will return all software update settings deployed to Testing123
    .NOTES
        FileName:    Get-CCMSoftwareUpdateSettings.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-01-29
        Updated:     2020-01-29
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param(
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {

        $connectionSplat = @{ }
        $getSoftwareUpdateSettingsSplat = @{
            Namespace = 'root\CCM\Policy\Machine\ActualConfig'
            Query     = 'SELECT * FROM CCM_SoftwareUpdatesClientConfig'
        }
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
                                $ConnectionSplat.Remove('ComputerName')
                                $ConnectionSplat['CimSession'] = $ExistingCimSession
                            }
                            else {
                                Write-Verbose "No active CimSession found for $Connection - falling back to -ComputerName parameter for CIM cmdlets"
                                $ConnectionSplat.Remove('CimSession')
                                $ConnectionSplat['ComputerName'] = $Connection
                            }
                        }
                        $true {
                            $ConnectionSplat.Remove('CimSession')
                            $ConnectionSplat.Remove('ComputerName')
                            Write-Verbose 'Local computer is being queried - skipping computername, and cimsession parameter'
                        }
                    }
                }
                'CimSession' {
                    Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
                    Write-Output -InputObject $Connection.ComputerName
                    $ConnectionSplat.Remove('ComputerName')
                    $ConnectionSplat['CimSession'] = $Connection
                }
            }
            $Result = [System.Collections.Specialized.OrderedDictionary]::new()
            $Result['ComputerName'] = $Computer

            [ciminstance[]]$Settings = Get-CimInstance @getSoftwareUpdateSettingsSplat @ConnectionSplat
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