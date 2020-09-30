function Remove-CCMCacheContent {
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param(
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ContentID,
        [parameter(Mandatory = $false)]
        [switch]$Clear,
        [parameter(Mandatory = $false)]
        [switch]$Force,
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
        switch ($PSBoundParameters.Keys -contains 'ContentID' -and $PSBoundParameters.Keys -contains 'Clear') {
            $true {
                Write-Error -ErrorAction Stop -Message 'Both ContentID and Clear parameters provided - please only provide one. Note that ParameterSetName is in use, but is currently being used for CimSession/ComputerName distinction. Feel free to make a pull request ;)'
            }
        }
        $invokeCommandSplat = @{
            FunctionsToLoad = 'Remove-CCMCacheContent', 'Get-CCMConnection'
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

            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [ContentID = '$([string]::Join('; ', $ContentID))]'", "Remove-CCMCacheContent")) {
                $removeCacheContentArgs = switch ($PSBoundParameters.Keys) {
                    'ContentID' {
                        [string]::Format('-ContentID "{0}"', [string]::Join('", "', $ContentID))
                    }
                    'Clear' {
                        '-Clear'
                    }
                    'Force' {
                        '-Force'
                    }
                }
                switch ($Computer -eq $env:ComputerName) {
                    $true {
                        $Client = New-Object -ComObject UIResource.UIResourceMGR
                        $Cache = $Client.GetCacheInfo()
                        $CacheContent = $Cache.GetCacheElements()
                        foreach ($ID in $ContentID) {
                            foreach ($CacheItem in $CacheContent) {
                                $CacheElementToRemove = switch ($PSBoundParameters.Keys) {
                                    'ContentID' {
                                        switch ($CacheItem.ContentID -eq $ID) {
                                            $true {
                                                $CacheItem.CacheElementId
                                            }
                                        }
                                    }
                                    'Clear' {
                                        $CacheItem.CacheElementId
                                    }
                                }
                                switch ($null -ne $CacheElementToRemove) {
                                    $true {
                                        switch ($Force.IsPresent) {
                                            $false {
                                                $Cache.DeleteCacheElement($CacheElementToRemove)
                                            }
                                            $true {
                                                $Cache.DeleteCacheElementEx($CacheElementToRemove, 1)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    $false {
                        $ScriptBlock = [string]::Format('Remove-CCMCacheContent {0}', [string]::Join(' ', $removeCacheContentArgs))
                        $invokeCommandSplat['ScriptBlock'] = [scriptblock]::Create($ScriptBlock)
                        Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                    }
                }
            }
        }
    }
}