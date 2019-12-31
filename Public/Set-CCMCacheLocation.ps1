function Set-CCMCacheLocation {
    <#
    .SYNOPSIS
        Set ConfigMgr cache location from computers via WMI
    .DESCRIPTION
        This function will allow you to set the configuration manager cache location for multiple computers using WMI queries. 
        You can provide an array of computer names, or you can pass them through the pipeline, and pass credentials.
        It will return a hastable with the computer as key and boolean as value for success
    .PARAMETER Location
        Provides the desired cache location
    .PARAMETER ComputerName
        Provides computer names to set the cache location for.
    .PARAMETER Credential
        Provides optional credentials to use for the WMI cmdlets.
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
        Created:     2019-11-6
        Updated:     2019-11-6
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [parameter(Mandatory = $true)]
        [string]$Location,
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
        [Alias('Computer', 'PSComputerName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [parameter(Mandatory = $false)]
        [pscredential]$Credential
    )
    begin {
        $Return = [System.Collections.Specialized.OrderedDictionary]::new()
        
        $GetCacheSplat = @{
            Namespace = 'root\CCM\SoftMgmtAgent'
            Class     = 'CacheConfig'
        }
        $SetCacheSplat = @{
            Arguments = @{ Location = $Location }
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
                if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [Location = '$Location']", "Set CCM Cache Location")) {
                    $Cache = Get-WmiObject @GetCacheSplat @CacheSplat
                    if ($Cache -is [object]) {
                        switch ($Cache.Location) {
                            $Location {
                                $Return[$Computer] = $true
                            }
                            default {
                                $SetCacheSplat['InputObject'] = $Cache
                                $WmiResult = Set-WmiInstance @CacheSplat @SetCacheSplat
                                if ($WmiResult -is [Object] -and $WmiResult.Location -eq $Location) {
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
