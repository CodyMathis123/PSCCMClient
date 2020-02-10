function Get-CCMClientVersion {
    <#
    .SYNOPSIS
        Returns the current MEMCM client version
    .DESCRIPTION
        This function will return the current version for the MEMCM client using CIM.
    .PARAMETER CimSession
        Provides CimSessions to gather the version from
    .PARAMETER ComputerName
        Provides computer names to gather the version from
    .EXAMPLE
        C:\PS> Get-CCMClientVersion
            Returns the MEMCM client version from local computer
    .EXAMPLE
        C:\PS> Get-CCMClientVersion -ComputerName 'Workstation1234','Workstation4321'
            Returns the MEMCM client version from Workstation1234, and Workstation4321
    .NOTES
        FileName:    Get-CCMClientVersion.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-01-24
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
        $getClientVersionSplat = @{
            Namespace = 'root\CCM'
            Query     = 'SELECT ClientVersion FROM SMS_Client'
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
                [ciminstance[]]$Currentversion = Get-CimInstance @getClientVersionSplat @connectionSplat
                if ($Currentversion -is [Object] -and $Currentversion.Count -gt 0) {
                    foreach ($SMSClient in $Currentversion) {
                        $Result['ClientVersion'] = $SMSClient.ClientVersion
                        [PSCustomObject]$Result
                    }
                }
                else {
                    Write-Warning "No client version found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}