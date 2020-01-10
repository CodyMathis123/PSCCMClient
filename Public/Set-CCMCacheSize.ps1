function Set-CCMCacheSize {
    <#
    .SYNOPSIS
        Set ConfigMgr cache size from computers via UIResource.UIResourceMgr invoked over CIM
    .DESCRIPTION
        This function will allow you to set the configuration manager cache size for multiple computers using Invoke-CIMPowerShell. 
        You can provide an array of computer names, cimsesions, or you can pass them through the pipeline.
        It will return a hashtable with the computer as key and boolean as value for success
    .PARAMETER Size
        Provides the desired cache size in MB
    .PARAMETER CimSession
        Provides CimSessions to set CCMCache size on
    .PARAMETER ComputerName
        Provides computer names to set CCMCache size on
    .EXAMPLE
        C:\PS> Set-CCMCacheSize -Size 20480
            Set the cache size to 20480 MB for the local computer
    .EXAMPLE
        C:\PS> Set-CCMCacheSize -ComputerName 'Workstation1234','Workstation4321' -Size 10240
            Set the cache size to 10240 MB for Workstation1234, and Workstation4321
    .NOTES
        FileName:    Set-CCMCacheSize.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2019-11-06
        Updated:     2020-01-08
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [parameter(Mandatory = $true)]
        [ValidateRange(1, 99999)]
        [int]$Size,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        $GetCacheSplat = @{
            Namespace   = 'root\CCM\SoftMgmtAgent'
            ClassName   = 'CacheConfig'
            ErrorAction = 'Stop'
        }

        $SetCacheSizeScriptBlock = [scriptblock]::Create([string]::Format('(New-Object -ComObject UIResource.UIResourceMgr).GetCacheInfo().TotalSize = {0}', $Size))
        $SetCacheSplat = @{
            ScriptBlock = $SetCacheSizeScriptBlock
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
                if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [Size = '$Size']", "Set CCM Cache Size")) {
                    $Cache = Get-CimInstance @GetCacheSplat
                    if ($Cache -is [object]) {
                        switch ($Cache.Size) {
                            $Size {
                                $Return[$Computer] = $true
                            }
                            default {
                                switch ($Computer -eq $env:ComputerName) {
                                    $true {
                                        . $SetCacheSizeScriptBlock
                                    }
                                    $false {
                                        Invoke-CIMPowerShell @SetCacheSplat
                                    }
                                }
                                $Cache = Get-CimInstance @GetCacheSplat
                                if ($Cache -is [Object] -and $Cache.Size -eq $Size) {
                                    $Return[$Computer] = $true
                                }
                                else {
                                    $Return[$Computer] = $false
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
