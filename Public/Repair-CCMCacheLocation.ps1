function Repair-CCMCacheLocation {
    <#
    .SYNOPSIS
        Repairs ConfigMgr cache location from computers via WMI. This cleans up \\ and ccmcache\ccmcache in path
    .DESCRIPTION
        This function will allow you to clean the existing cache path for multiple computers using WMI queries. 
        You can provide an array of computer names, or you can pass them through the pipeline, and pass credentials.
        It will return a hastable with the computer as key and boolean as value for success
    .PARAMETER ComputerName
        Provides computer names to set the cache location for.
    .PARAMETER Credential
        Provides optional credentials to use for the WMI cmdlets.
    .EXAMPLE
        C:\PS> Repair-CCMCacheLocation -Location d:\windows\ccmcache
            Repair cache for local computer
    .EXAMPLE
        C:\PS> Repair-CCMCacheLocation -ComputerName 'Workstation1234','Workstation4321'
            Repair Cache location for Workstation1234, and Workstation4321
    .NOTES
        FileName:    Repair-CCMCacheLocation.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2019-11-6
        Updated:     2019-11-6
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
        [Alias('Computer', 'PSComputerName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [parameter(Mandatory = $false)]
        [pscredential]$Credential
    )
    begin {
        $Return = @{ }
        
        $GetCCMCacheSplat = @{ }
        $SetCCMCacheSplat = @{ }
        if ($PSBoundParameters.ContainsKey('Credential')) {
            $GetCCMCacheSplat['Credential'] = $Credential
            $SetCCMCacheSplat['Credential'] = $Credential
        }
    }
    process {
        foreach ($Computer in $ComputerName) {
            $GetCCMCacheSplat['ComputerName'] = $Computer
            $SetCCMCacheSplat['ComputerName'] = $Computer

            try {
                if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer']", "Repair CCM Cache Location")) {
                    $Cache = Get-CCMCache @GetCCMCacheSplat
                    if ($Cache -is [hashtable]) {
                        $CurrentLocation = $Cache.$Computer.Location
                        $NewLocation = $CurrentLocation -replace '\\\\', '\' -replace 'ccmcache\\ccmcache', 'ccmcache' 
                        switch ($NewLocation -eq $CurrentLocation) {
                            $true {
                                $Return[$Computer] = $true
                            }
                            $false {
                                $SetCCMCacheSplat['Location'] = $NewLocation
                                $SetCache = Set-CCMCacheLocation @SetCCMCacheSplat
                                $Return[$Computer] = $SetCache.$Computer
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