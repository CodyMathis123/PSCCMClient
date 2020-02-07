function Get-CCMPrimaryUser {
    <#
    .SYNOPSIS
        Return primary users for a computer
    .DESCRIPTION
        Pulls a list of primary users from WMI on the specified computer(s) or CIMSession(s)
    .PARAMETER CimSession
        Provides CimSession to gather primary users info from
    .PARAMETER ComputerName
        Provides computer names to gather primary users info from
    .EXAMPLE
        PS> Get-CCMPrimaryUser
            Returns all primary users listed in WMI on the local computer
    .NOTES
        FileName:    Get-CCMPrimaryUser.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-01-05
        Updated:     2020-01-05
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
        #region define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
        $getPrimaryUserSplat = @{
            NameSpace = 'root\CCM\CIModels'
            Query     = 'SELECT User from CCM_PrimaryUser'
        }
        #endregion define our hash tables for parameters to pass to Get-CIMInstance and our return hash table

        $connectionSplat = @{ }
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
                [ciminstance[]]$PrimaryUsers = Get-CimInstance @getPrimaryUserSplat @connectionSplat
                if ($PrimaryUsers -is [Object] -and $PrimaryUsers.Count -gt 0) {
                    $Result['PrimaryUser'] = $PrimaryUsers.User
                    [PSCustomObject]$Result
                }
                else {
                    Write-Warning "No Primary Users found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
