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
        .PARAMETER PSSession
            Provides PSSession to remove the provided ContentID from the MEMCM cache for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the funtion. This is ultimately going to result in the function running faster. The typicaly usecase is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determins what type of connection / command
            the ComputerName paramter is passed to.
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
            Updated:     2020-02-23
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
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession,
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [ValidateSet('CimSession', 'PSSession')]
        [string]$ConnectionPreference
    )
    begin {
        switch ($PSBoundParameters.Keys -contains 'ContentID' -and $PSBoundParameters.Keys -contains 'Clear') {
            $true {
                Write-Error -ErrorAction Stop -Message 'Both ContentID and Clear parameters provided - please only provide one. Note that ParameterSetName is in use, but is currently being used for CimSession/ComputerName distinction. Feel free to make a pull request ;)'
            }
        }
        $invokeCommandSplat = @{
            FunctionsToLoad = 'Remove-CCMCacheContent', 'Get-CCMConnection'
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

            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [ContentID = '$([string]::Join('; ', $ContentID))]'", "Remove-CCMCacheContent")) {
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
                        $invokeCommandSplat['ScriptBlock'] = [scriptblock]::Create($ScriptBlock)
                        Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                    }
                }
            }
        }
    }
}