function Get-CCMLastHeartbeat {
    <#
    .SYNOPSIS
        Returns info about the last time a heartbeat ran. Also known as a DDR.
    .DESCRIPTION
        This function will return info about the last time Discovery Data Collection Cycle was ran. This is pulled from the InventoryActionStatus WMI Class. 
        The Discovery Data Collection Cycle major, and minor version is included. 

        This is also known as a 'Heartbeat' or 'DDR'
    .PARAMETER CimSession
        Provides CimSessions to gather Discovery Data Collection Cycle last run info from
    .PARAMETER ComputerName
        Provides computer names to gather Discovery Data Collection Cycle last run info from
    .EXAMPLE
        C:\PS> Get-CCMLastHeartbeat
            Returns info regarding the last Discovery Data Collection Cycle for the local computer
    .EXAMPLE
        C:\PS> Get-CCMLastHeartbeat -ComputerName 'Workstation1234','Workstation4321'
            Returns info regarding the last Discovery Data Collection Cycle for Workstation1234, and Workstation4321
    .NOTES
        FileName:    Get-CCMLastHeartbeat.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-01-01
        Updated:     2020-01-18
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CCMLastDDR')]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        $getLastDDRSplat = @{
            Namespace = 'root\CCM\InvAgt'
            Query     = "SELECT LastCycleStartedDate, LastReportDate, LastMajorReportVersion, LastMinorReportVersion, InventoryActionID FROM InventoryActionStatus WHERE InventoryActionID = '{00000000-0000-0000-0000-000000000003}'"
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
                                $getLastDDRSplat.Remove('ComputerName')
                                $getLastDDRSplat['CimSession'] = $ExistingCimSession
                            }
                            else {
                                Write-Verbose "No active CimSession found for $Connection - falling back to -ComputerName parameter for CIM cmdlets"
                                $getLastDDRSplat.Remove('CimSession')
                                $getLastDDRSplat['ComputerName'] = $Connection
                            }
                        }
                        $true {
                            $getLastDDRSplat.Remove('CimSession')
                            $getLastDDRSplat.Remove('ComputerName')
                            Write-Verbose 'Local computer is being queried - skipping computername, and cimsession parameter'
                        }
                    }
                }
                'CimSession' {
                    Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
                    Write-Output -InputObject $Connection.ComputerName
                    $getLastDDRSplat.Remove('ComputerName')
                    $getLastDDRSplat['CimSession'] = $Connection
                }
            }
            $Result = [System.Collections.Specialized.OrderedDictionary]::new()
            $Result['ComputerName'] = $Computer

            try {
                [ciminstance[]]$LastDDR = Get-CimInstance @getLastDDRSplat
                if ($LastDDR -is [Object] -and $LastDDR.Count -gt 0) {
                    foreach ($Occurrence in $LastDDR) {
                        $Result['LastCycleStartedDate'] = $Occurrence.LastCycleStartedDate
                        $Result['LastReportDate'] = $Occurrence.LastReportDate
                        $Result['LastMajorReportVersion'] = $Occurrence.LastMajorReportVersion
                        $Result['LastMinorReportVersion'] = $Occurrence.LastMinorReportVersion
                        [PSCustomObject]$Result
                    }
                }
                else {
                    Write-Warning "No Discovery Data Collection Cycle run found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}