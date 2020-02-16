function Set-CCMCacheSize {
    <#
    .SYNOPSIS
        Set ConfigMgr cache size from computers via UIResource.UIResourceMgr invoked over CIM
    .DESCRIPTION
        This function will allow you to set the configuration manager cache size for multiple computers using Invoke-CIMPowerShell.
        You can provide an array of computer names, cimsesions, or you can pass them through the pipeline.
        It will return a hashtable with the computer as key and boolean as value for success
    .PARAMETER Size
        Provides the desired cache size in MB
    .PARAMETER CimSession
        Provides CimSessions to set CCMCache size on
    .PARAMETER ComputerName
        Provides computer names to set CCMCache size on
    .PARAMETER PSSession
        Provides PSSession to set CCMCache size on
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
        Created:     2019-11-06
        Updated:     2020-02-15
    #>
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
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession
    )
    begin {
        $GetCacheSplat = @{
            Namespace   = 'root\CCM\SoftMgmtAgent'
            ClassName   = 'CacheConfig'
            ErrorAction = 'Stop'
        }
        $invokeCommandSplat = @{
            FunctionsToLoad = 'Set-CCMCacheSize'
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
            $Return = [ordered]@{ }

            try {
                if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [Size = '$Size']", "Set CCM Cache Size")) {
                    switch ($Computer -eq $env:ComputerName) {
                        $true {
                            $Cache = Get-CimInstance @GetCacheSplat @connectionSplat
                            if ($Cache -is [object]) {
                                switch ($Cache.Size) {
                                    $Size {
                                        $Return[$Computer] = $true
                                    }
                                    default {
                                        (New-Object -ComObject UIResource.UIResourceMgr).GetCacheInfo().TotalSize = $Size
                                        $Cache = Get-CimInstance @GetCacheSplat @connectionSplat
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
                        $false {
                            $ScriptBlock = [string]::Format('Set-CCMCacheSize -Size {0}', $Size)
                            $invokeCommandSplat['ScriptBlock'] = [scriptblock]::Create($ScriptBlock)
                            Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                        }
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
