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
        $connectionSplat = @{ }
        $getClientVersionSplat = @{
            Namespace = 'root\CCM'
            Query     = 'SELECT ClientVersion FROM SMS_Client'
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