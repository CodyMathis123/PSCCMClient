function Get-CCMCacheInfo {
    <#
    .SYNOPSIS
        Get ConfigMgr client cache directory info from computers via CIM
    .DESCRIPTION
        This function will allow you to gather the ConfigMgr client cache directory info from multiple computers using CIM queries.
        You can provide an array of computer names, or cimsessions, or you can pass them through the pipeline.
    .PARAMETER CimSession
        Provides CimSession to gather cache info from.
    .PARAMETER ComputerName
        Provides computer names to gather cache info from.
    .EXAMPLE
        C:\PS> Get-CCMCacheInfo
            Return ConfigMgr client cache directory info for the local computer
    .EXAMPLE
        C:\PS> Get-CCMCacheInfo -ComputerName 'Workstation1234','Workstation4321'
            Return ConfigMgr client cache directory info for Workstation1234, and Workstation4321
    .NOTES
        FileName:    Get-CCMCacheInfo.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2019-11-06
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
        $getCacheInfoSplat = @{
            Namespace   = 'root\CCM\SoftMgmtAgent'
            ClassName   = 'CacheConfig'
            ErrorAction = 'Stop'
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
                [ciminstance[]]$CimResult = Get-CimInstance @getCacheInfoSplat @connectionSplat
                if ($CimResult -is [Object] -and $CimResult.Count -gt 0) {
                    foreach ($Object in $CimResult) {
                        $Result['Location'] = $Object.Location
                        $Result['Size'] = $Object.Size
                        [PSCustomObject]$Result
                    }
                }
                else {
                    $Result['Location'] = $null
                    $Result['Size'] = $null
                    [PSCustomObject]$Result
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
