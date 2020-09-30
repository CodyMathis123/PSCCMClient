function Set-CCMCacheLocation {
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [parameter(Mandatory = $true)]
        [ValidateScript( { -not $_.EndsWith('\') } )]
        [string]$Location,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [Alias('Session')]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession,
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [ValidateSet('CimSession', 'PSSession')]
        [string]$ConnectionPreference
    )
    begin {       
        $FullCachePath = switch ($Location.EndsWith('ccmcache', 'CurrentCultureIgnoreCase')) {
            $true {
                Write-Output $Location
            }
            $false {
                Join-Path -Path $Location -ChildPath 'ccmcache'
            }
        }
        
        $GetCacheSplat = @{
            Namespace = 'root\CCM\SoftMgmtAgent'
            ClassName = 'CacheConfig'
        }
        $SetCacheScriptblock = [scriptblock]::Create([string]::Format('(New-Object -ComObject UIResource.UIResourceMgr).GetCacheInfo().Location = "{0}"', (Split-Path -Path $FullCachePath -Parent)))
        $SetCacheSplat = @{
            ScriptBlock = $SetCacheScriptblock
        }
    }
    process {
        foreach ($Connection in (Get-Variable -Name $PSCmdlet.ParameterSetName -ValueOnly)) {
            $getConnectionInfoSplat = @{
                $PSCmdlet.ParameterSetName = $Connection
            }
            switch ($PSBoundParameters.ContainsKey('ConnectionPreference')) {
                $true {
                    $getConnectionInfoSplat['Prefer'] = $ConnectionPreference
                }
            }
            $ConnectionInfo = Get-CCMConnection @getConnectionInfoSplat
            $Computer = $ConnectionInfo.ComputerName
            $connectionSplat = $ConnectionInfo.connectionSplat

            $Return = [ordered]@{ }

            try {
                if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [Location = '$Location']", "Set CCM Cache Location")) {
                    $Cache = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Get-CimInstance @GetCacheSplat @connectionSplat
                        }
                        $false {
                            Get-CCMCimInstance @GetCacheSplat @connectionSplat
                        }
                    }
                    if ($Cache -is [object]) {
                        switch ($Cache.Location) {
                            $FullCachePath {
                                $Return[$Computer] = $true
                            }
                            default {
                                switch ($Computer -eq $env:ComputerName) {
                                    $true {
                                        $SetCacheScriptblock.Invoke()
                                    }
                                    $false {
                                        Invoke-CCMCommand @SetCacheSplat @connectionSplat
                                    }
                                }
                                $Cache = switch ($Computer -eq $env:ComputerName) {
                                    $true {
                                        Get-CimInstance @GetCacheSplat @connectionSplat
                                    }
                                    $false {
                                        Get-CCMCimInstance @GetCacheSplat @connectionSplat
                                    }
                                }
                                switch ($Cache.Location) {
                                    $FullCachePath {
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
