function Get-CCMCacheContent {
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
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
        $getCacheContentSplat = @{
            Namespace   = 'root\CCM\SoftMgmtAgent'
            ClassName   = 'CacheInfoEx'
            ErrorAction = 'Stop'
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
            $Result = [ordered]@{ }
            $Result['ComputerName'] = $Computer

            try {
                [ciminstance[]]$CacheContent = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getCacheContentSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getCacheContentSplat @connectionSplat
                    }
                }
                if ($CacheContent -is [Object] -and $CacheContent.Count -gt 0) {
                    foreach ($Item in $CacheContent) {
                        $Result['ContentId'] = $Item.ContentId
                        $Result['ContentVersion'] = $Item.ContentVer
                        $Result['Location'] = $Item.Location
                        $Result['LastReferenceTime'] = $Item.LastReferenced
                        $Result['ReferenceCount'] = $Item.ReferenceCount
                        $Result['ContentSize'] = $Item.ContentSize
                        $Result['ContentComplete'] = $Item.ContentComplete
                        $Result['CacheElementId'] = $Item.CacheID
                        [pscustomobject]$Result
                    }
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}