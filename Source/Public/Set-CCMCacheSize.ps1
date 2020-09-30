function Set-CCMCacheSize {
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [parameter(Mandatory = $true)]
        [ValidateRange(1, 99999)]
        [int]$Size,
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
        $GetCacheSplat = @{
            Namespace   = 'root\CCM\SoftMgmtAgent'
            ClassName   = 'CacheConfig'
            ErrorAction = 'Stop'
        }
        $SetCacheSizeScriptBlockString = [string]::Format('(New-Object -ComObject UIResource.UIResourceMgr).GetCacheInfo().TotalSize = {0}', $Size)
        $SetCacheSizeScriptBlock = [scriptblock]::Create($SetCacheSizeScriptBlockString)
        $invokeCommandSplat = @{
            ScriptBlock = $SetCacheSizeScriptBlock
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
                if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [Size = '$Size']", "Set CCM Cache Size")) {
                    $Cache = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Get-CimInstance @GetCacheSplat @connectionSplat
                        }
                        $false {
                            Get-CCMCimInstance @GetCacheSplat @connectionSplat
                        }
                    }
                    if ($Cache -is [object]) {
                        switch ($Cache.Size) {
                            $Size {
                                $Return[$Computer] = $true
                            }
                            default {
                                switch ($Computer -eq $env:ComputerName) {
                                    $true {
                                        $SetCacheSizeScriptBlock.Invoke()
                                    }
                                    $false {
                                        Invoke-CCMCommand @invokeCommandSplat @connectionSplat
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