function Remove-CCMCacheContent {
    param(
        [parameter(Mandatory = $false, ParameterSetName = 'ByID')]
        [string[]]$ContentID,
        [parameter(Mandatory = $false, ParameterSetName = 'ClearCache')]
        [switch]$Clear,
        [parameter(Mandatory = $false)]
        [switch]$Force
    )
    $Client = New-Object -ComObject UIResource.UIResourceMGR
    $Cache = $Client.GetCacheInfo()
    $CacheContent = $Cache.GetCacheElements()
    foreach ($CacheItem in $CacheContent) {
        $CacheElementToRemove = switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                switch ($CacheItem.ContentID -eq $ContentID) {
                    $true {
                        $CacheItem.CacheElementId
                    }
                }
            }
            'ClearCache' {
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