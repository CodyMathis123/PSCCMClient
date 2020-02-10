function Get-CCMCacheContent {
    <#
        .SYNOPSIS
            Returns the content of the MEMCM cache
        .DESCRIPTION
            This function will return the content of the MEMCM cache. This is pulled from the CacheInfoEx WMI Class
        .PARAMETER CimSession
            Provides CimSessions to gather the content of the MEMCM cache from
        .PARAMETER ComputerName
            Provides computer names to gather the content of the MEMCM cache from
        .EXAMPLE
            C:\PS> Get-CCMCacheContent
                Returns the content of the MEMCM cache for the local computer
        .EXAMPLE
            C:\PS> Get-CCMCacheContent -ComputerName 'Workstation1234','Workstation4321'
                Returns the content of the MEMCM cache for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMCacheContent.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-12
            Updated:     2020-01-16
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
            $ConnectionInfo = Get-CCMConnection @getConnectionInfoSplat
            $Computer = $ConnectionInfo.ComputerName
            $connectionSplat = $ConnectionInfo.connectionSplat
            $Result = [ordered]@{ }
            $Result['ComputerName'] = $Computer

            try {
                [ciminstance[]]$CacheContent = Get-CimInstance @getCacheContentSplat @connectionSplat
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