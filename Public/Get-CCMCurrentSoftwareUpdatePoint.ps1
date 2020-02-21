# TODO - Update help
function Get-CCMCurrentSoftwareUpdatePoint {
    <#
    .SYNOPSIS
        Returns the current assigned SUP from a client
    .DESCRIPTION
        This function will return the current assigned SUP for the client using CIM.
    .PARAMETER CimSession
        Provides CimSessions to gather the current assigned SUP from
    .PARAMETER ComputerName
        Provides computer names to gather the current assigned SUP from
    .EXAMPLE
        C:\PS> Get-CCMCurrentSoftwareUpdatePoint
            Returns the current assigned SUP from local computer
    .EXAMPLE
        C:\PS> Get-CCMCurrentSoftwareUpdatePoint -ComputerName 'Workstation1234','Workstation4321'
            Returns the current assigned SUP from Workstation1234, and Workstation4321
    .NOTES
        FileName:    Get-CCMCurrentSoftwareUpdatePoint.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-01-16
        Updated:     2020-01-18
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CCMCurrentSUP', 'Get-CCMSUP')]
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
        $CurrentSUPSplat = @{
            Namespace = 'root\ccm\SoftwareUpdates\WUAHandler'
            Query     = 'SELECT ContentLocation FROM CCM_UpdateSource'
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
                [ciminstance[]]$CurrentSUP = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @CurrentSUPSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @CurrentSUPSplat @connectionSplat
                    }
                }
                if ($CurrentSUP -is [Object] -and $CurrentSUP.Count -gt 0) {
                    foreach ($SUP in $CurrentSUP) {
                        $Result['CurrentSoftwareUpdatePoint'] = $SUP.ContentLocation
                        [PSCustomObject]$Result
                    }
                }
                else {
                    Write-Warning "No Software Update Point information found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}