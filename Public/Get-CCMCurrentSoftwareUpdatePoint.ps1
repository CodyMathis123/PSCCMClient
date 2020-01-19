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
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        $connectionSplat = @{ }
        $CurrentSUPSplat = @{
            Namespace = 'root\ccm\SoftwareUpdates\WUAHandler'
            Query     = 'SELECT ContentLocation FROM CCM_UpdateSource'
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

            try {
                [ciminstance[]]$CurrentSUP = Get-CimInstance @CurrentSUPSplat @connectionSplat
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