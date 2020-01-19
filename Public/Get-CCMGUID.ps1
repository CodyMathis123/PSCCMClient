function Get-CCMGUID {
    <#
    .SYNOPSIS
        Returns the current client GUID
    .DESCRIPTION
        This function will return the current GUID for the MEMCM client using CIM.
    .PARAMETER CimSession
        Provides CimSessions to gather the GUID from
    .PARAMETER ComputerName
        Provides computer names to gather the GUID from
    .EXAMPLE
        C:\PS> Get-CCMGUID
            Returns the GUID from local computer
    .EXAMPLE
        C:\PS> Get-CCMGUID -ComputerName 'Workstation1234','Workstation4321'
            Returns the GUID from Workstation1234, and Workstation4321
    .NOTES
        FileName:    Get-CCMGUID.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-01-18
        Updated:     2020-01-18
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
        $getGUIDSplat = @{
            Namespace = 'root\CCM'
            Query     = 'SELECT ClientID, ClientIDChangeDate, PreviousClientID FROM CCM_Client'
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
                [ciminstance[]]$CurrentGUID = Get-CimInstance @getGUIDSplat @connectionSplat
                if ($CurrentGUID -is [Object] -and $CurrentGUID.Count -gt 0) {
                    foreach ($GUID in $CurrentGUID) {
                        $Result['GUID'] = $GUID.ClientID
                        $Result['ClientGUIDChangeDate'] = $GUID.ClientIDChangeDate
                        $Result['PreviousGUID'] = $GUID.PreviousClientID
                        [PSCustomObject]$Result
                    }
                }
                else {
                    Write-Warning "No ClientID information found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}