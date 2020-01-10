function Set-CCMCacheLocation {
    <#
    .SYNOPSIS
        Set ConfigMgr cache location from computers via CIM
    .DESCRIPTION
        This function will allow you to set the configuration manager cache location for multiple computers using CIM queries. 
        You can provide an array of computer names, or cimsession, or you can pass them through the pipeline.
        It will return a hashtable with the computer as key and boolean as value for success
    .PARAMETER Location
        Provides the desired cache location
    .PARAMETER CimSession
        Provides CimSessions to set the cache location for
    .PARAMETER ComputerName
        Provides computer names to set the cache location for
    .EXAMPLE
        C:\PS> Set-CCMCacheLocation -Location d:\windows\ccmcache
            Set cache location to d:\windows\ccmcache for local computer
    .EXAMPLE
        C:\PS> Set-CCMCacheLocation -ComputerName 'Workstation1234','Workstation4321' -Location 'C:\windows\ccmcache'
            Set Cache location to 'C:\Windows\CCMCache' for Workstation1234, and Workstation4321
    .NOTES
        FileName:    Set-CCMCacheLocation.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2019-11-06
        Updated:     2020-01-09
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [parameter(Mandatory = $true)]
        [string]$Location,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {        
        $GetCacheSplat = @{
            Namespace = 'root\CCM\SoftMgmtAgent'
            ClassName = 'CacheConfig'
        }
        $SetCacheSplat = @{
            Property = @{ 
                Location = $Location 
            }
        }
        $CacheSplat = @{
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
                                $GetCacheSplat.Remove('ComputerName')
                                $GetCacheSplat['CimSession'] = $ExistingCimSession
                                $SetCacheSplat.Remove('ComputerName')
                                $SetCacheSplat['CimSession'] = $ExistingCimSession
                            }
                            else {
                                Write-Verbose "No active CimSession found for $Connection - falling back to -ComputerName parameter for CIM cmdlets"
                                $GetCacheSplat.Remove('CimSession')
                                $GetCacheSplat['ComputerName'] = $Connection
                                $SetCacheSplat.Remove('CimSession')
                                $SetCacheSplat['ComputerName'] = $Connection
                            }
                        }
                        $true {
                            $GetCacheSplat.Remove('CimSession')
                            $GetCacheSplat.Remove('ComputerName')
                            $SetCacheSplat.Remove('CimSession')
                            $SetCacheSplat.Remove('ComputerName')
                            Write-Verbose 'Local computer is being queried - skipping computername, and cimsession parameter'
                        }
                    }
                }
                'CimSession' {
                    Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
                    Write-Output -InputObject $Connection.ComputerName
                    $GetCacheSplat.Remove('ComputerName')
                    $SetCacheSplat.Remove('ComputerName')
                    $GetCacheSplat['CimSession'] = $Connection
                    $SetCacheSplat['CimSession'] = $Connection
                }
            }
            $Return = [System.Collections.Specialized.OrderedDictionary]::new()

            try {
                if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [Location = '$Location']", "Set CCM Cache Location")) {
                    $Cache = Get-CimInstance @GetCacheSplat @CacheSplat
                    if ($Cache -is [object]) {
                        switch ($Cache.Location) {
                            $Location {
                                $Return[$Computer] = $true
                            }
                            default {
                                $SetCacheSplat['InputObject'] = $Cache
                                $null = Set-CimInstance @CacheSplat @SetCacheSplat
                                $Cache = Get-CimInstance @GetCacheSplat @CacheSplat
                                switch ($Cache.Location) {
                                    $Location {
                                        $Return[$Computer] = $true
                                    }
                                    default {       
                                        $Return[$Computer] = $false
                                    }
                                }
                            }
                        }
                    }
                    Write-Output $Return
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
