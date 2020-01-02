function Get-CCMLastSoftwareInventory {
    <#
    .SYNOPSIS
        Returns info about the last time a heartbeat ran. Also known as a DDR.
    .DESCRIPTION
        This function will return info about the last time Software Inventory Cycle was ran. This is pulled from the InventoryActionStatus WMI Class. 
        The Software Inventory Cycle major, and minor version is included. 

        This is also known as a 'Heartbeat' or 'DDR'
    .PARAMETER ComputerName
        Provides computer names to gather Software Inventory Cycle last run info from
    .PARAMETER Credential
        Provides optional credentials to use for the WMI cmdlets.
    .EXAMPLE
        C:\PS> Get-CCMLastSoftwareInventory 
            Returns info regarding the last Software Inventory Cycle for the local computer
    .EXAMPLE
        C:\PS> Get-CCMLastSoftwareInventory -ComputerName 'Workstation1234','Workstation4321' 
            Returns info regarding the last Software Inventory Cycle for Workstation1234, and Workstation4321
    .NOTES
        FileName:    Get-CCMLastSoftwareInventory.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2019-01-01
        Updated:     2019-01-01
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
        [Alias('Computer', 'PSComputerName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [parameter(Mandatory = $false)]
        [pscredential]$Credential
    )
    begin {
        $getWmiObjectLastHinv = @{
            Namespace = 'root\CCM\InvAgt'
            Query     = "SELECT LastCycleStartedDate, LastReportDate, LastMajorReportVersion, LastMinorReportVersion, InventoryActionID FROM InventoryActionStatus WHERE InventoryActionID = '{00000000-0000-0000-0000-000000000002}'"
        }
        if ($PSBoundParameters.ContainsKey('Credential')) {
            $getWmiObjectLastHinv['Credential'] = $Credential
        }
    }
    process {
        foreach ($Computer in $ComputerName) {
            $Result = [System.Collections.Specialized.OrderedDictionary]::new()
            $Result['ComputerName'] = $Computer
            $getWmiObjectLastHinv['ComputerName'] = $Computer

            try {
                [System.Management.ManagementObject[]]$LastHinv = Get-WmiObject @getWmiObjectLastHinv
                if ($LastHinv -is [Object] -and $LastHinv.Count -gt 0) {
                    foreach ($Occurrence in $LastHinv) {
                        $Result['LastCycleStartedDate'] = [DateTime]::ParseExact(($Occurrence.LastCycleStartedDate.Split('+|-')[0]), 'yyyyMMddHHmmss.ffffff', [System.Globalization.CultureInfo]::InvariantCulture)
                        $Result['LastReportDate'] = [DateTime]::ParseExact(($Occurrence.LastReportDate.Split('+|-')[0]), 'yyyyMMddHHmmss.ffffff', [System.Globalization.CultureInfo]::InvariantCulture)
                        $Result['LastMajorReportVersion'] = $Occurrence.LastMajorReportVersion
                        $Result['LastMinorReportVersion'] = $Occurrence.LastMinorReportVersion
                        [PSCustomObject]$Result
                    }
                }
                else {
                    Write-Warning "No Software Inventory Cycle run found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}