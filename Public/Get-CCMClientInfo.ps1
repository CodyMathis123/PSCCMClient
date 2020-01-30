function Get-CCMClientInfo {
    <#
    .SYNOPSIS
        Returns info about the MEMCM Client
    .DESCRIPTION
        This function will return a large amount of info for the MEMCM client using CIM. It leverages many of the existing Get-CCM* functions
        in the module to present the data as one object.
    .PARAMETER CimSession
        Provides CimSessions to gather the client info from
    .PARAMETER ComputerName
        Provides computer names to gather the client info from
    .EXAMPLE
        C:\PS> Get-CCMClientInfo
            Returns the client info from local computer
    .EXAMPLE
        C:\PS> Get-CCMClientInfo -ComputerName 'Workstation1234','Workstation4321'
            Returns the client info from Workstation1234, and Workstation4321
    .NOTES
        FileName:    Get-CCMClientInfo.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-01-24
        Updated:     2020-01-24
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        $connectionSplat = @{ }
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

            # ENHANCE - Decide on an order for the properties

            $Result = [System.Collections.Specialized.OrderedDictionary]::new()
            $Result['ComputerName'] = $Computer

            #region cache info
            $CacheInfo = Get-CCMCacheInfo @connectionSplat
            $Result['CacheLocation'] = $CacheInfo.Location
            $Result['CacheSize'] = $CacheInfo.Size
            #endregion cache info

            #region MEMCM Client Directory
            $Result['ClientDirectory'] = (Get-CCMClientDirectory @connectionSplat).ClientDirectory
            #endregion MEMCM Client Directory
                                    
            #region DNS Suffix
            $Result['DNSSuffix'] = (Get-CCMDNSSuffix @connectionSplat).DNSSuffix
            #endregion DNS Suffix

            #region MEMCM Client GUID
            $GUIDInfo = Get-CCMGUID @connectionSplat
            $Result['GUID'] = $GUIDInfo.GUID
            $Result['ClientGUIDChangeDate'] = $GUIDInfo.ClientGUIDChangeDate
            $Result['PreviousGUID'] = $GUIDInfo.PreviousGUID
            #endregion MEMCM Client GUID

            #region MEMCM Client Version
            $Result['ClientVersion'] = (Get-CCMClientVersion @connectionSplat).ClientVersion
            #endregion MEMCM Client Version

            #region Last Heartbeat Cycle
            $LastHeartbeat = Get-CCMLastSoftwareInventory @connectionSplat
            $Result['DDR-LastCycleStartedDate'] = $LastHeartbeat.LastCycleStartedDate
            $Result['DDR-LastReportDate'] = $LastHeartbeat.LastReportDate
            $Result['DDR-LastMajorReportVersion'] = $LastHeartbeat.LastMajorReportVersion
            $Result['DDR-LastMinorReportVersion'] = $LastHeartbeat.LastMinorReportVersion
            #endregion Last Heartbeat Cycle

            #region Last Hardware Inventory Cycle
            $LastHardwareInventory = Get-CCMLastHardwareInventory @connectionSplat
            $Result['HINV-LastCycleStartedDate'] = $LastHardwareInventory.LastCycleStartedDate
            $Result['HINV-LastReportDate'] = $LastHardwareInventory.LastReportDate
            $Result['HINV-LastMajorReportVersion'] = $LastHardwareInventory.LastMajorReportVersion
            $Result['HINV-LastMinorReportVersion'] = $LastHardwareInventory.LastMinorReportVersion
            #endregion Last Hardware Inventory Cycle

            #region Last Software Inventory Cycle
            $LastSoftwareInventory = Get-CCMLastSoftwareInventory @connectionSplat
            $Result['SINV-LastCycleStartedDate'] = $LastSoftwareInventory.LastCycleStartedDate
            $Result['SINV-LastReportDate'] = $LastSoftwareInventory.LastReportDate
            $Result['SINV-LastMajorReportVersion'] = $LastSoftwareInventory.LastMajorReportVersion
            $Result['SINV-LastMinorReportVersion'] = $LastSoftwareInventory.LastMinorReportVersion
            #endregion Last Software Inventory Cycle

            #region Current Management Point
            $Result['CurrentManagementPoint'] = (Get-CCMCurrentManagementPoint @connectionSplat).CurrentManagementPoint
            $Result['CurrentSoftwareUpdatePoint'] = (Get-CCMCurrentSoftwareUpdatePoint @connectionSplat).CurrentSoftwareUpdatePoint
            #endregion Current Management Point

            #region MEMCM Client Log Configuration
            $LogConfiguration = Get-CCMLoggingConfiguration @connectionSplat
            $Result['LogDirectory'] = $LogConfiguration.LogDirectory
            $Result['LogMaxSize'] = $LogConfiguration.LogMaxSize
            $Result['LogMaxHistory'] = $LogConfiguration.LogMaxHistory
            $Result['LogLevel'] = $LogConfiguration.LogLevel
            $Result['LogEnabled'] = $LogConfiguration.LogEnabled
            #endregion MEMCM Client Log Configuration

            #region MEMCM Client internet configuration
            $Result['IsClientOnInternet'] = (Test-CCMIsClientOnInternet @connectionSplat).IsClientOnInternet
            $Result['IsClientAlwaysOnInternet'] = (Test-CCMIsClientAlwaysOnInternet @connectionSplat).IsAlwaysClientOnInternet
            #endregion MEMCM Client internet configuration

            [pscustomobject]$Result
        }
    }
}