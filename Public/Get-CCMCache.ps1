function Get-CCMCache {
    <#
    .SYNOPSIS
        Get ConfigMgr client cache directory info from computers via WMI
    .DESCRIPTION
        This function will allow you to gather the ConfigMgr client cache directory info from multiple computers using WMI queries.
        You can provide an array of computer names, or you can pass them through the pipeline, and pass credentials.
    .PARAMETER ComputerName
        Provides computer names to gather cache info from.
    .PARAMETER Credential
        Provides optional credentials to use for the WMI cmdlets.
    .EXAMPLE
        C:\PS> Get-CCMCache
            Return ConfigMgr client cache directory info for the local computer
    .EXAMPLE
        C:\PS> Get-CCMCache -ComputerName 'Workstation1234','Workstation4321'
            Return ConfigMgr client cache directory info for Workstation1234, and Workstation4321
    .NOTES
        FileName:    Get-CCMCache.ps1
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
        $getWmiObjectSplat = @{
            Namespace   = 'root\CCM\SoftMgmtAgent'
            Class       = 'CacheConfig'
            ErrorAction = 'Stop'
        }
        if ($PSBoundParameters.ContainsKey('Credential')) {
            $getWmiObjectSplat['Credential'] = $Credential
        }
    }
    process {
        foreach ($Computer in $ComputerName) {
            $Return = [System.Collections.Specialized.OrderedDictionary]::new()
            $Result = [System.Collections.Specialized.OrderedDictionary]::new()
            $Result['ComputerName'] = $Computer
            $getWmiObjectSplat['ComputerName'] = $Computer

            try {
                [System.Management.ManagementObject[]]$WmiResult = Get-WmiObject @getWmiObjectSplat
                if ($WmiResult -is [Object] -and $WmiResult.Count -gt 0) {
                    $Return[$Computer] = foreach ($Object in $WmiResult) {
                        $Result['Location'] = $Object.Location
                        $Result['Size'] = $Object.Size
                        [PSCustomObject]$Result 
                    }
                }
                else {
                    $Result['Location'] = $null
                    $Result['Size'] = $null
                    $Return[$Computer] = [PSCustomObject]$Result
                }
                Write-Output $Return
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
