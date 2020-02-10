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
        $getRegistryPropertySplat = @{
            Key      = "SOFTWARE\Microsoft\SMS\Client\Configuration\Client Properties"
            Property = "Local SMS Path"
            RegRoot  = 'HKEY_LOCAL_MACHINE'
        }
    }
    process {
        foreach ($Connection in (Get-Variable -Name $PSCmdlet.ParameterSetName -ValueOnly)) {
            $getConnectionInfoSplat = @{
                $PSCmdlet.ParameterSetName = $Connection
            }
            $ConnectionInfo = Get-CCMConnection @getConnectionInfoSplat
            $Computer = $ConnectionInfo.ComputerName
            $connectionSplat = $ConnectionInfo.connectionSplat
            $Result = [ordered]@{ }
            $Result['ComputerName'] = $Computer

            $ReturnHashTable = Get-CIMRegistryProperty @getRegistryPropertySplat @connectionSplat
            foreach ($PC in $ReturnHashTable.GetEnumerator()) {
                $Result['ClientDirectory'] = $ReturnHashTable[$PC.Key].'Local SMS Path'.TrimEnd('\')
            }
            [pscustomobject]$Result
        }
    }
}