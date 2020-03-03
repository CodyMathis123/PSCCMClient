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
        .PARAMETER PSSession
            Provides PSSessions to gather the client info from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
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
            Updated:     2020-03-03
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
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

            # ENHANCE - Decide on an order for the properties

            $Result = [ordered]@{ }
            $Result['ComputerName'] = $Computer

            #region site code
            $SiteCode = Get-CCMSite @connectionSplat
            $Result['SiteCode'] = $SiteCode.SiteCode
            #endregion site code

            #region Current Management Point
            $Result['CurrentManagementPoint'] = (Get-CCMCurrentManagementPoint @connectionSplat).CurrentManagementPoint
            $Result['CurrentSoftwareUpdatePoint'] = (Get-CCMCurrentSoftwareUpdatePoint @connectionSplat).CurrentSoftwareUpdatePoint
            #endregion Current Management Point

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

            #region MEMCM Client Log Configuration
            $LogConfiguration = Get-CCMLoggingConfiguration @connectionSplat
            $Result['LogDirectory'] = $LogConfiguration.LogDirectory
            $Result['LogMaxSize'] = $LogConfiguration.LogMaxSize
            $Result['LogMaxHistory'] = $LogConfiguration.LogMaxHistory
            $Result['LogLevel'] = $LogConfiguration.LogLevel
            $Result['LogEnabled'] = $LogConfiguration.LogEnabled
            #endregion MEMCM Client Log Configuration

            #region MEMCM Client internet configuration
            $Result['IsClientOnInternet'] = (Test-CCMIsClientOnInternet @connectionSplat).IsClientOnInternet[0]
            $Result['IsClientAlwaysOnInternet'] = (Test-CCMIsClientAlwaysOnInternet @connectionSplat).IsClientAlwaysOnInternet[0]
            #endregion MEMCM Client internet configuration

            [pscustomobject]$Result
        }
    }
}