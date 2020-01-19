function Get-CCMLastSoftwareInventory {
    <#
    .SYNOPSIS
        Returns info about the last time Software Inventory ran
    .DESCRIPTION
        This function will return info about the last time Software Inventory was ran. This is pulled from the InventoryActionStatus WMI Class.
        The Software inventory major, and minor version is included. This can be helpful in troubleshooting Software inventory issues.
    .PARAMETER CimSession
        Provides CimSession to gather Software inventory last run info from
    .PARAMETER ComputerName
        Provides computer names to gather Software inventory last run info from
    .EXAMPLE
        C:\PS> Get-CCMLastSoftwareInventory
            Returns info regarding the last Software inventory cycle for the local computer
    .EXAMPLE
        C:\PS> Get-CCMLastSoftwareInventory -ComputerName 'Workstation1234','Workstation4321'
            Returns info regarding the last Software inventory cycle for Workstation1234, and Workstation4321
    .NOTES
        FileName:    Get-CCMLastSoftwareInventory.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-01-01
        Updated:     2020-01-18
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CCMLastSINV')]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        $getLastSINVSplat = @{
            Namespace = 'root\CCM\InvAgt'
            Query     = "SELECT LastCycleStartedDate, LastReportDate, LastMajorReportVersion, LastMinorReportVersion, InventoryActionID FROM InventoryActionStatus WHERE InventoryActionID = '{00000000-0000-0000-0000-000000000002}'"
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
                                $getLastSINVSplat.Remove('ComputerName')
                                $getLastSINVSplat['CimSession'] = $ExistingCimSession
                            }
                            else {
                                Write-Verbose "No active CimSession found for $Connection - falling back to -ComputerName parameter for CIM cmdlets"
                                $getLastSINVSplat.Remove('CimSession')
                                $getLastSINVSplat['ComputerName'] = $Connection
                            }
                        }
                        $true {
                            $getLastSINVSplat.Remove('CimSession')
                            $getLastSINVSplat.Remove('ComputerName')
                            Write-Verbose 'Local computer is being queried - skipping computername, and cimsession parameter'
                        }
                    }
                }
                'CimSession' {
                    Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
                    Write-Output -InputObject $Connection.ComputerName
                    $getLastSINVSplat.Remove('ComputerName')
                    $getLastSINVSplat['CimSession'] = $Connection
                }
            }
            $Result = [System.Collections.Specialized.OrderedDictionary]::new()
            $Result['ComputerName'] = $Computer

            try {
                [ciminstance[]]$LastSINV = Get-CimInstance @getLastSINVSplat
                if ($LastSINV -is [Object] -and $LastSINV.Count -gt 0) {
                    foreach ($Occurrence in $LastSINV) {
                        $Result['LastCycleStartedDate'] = $Occurrence.LastCycleStartedDate
                        $Result['LastReportDate'] = $Occurrence.LastReportDate
                        $Result['LastMajorReportVersion'] = $Occurrence.LastMajorReportVersion
                        $Result['LastMinorReportVersion'] = $Occurrence.LastMinorReportVersion
                        [PSCustomObject]$Result
                    }
                }
                else {
                    Write-Warning "No Software inventory run found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}