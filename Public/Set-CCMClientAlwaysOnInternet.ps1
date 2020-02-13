function Set-CCMClientAlwaysOnInternet {
    <#
        .SYNOPSIS
            Set the ClientAlwaysOnInternet registry key on a computer
        .DESCRIPTION
            This function leverages the Set-CimRegistryProperty function in order to configure
            the ClientAlwaysOnInternet property for the MEMCM Client.
        .PARAMETER Status
            Determines if the setting should be Enabled or Disabled
        .PARAMETER CimSession
            Provides CimSessions to set the ClientAlwaysOnInternet setting for
        .PARAMETER ComputerName
            Provides computer names to set the ClientAlwaysOnInternet setting for
        .EXAMPLE
            C:\PS> Set-CCMClientAlwaysOnInternet -Status Enabled
                Sets ClientAlwaysOnInternet to Enabled for the local computer
        .EXAMPLE
            C:\PS> Set-CCMClientAlwaysOnInternet -ComputerName 'Workstation1234','Workstation4321' -Status Disabled
                Sets ClientAlwaysOnInternet to Disabled for 'Workstation1234', and 'Workstation4321'
        .NOTES
            FileName:    Set-CCMClientAlwaysOnInternet.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-02-1W3
            Updated:     2020-02-13
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Enabled', 'Disabled')]
        [string]$Status,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession
    )
    begin {
        $Enablement = switch ($Status) {
            'Enabled' {
                1
            }
            'Disabled' {
                0
            }
        }
        $SetAlwaysOnInternetSplat = @{
            Force        = $true
            PropertyType = 'DWORD'
            Property     = 'ClientAlwaysOnInternet'
            Value        = $Enablement
            Key          = 'SOFTWARE\Microsoft\CCM\Security'
            RegRoot      = 'HKEY_LOCAL_MACHINE'
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

            try {
                Set-CIMRegistryProperty @SetAlwaysOnInternetSplat @connectionSplat
            }
            catch {
                Write-Error "Failure to set MEMCM ClientAlwaysOnInternet to $Enablement for $Computer - $($_.Exception.Message)"
            }
        }
    }
}