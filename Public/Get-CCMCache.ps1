function Get-CCMCache {
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
        C:\PS> Get-CCMCache
            Return ConfigMgr client cache directory info for the local computer
    .EXAMPLE
        C:\PS> Get-CCMCache -ComputerName 'Workstation1234','Workstation4321'
            Return ConfigMgr client cache directory info for Workstation1234, and Workstation4321
    .NOTES
        FileName:    Get-CCMCache.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2019-11-06
        Updated:     2020-01-05
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
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
                                $getCacheInfoSplat.Remove('ComputerName')
                                $getCacheInfoSplat['CimSession'] = $ExistingCimSession
                            }
                            else {
                                Write-Verbose "No active CimSession found for $Connection - falling back to -ComputerName parameter for CIM cmdlets"
                                $getCacheInfoSplat.Remove('CimSession')
                                $getCacheInfoSplat['ComputerName'] = $Connection
                            }
                        }
                        $true {
                            $getCacheInfoSplat.Remove('CimSession')
                            $getCacheInfoSplat.Remove('ComputerName')
                            Write-Verbose 'Local computer is being queried - skipping computername, and cimsession parameter'
                        }
                    }
                }
                'CimSession' {
                    Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
                    Write-Output -InputObject $Connection.ComputerName
                    $getCacheInfoSplat.Remove('ComputerName')
                    $getCacheInfoSplat['CimSession'] = $Connection
                }
            }
            $Result = [System.Collections.Specialized.OrderedDictionary]::new()
            $Result['ComputerName'] = $Computer

            try {
                [ciminstance[]]$CimResult = Get-CimInstance @getCacheInfoSplat
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
