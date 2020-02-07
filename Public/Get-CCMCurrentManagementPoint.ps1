function Get-CCMCurrentManagementPoint {
    <#
    .SYNOPSIS
        Returns the current assigned MP from a client
    .DESCRIPTION
        This function will return the current assigned MP for the client using CIM. 
    .PARAMETER CimSession
        Provides CimSessions to gather the current assigned MP from
    .PARAMETER ComputerName
        Provides computer names to gather the current assigned MP from
    .EXAMPLE
        C:\PS> Get-CCMCurrentManagementPoint
            Returns the current assigned MP from local computer
    .EXAMPLE
        C:\PS> Get-CCMCurrentManagementPoint -ComputerName 'Workstation1234','Workstation4321'
            Returns the current assigned MP from Workstation1234, and Workstation4321
    .NOTES
        FileName:    Get-CCMCurrentManagementPoint.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-01-16
        Updated:     2020-01-18
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CCMCurrentMP', 'Get-CCMMP')]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        $connectionSplat = @{ }
        $getCurrentMPSplat = @{
            Namespace = 'root\CCM'
            Query     = 'SELECT CurrentManagementPoint FROM SMS_Authority'
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

            try {
                [ciminstance[]]$CurrentMP = Get-CimInstance @getCurrentMPSplat @connectionSplat
                if ($CurrentMP -is [Object] -and $CurrentMP.Count -gt 0) {
                    foreach ($MP in $CurrentMP) {
                        $Result['CurrentManagementPoint'] = $MP.CurrentManagementPoint
                        [PSCustomObject]$Result
                    }
                }
                else {
                    Write-Warning "No Management Point infomration found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}