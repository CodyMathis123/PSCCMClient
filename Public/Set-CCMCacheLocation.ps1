function Set-CCMCacheLocation {
    <#
        .SYNOPSIS
            Set ConfigMgr cache location from computers via CIM
        .DESCRIPTION
            This function will allow you to set the configuration manager cache location for multiple computers using CIM queries. 
            You can provide an array of computer names, or cimsession, or you can pass them through the pipeline.
            It will return a hashtable with the computer as key and boolean as value for success
        .PARAMETER Location
            Provides the desired cache location - note that ccmcache is appended if not provided as the end of the path
        .PARAMETER CimSession
            Provides CimSessions to set the cache location for
        .PARAMETER ComputerName
            Provides computer names to set the cache location for
        .PARAMETER PSSession
            Provides PSSessions to set the cache location for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the funtion. This is ultimately going to result in the function running faster. The typicaly usecase is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the 
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then 
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to. 
        .EXAMPLE
            C:\PS> Set-CCMCacheLocation -Location d:\windows\ccmcache
                Set cache location to d:\windows\ccmcache for local computer
        .EXAMPLE
            C:\PS> Set-CCMCacheLocation -ComputerName 'Workstation1234','Workstation4321' -Location 'C:\windows\ccmcache'
                Set Cache location to 'C:\Windows\CCMCache' for Workstation1234, and Workstation4321
        .EXAMPLE
            C:\PS> Set-CCMCacheLocation -ComputerName 'Workstation1234','Workstation4321' -Location 'C:\temp\ccmcache'
                Set Cache location to 'C:\temp\CCMCache' for Workstation1234, and Workstation4321
        .EXAMPLE
            C:\PS> Set-CCMCacheLocation -Location 'D:'
                Set Cache location to 'D:\CCMCache' for the local computer
        .NOTES
            FileName:    Set-CCMCacheLocation.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2019-11-06
            Updated:     2020-02-24
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [parameter(Mandatory = $true)]
        [ValidateScript( { -not $_.EndsWith('\') } )]
        [string]$Location,
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
        $FullCachePath = switch ($Location.EndsWith('ccmcache', 'CurrentCultureIgnoreCase')) {
            $true {
                Write-Output $Location
            }
            $false {
                Join-Path -Path $Location -ChildPath 'ccmcache'
            }
        }
        
        $GetCacheSplat = @{
            Namespace = 'root\CCM\SoftMgmtAgent'
            ClassName = 'CacheConfig'
        }
        $SetCacheScriptblock = [scriptblock]::Create([string]::Format('(New-Object -ComObject UIResource.UIResourceMgr).GetCacheInfo().Location = "{0}"', (Split-Path -Path $FullCachePath -Parent)))
        $SetCacheSplat = @{
            ScriptBlock = $SetCacheScriptblock
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
                if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [Location = '$Location']", "Set CCM Cache Location")) {
                    $Cache = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Get-CimInstance @GetCacheSplat @connectionSplat
                        }
                        $false {
                            Get-CCMCimInstance @GetCacheSplat @connectionSplat
                        }
                    }
                    if ($Cache -is [object]) {
                        switch ($Cache.Location) {
                            $FullCachePath {
                                $Return[$Computer] = $true
                            }
                            default {
                                switch ($Computer -eq $env:ComputerName) {
                                    $true {
                                        . $SetCacheScriptblock
                                    }
                                    $false {
                                        Invoke-CCMCommand @SetCacheSplat @connectionSplat
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
                                switch ($Cache.Location) {
                                    $FullCachePath {
                                        $Return[$Computer] = $true
                                    }
                                    default {       
                                        $Return[$Computer] = $false
                                    }
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
