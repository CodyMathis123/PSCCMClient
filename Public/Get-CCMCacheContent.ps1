function Get-CCMCacheContent {
    <#
        .SYNOPSIS
            Returns the content of the MEMCM cache
        .DESCRIPTION
            This function will return the content of the MEMCM cache. This is pulled from the UIResource.UIResourceMGR COM Object.
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
            Created:     2019-01-12
            Updated:     2020-01-12
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param(
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        $connectionSplat = @{ }
        $invokeCIMPowerShellSplat = @{
            FunctionsToLoad = 'Get-CCMCacheContent'
        }
    }
    process {
        foreach ($Connection in (Get-Variable -Name $PSCmdlet.ParameterSetName -ValueOnly)) {
            $Computer = switch ($PSCmdlet.ParameterSetName) {
                'ComputerName' {
                    Write-Output -InputObject $Connection
                    switch ($Connection -eq $env:ComputerName) {
                        $false {
                            if ($ExistingCimSession = Get-CimSession -ComputerName $Connection -ErrorAction Ignore) {
                                Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
                                $connectionSplat.Remove('ComputerName')
                                $connectionSplat['CimSession'] = $ExistingCimSession
                            }
                            else {
                                Write-Verbose "No active CimSession found for $Connection - falling back to -ComputerName parameter for CIM cmdlets"
                                $connectionSplat.Remove('CimSession')
                                $connectionSplat['ComputerName'] = $Connection
                            }
                        }
                        $true {
                            $connectionSplat.Remove('CimSession')
                            $connectionSplat.Remove('ComputerName')
                            Write-Verbose 'Local computer is being queried - skipping computername, and cimsession parameter'
                        }
                    }
                }
                'CimSession' {
                    Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
                    Write-Output -InputObject $Connection.ComputerName
                    $connectionSplat.Remove('ComputerName')
                    $connectionSplat['CimSession'] = $Connection
                }
            }
            $Result = [System.Collections.Specialized.OrderedDictionary]::new()
            $Result['ComputerName'] = $Computer

            $CacheContent = switch ($Computer -eq $env:ComputerName) {
                $true {
                    $Client = New-Object -ComObject UIResource.UIResourceMGR
                    $Cache = $Client.GetCacheInfo()
                    $Cache.GetCacheElements()
                }
                $false {
                    $invokeCIMPowerShellSplat['ScriptBlock'] = [scriptblock]::Create('Get-CCMCacheContent')
                    Invoke-CIMPowerShell @invokeCIMPowerShellSplat @connectionSplat
                }
            }
            foreach ($Item in $CacheContent) {
                $Result['ContentId'] = $Item.ContentId
                $Result['ContentVersion'] = $Item.ContentVersion
                $Result['Location'] = $Item.Location
                $Result['LastReferenceTime'] = $Item.LastReferenceTime
                $Result['ReferenceCount'] = $Item.ReferenceCount
                $Result['ContentSize'] = $Item.ContentSize
                $Result['CacheElementId'] = $Item.CacheElementId
                [pscustomobject]$Result
            }
        }
    }
}