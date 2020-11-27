Function Test-CCMStaleLog {
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
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [Alias('Session')]      
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession,
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [ValidateSet('CimSession', 'PSSession')]
        [string]$ConnectionPreference
    )
    begin {
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
            $Result['LogFileName'] = $LogFileName
            $Result['LogLastWriteTime'] = $null
            $Result['LogStale'] = $null
            $Result['CCMSetupLastWriteTime'] = $null
            $CCMLogDirectory = (Get-CCMLoggingConfiguration @connectionSplat).LogDirectory
            $LogFullPath = [string]::Join('\', $CCMLogDirectory, $LogFileName)

            Write-Verbose $([string]::Format('Checking {0} for activity', $LogFullPath))

            $getRequestedLogInfoSplat['Query'] = [string]::Format('SELECT Readable, LastModified FROM CIM_DataFile WHERE Name = "{0}" OR Name = "{1}"', ($LogFullPath -replace "\\", "\\"), ($MEMCMClientInstallLog -replace "\\", "\\"))
            # 'Poke' the log by querying it once. Log files sometimes do not show an accurate LastModified time until they are accessed
            $null = switch ($Computer -eq $env:ComputerName) {
                $true {
                    Get-CimInstance @getRequestedLogInfoSplat @connectionSplat
                }
                $false {
                    Get-CCMCimInstance @getRequestedLogInfoSplat @connectionSplat
                }
            }
            $RequestedLogInfo = switch ($Computer -eq $env:ComputerName) {
                $true {
                    Get-CimInstance @getRequestedLogInfoSplat @connectionSplat
                }
                $false {
                    Get-CCMCimInstance @getRequestedLogInfoSplat @connectionSplat
                }
            }
            $RequestedLog = $RequestedLogInfo.Where({ $_.Name -eq $LogFullPath})
            $MEMCMSetupLog = $RequestedLogInfo.Where({ $_.Name -eq $MEMCMClientInstallLog})
            if ($null -ne $MEMCMSetupLog) {
                $Result['CCMSetupLastWriteTime'] = ([datetime]$dtmMEMCMClientInstallLogDate = $MEMCMSetupLog.LastModified)
            }
            if ($null -ne $RequestedLog) {
                $Result['LogLastWriteTime'] = ([datetime]$LogLastWriteTime = $RequestedLog.LastModified)
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