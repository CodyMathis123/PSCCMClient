function Get-CCMTaskSequence {
    <#
    .SYNOPSIS
        Return deployed task sequences from a computer
    .DESCRIPTION
        Pulls a list of deployed task sequences from the specified computer(s) or CIMSession(s) with optional filters, and can be passed on
        to Invoke-CCMTaskSequence if desired.

        Note that the parameters for filter are all joined together with OR.
    .PARAMETER PackageID
        An array of PackageID to filter on
    .PARAMETER TaskSequenceName
        An array of task sequence names to filter on
    .PARAMETER CimSession
        Provides CimSession to gather deployed task sequence info from
    .PARAMETER ComputerName
        Provides computer names to gather deployed task sequence info from
    .EXAMPLE
        PS> Get-CCMTaskSequence
            Returns all deployed task sequences listed in WMI on the local computer
    .EXAMPLE
        PS> Get-CCMTaskSequence -TaskSequenceName 'Windows 10' -PackageID 'TST00443'
            Returns all deployed task sequences listed in WMI on the local computer which have either a task sequence name of 'Windows 10' or
            a PackageID of 'TST00443'
    .NOTES
        FileName:    Get-CCMTaskSequence.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-01-14
        Updated:     2020-01-14
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$PackageID,
        [Parameter(Mandatory = $false)]
        [string[]]$TaskSequenceName,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        $connectionSplat = @{ }
        #region define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
        $getPackageSplat = @{
            NameSpace = 'root\CCM\Policy\Machine\ActualConfig'
        }
        #endregion define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
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

            try {
                $FilterParts = switch ($PSBoundParameters.Keys) {
                    'PackageID' {
                        [string]::Format('PKG_PackageID = "{0}"', [string]::Join('" OR PRG_ProgramName = "', $PackageID))
                    }
                    'TaskSequenceName' {
                        [string]::Format('PKG_Name = "{0}"', [string]::Join('" OR PKG_Name = "', $TaskSequenceName))
                    }
                }
                $Filter = switch ($null -ne $FilterParts) {
                    $true {
                        [string]::Format(' WHERE {0}', [string]::Join(' OR ', $FilterParts))
                    }
                    $false {
                        ' '
                    }
                }
                $getPackageSplat['Query'] = [string]::Format('SELECT * FROM CCM_TaskSequence{0}', $Filter)

                [ciminstance[]]$Packages = Get-CimInstance @getPackageSplat @connectionSplat
                if ($Packages -is [Object] -and $Packages.Count -gt 0) {
                    Write-Output -InputObject $Packages
                }
                else {
                    Write-Warning "No deployed task sequences found for $Computer based on input filters"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
