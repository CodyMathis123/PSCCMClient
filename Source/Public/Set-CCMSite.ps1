function Set-CCMSite {
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param(
        [parameter(Mandatory = $true)]
        [string]$SiteCode,
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
        $SetAssignedSiteCodeScriptBlockString = [string]::Format('(New-Object -ComObject Microsoft.SMS.Client).SetAssignedSite("{0}", 0)', $SiteCode)
        $SetAssignedSiteCodeScriptBlock = [scriptblock]::Create($SetAssignedSiteCodeScriptBlockString)
        $invokeCommandSplat = @{
            ScriptBlock = $SetAssignedSiteCodeScriptBlock
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

            $Result = [ordered]@{ }
            $Result['ComputerName'] = $Computer

            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [Site = '$SiteCode']", "Set-CCMSite")) {
                try {
                    switch ($Computer -eq $env:ComputerName) {
                        $true {
                            $SetAssignedSiteCodeScriptBlock.Invoke()
                            $Result['SiteSet'] = $true
                            [pscustomobject]$Result
                        }
                        $false {
                            Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                        }
                    }
                }
                catch {
                    $Result['SiteSet'] = $false
                    Write-Error "Failure to set MEMCM Site to $SiteCode for $Computer - $($_.Exception.Message)"
                }
            }
        }
    }
}