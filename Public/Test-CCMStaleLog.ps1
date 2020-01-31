Function Test-CCMStaleLog {
    <#
    .SYNOPSIS
        Returns a boolean based on whether a log file has been written to in the timeframe specified
    .DESCRIPTION
        This function is used to check the LastWriteTime property of a specified file. It will be compared to
        the *Stale parameters. Note that logs are assumed to be under the MEMCM Log directory. Note that
        this function uses the CIM_DataFile so that SMB is NOT needed. Get-CimInstance is able to query for
        file information.
    .PARAMETER LogFileName
        Name of the log file under the CCM\Logs directory to check. Not, online the log name is required. The path for the MEMCM logs
        will be automatically identified. The .log extension is optional
    .PARAMETER DaysStale
        Number of days of inactivity that you would consider the specified log stale.
    .PARAMETER HoursStale
        Number of days of inactivity that you would consider the specified log stale.
    .PARAMETER MinutesStale
        Number of minutes of inactivity that you would consider the specified log stale.
    .PARAMETER DisableCCMSetupFallback
        Disable the CCMSetup fallback check - details below.

        When the desired log file is not found, then the last modified timestamp for the CCMSetup log is checked.
        When the CCMSetup file has activity within the last 24 hours, then we assume that, even though our desired
        log file was not found, it isn't stale because the MEMCM client is recently installed or repaired.
        If the CCMSetup is found, and has no activity, or is just not found, then we assume the desired
        log is 'stale.' This additional chack can be disabled with this switch parameter.
    .EXAMPLE
        C:\PS> Test-CCMStaleLog -LogFileName ccmexec -DaysStale 2
            Check if the ccmexec log file has been written to within the last 2 days on the local computer
    .EXAMPLE
        C:\PS> Test-CCMStaleLog -LogFileName AppDiscovery.log -DaysStale 7 -ComputerName Workstation123
            Check if the AppDiscovery.log file has been written to within the last 7 days on Workstation123
    .NOTES
        FileName:    Test-CCMStaleLog.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-01-25
        Updated:     2020-01-26
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$LogFileName,
        [Parameter(Mandatory = $false)]
        [int]$DaysStale,
        [Parameter(Mandatory = $false)]
        [int]$HoursStale,
        [Parameter(Mandatory = $false)]
        [int]$MinutesStale,
        [Parameter(Mandatory = $false)]
        [switch]$DisableCCMSetupFallback,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        $connectionSplat = @{ }

        $getRequestedLogInfoSplat = @{ }

        $TimeSpanSplat = @{ }
        switch ($PSBoundParameters.Keys) {
            'DaysStale' {
                $TimeSpanSplat['Days'] = $DaysStale
            }
            'HoursStale' {
                $TimeSpanSplat['Hours'] = $HoursStale
            }
            'MinutesStale' {
                $TimeSpanSplat['Minutes'] = $MinutesStale
            }
        }
        $StaleTimeframe = New-TimeSpan @TimeSpanSplat

        switch ($LogFileName.EndsWith('.log')) {
            $false {
                $LogFileName = [string]::Format('{0}.log', $LogFileName)
            }
        }

        $MEMCMClientInstallLog = "$env:windir\ccmsetup\Logs\ccmsetup.log"
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
            $Result = [System.Collections.Specialized.OrderedDictionary]::new()
            $Result['ComputerName'] = $Computer
            $Result['LogFileName'] = $LogFileName
            $Result['LogLastWriteTime'] = $null
            $Result['LogStale'] = $null
            $Result['CCMSetupLastWriteTime'] = $null
            $CCMLogDirectory = (Get-CCMLoggingConfiguration @connectionSplat).LogDirectory
            $LogFullPath = [string]::Join('\', $CCMLogDirectory, $LogFileName)

            Write-Verbose $([string]::Format('Checking {0} for activity', $LogFullPath))

            $getRequestedLogInfoSplat['Query'] = [string]::Format('SELECT Readable, LastModified FROM CIM_DataFile WHERE Name = "{0}"', ($LogFullPath -replace "\\", "\\"))
            # 'Poke' the log by querying it once. Log files sometimes do not show an accurate LastModified time until they are accessed
            $null = Get-CimInstance @getRequestedLogInfoSplat @connectionSplat
            $RequestedLogInfo = Get-CimInstance @getRequestedLogInfoSplat @connectionSplat

            $getRequestedLogInfoSplat['Query'] = [string]::Format('SELECT Readable, LastModified FROM CIM_DataFile WHERE Name = "{0}"', ($MEMCMClientInstallLog -replace "\\", "\\"))
            # 'Poke' the log by querying it once. Log files sometimes do not show an accurate LastModified time until they are accessed
            $null = Get-CimInstance @getRequestedLogInfoSplat @connectionSplat
            $MEMCMClientInstallLogInfo = Get-CimInstance @getRequestedLogInfoSplat @connectionSplat
            
            if ($null -ne $MEMCMClientInstallLogInfo) {
                $Result['CCMSetupLastWriteTime'] = ([datetime]$dtmMEMCMClientInstallLogDate = $MEMCMClientInstallLogInfo.LastModified)
            }
            if ($null -ne $RequestedLogInfo) {
                $Result['LogLastWriteTime'] = ([datetime]$LogLastWriteTime = $RequestedLogInfo.LastModified)
                $LastWriteDiff = New-TimeSpan -Start $LogLastWriteTime -End (Get-Date -format yyyy-MM-dd)
                if ($LastWriteDiff -gt $StaleTimeframe) {
                    Write-Verbose $([string]::Format('{0} is not active', $LogFullPath))
                    Write-Verbose $([string]::Format('{0} last date modified is {1}', $LogFullPath, $LogDate))
                    Write-Verbose $([string]::Format("Current Date and Time is {0}", (Get-Date)))
                    $LogStale = $true
                }
                else {
                    Write-Verbose $([string]::Format('{0}.log is active', $LogFullPath))
                    $LogStale = $false
                }
            }
            elseif (-not $DisableCCMSetupFallback.IsPresent) {
                Write-Warning $([string]::Format('{0} not found; checking for recent ccmsetup activity', $LogFullPath))
                if ($null -ne $MEMCMClientInstallLogInfo) {
                    [int]$ClientInstallHours = (New-TimeSpan -Start $dtmMEMCMClientInstallLogDate -End (Get-Date)).TotalHours
                    if ($ClientInstallHours -lt 24) {
                        Write-Warning 'CCMSetup activity detected within last 24 hours - marking log as not stale'
                        $LogStale = $false
                    }
                    else {
                        Write-Warning 'CCMSetup activity not detected within last 24 hours - marking log as stale'
                        $LogStale = $true
                    }
                }
                else {
                    Write-Warning $([string]::Format('CCMSetup.log not found in {0} - marking log as stale', $MEMCMClientInstallLog))
                    $LogStale = $true
                }
            }
            else {
                Write-Warning $([string]::Format('{0} not found', $LogFullPath))
                $LogStale = 'File Not Found'
            }
            $Result['LogStale'] = $LogStale
            [pscustomobject]$Result
        }
    }
}