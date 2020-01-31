function Get-CCMClientDirectory {
    <#
    .SYNOPSIS
        Return the MEMCM Client Directory
    .DESCRIPTION
        Checks the registry of the local machine and will return the 'Local SMS Path' property of the 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SMS\Client\Configuration\Client Properties'
        registry key. This function uses the Get-CIMRegistryProperty function which uses CIM to query the registry
    .PARAMETER CimSession
        Provides CimSessions to gather the MEMCM Client Directory from
    .PARAMETER ComputerName
        Provides computer names to gather the MEMCM Client Directory from
    .EXAMPLE
        C:\PS> Get-CCMClientDirectory
            Returns the MEMCM Client Directory for the local computer
    .EXAMPLE
        C:\PS> Get-CCMClientDirectory -ComputerName 'Workstation1234','Workstation4321'
            Returns the MEMCM Client Directory for Workstation1234, and Workstation4321
    .NOTES
        FileName:    Get-CCMClientDirectory.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-01-12
        Updated:     2020-01-24
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
        $getRegistryPropertySplat = @{
            Key      = "SOFTWARE\Microsoft\SMS\Client\Configuration\Client Properties"
            Property = "Local SMS Path"
            RegRoot  = 'HKEY_LOCAL_MACHINE'
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

            $ReturnHashTable = Get-CIMRegistryProperty @getRegistryPropertySplat @connectionSplat
            foreach ($PC in $ReturnHashTable.GetEnumerator()) {
                $Result['ClientDirectory'] = $ReturnHashTable[$PC.Key].'Local SMS Path'.TrimEnd('\')
            }
            [pscustomobject]$Result
        }
    }
}