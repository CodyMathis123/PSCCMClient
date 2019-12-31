function Set-CCMCacheSize {
    <#
    .SYNOPSIS
        Set ConfigMgr cache size from computers via WMI
    .DESCRIPTION
        This function will allow you to set the configuration manager cache size for multiple computers using WMI queries. 
        You can provide an array of computer names, or you can pass them through the pipeline, and pass credentials.
        It will return a hastable with the computer as key and boolean as value for success
    .PARAMETER Size
        Provides the desired cache size in MB
    .PARAMETER ComputerName
        Provides computer names to set the cahce size for.
    .PARAMETER Credential
        Provides optional credentials to use for the WMI cmdlets.
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
        Created:     2019-11-6
        Updated:     2019-11-6
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [parameter(Mandatory = $true)]
        [ValidateRange(1, 99999)]
        [int]$Size,
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
        [Alias('Computer', 'PSComputerName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [parameter(Mandatory = $false)]
        [pscredential]$Credential
    )
    begin {
        $GetCacheSplat = @{
            Namespace = 'root\CCM\SoftMgmtAgent'
            Class     = 'CacheConfig'
        }
        $SetCacheSplat = @{
            Arguments = @{ Size = $Size }
        }
        $CacheSplat = @{
            ErrorAction = 'Stop'
        }
        if ($PSBoundParameters.ContainsKey('Credential')) {
            $CacheSplat['Credential'] = $Credential
        }
    }
    process {
        foreach ($Computer in $ComputerName) {
            $Return = [System.Collections.Specialized.OrderedDictionary]::new()
            $GetCacheSplat['ComputerName'] = $Computer

            try {
                if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [Size = '$Size']", "Set CCM Cache Size")) {
                    $Cache = Get-WmiObject @GetCacheSplat @CacheSplat
                    if ($Cache -is [object]) {
                        switch ($Cache.Size) {
                            $Size {
                                $Return[$Computer] = $true
                            }
                            default {
                                $SetCacheSplat['InputObject'] = $Cache
                                $WmiResult = Set-WmiInstance @CacheSplat @SetCacheSplat
                                if ($WmiResult -is [Object] -and $WmiResult.Size -eq $Size) {
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
