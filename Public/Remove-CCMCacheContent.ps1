function Remove-CCMCacheContent {
    <#
        .SYNOPSIS
            Removes the provided ContentID from the MEMCM cache
        .DESCRIPTION
            This function will remove the provided ContentID from the MEMCM cache. This is done using the UIResource.UIResourceMGR COM Object.
        .PARAMETER ContentID
            ContentID that you want removed from the MEMCM cache. An array can be provided
        .PARAMETER Clear
            Remove all content from the MEMCM cache
        .PARAMETER Force
            Remove content from the cache, even if it is marked for 'persist content in client cache'
        .PARAMETER CimSession
            Provides CimSessions to remove the provided ContentID from the MEMCM cache for
        .PARAMETER ComputerName
            Provides computer names to remove the provided ContentID from the MEMCM cache for
        .EXAMPLE
            C:\PS> Remove-CCMCacheContent -Clear
                Clears the local MEMCM cache
        .EXAMPLE
            C:\PS> Remove-CCMCacheContent -ComputerName 'Workstation1234','Workstation4321' -ContentID TST002FE
                Removes ContentID TST002FE from the MEMCM cache for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Remove-CCMCacheContent.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-12
            Updated:     2020-01-12
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param(
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ContentID,
        [parameter(Mandatory = $false)]
        [switch]$Clear,
        [parameter(Mandatory = $false)]
        [switch]$Force,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        switch ($PSBoundParameters.Keys -contains 'ContentID' -and $PSBoundParameters.Keys -contains 'Clear') {
            $true {
                Write-Error -ErrorAction Stop -Message 'Both ContentID and Clear parameters provided - please only provide one. Note that ParameterSetName is in use, but is currently being used for CimSession/ComputerName distinction. Feel free to make a pull request ;)'
            }
        }
        $connectionSplat = @{ }
        $invokeCIMPowerShellSplat = @{
            FunctionsToLoad = 'Remove-CCMCacheContent'
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
            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [ContentID = '$($ContentID -join '; ')]'", "Remove-CCMCacheContent")) {
                $removeCacheContentArgs = switch ($PSBoundParameters.Keys) {
                    'ContentID' {
                        [string]::Format('-ContentID "{0}"', [string]::Join('", "', $ContentID))
                    }
                    'Clear' {
                        '-Clear'
                    }
                    'Force' {
                        '-Force'
                    }
                }
                switch ($Computer -eq $env:ComputerName) {
                    $true {
                        $Client = New-Object -ComObject UIResource.UIResourceMGR
                        $Cache = $Client.GetCacheInfo()
                        $CacheContent = $Cache.GetCacheElements()
                        foreach ($ID in $ContentID) {
                            foreach ($CacheItem in $CacheContent) {
                                $CacheElementToRemove = switch ($PSBoundParameters.Keys) {
                                    'ContentID' {
                                        switch ($CacheItem.ContentID -eq $ID) {
                                            $true {
                                                $CacheItem.CacheElementId
                                            }
                                        }
                                    }
                                    'Clear' {
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
                    }
                    $false {
                        $ScriptBlock = [string]::Format('Remove-CCMCacheContent {0}', [string]::Join(' ', $removeCacheContentArgs))
                        $invokeCIMPowerShellSplat['ScriptBlock'] = [scriptblock]::Create($ScriptBlock)
                        Invoke-CIMPowerShell @invokeCIMPowerShellSplat @connectionSplat
                    }
                }
            }
        }
    }
}