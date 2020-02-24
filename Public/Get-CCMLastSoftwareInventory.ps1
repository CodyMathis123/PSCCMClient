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
        .PARAMETER PSSession
            Provides PSSessions to gather Software inventory last run info from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the funtion. This is ultimately going to result in the function running faster. The typicaly usecase is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName paramter is passed to.
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
            Updated:     2020-02-23
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CCMLastSINV')]
    param (
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
        $getLastSINVSplat = @{
            Namespace = 'root\CCM\InvAgt'
            Query     = "SELECT LastCycleStartedDate, LastReportDate, LastMajorReportVersion, LastMinorReportVersion, InventoryActionID FROM InventoryActionStatus WHERE InventoryActionID = '{00000000-0000-0000-0000-000000000002}'"
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
                [ciminstance[]]$LastSINV = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getLastSINVSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getLastSINVSplat @connectionSplat
                    }
                }
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