function Get-CCMSite {
    <#
        .SYNOPSIS
            Returns the current MEMCM Site set for the MEMCM Client
        .DESCRIPTION
            This function will return the current MEMCM Site for the MEMCM Client. This is done using the Microsoft.SMS.Client COM Object.
        .PARAMETER CimSession
            Provides CimSessions to return the current MEMCM Site for
        .PARAMETER ComputerName
            Provides computer names to return the current MEMCM Site for
        .EXAMPLE
            C:\PS> Get-CCMSite
                Return the local computers MEMCM Site setting
        .EXAMPLE
            C:\PS> Get-CCMSite -ComputerName 'Workstation1234','Workstation4321'
                Return the MEMCM Site setting for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMSite.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-18
            Updated:     2020-01-18
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param(
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        $connectionSplat = @{ }
        $invokeCIMPowerShellSplat = @{ }
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

            $Result['SiteCode'] = switch ($Computer -eq $env:ComputerName) {
                $true {
                    $Client = New-Object -ComObject Microsoft.SMS.Client
                    $Client.GetAssignedSite()
                }
                $false {
                    $invokeCIMPowerShellSplat['ScriptBlock'] = {
                        $Client = New-Object -ComObject Microsoft.SMS.Client
                        $Client.GetAssignedSite()
                    }
                    Invoke-CIMPowerShell @invokeCIMPowerShellSplat @connectionSplat
                }
            }
            [pscustomobject]$Result
        }
    }
}