function Set-CCMDNSSuffix {
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param(
        [parameter(Mandatory = $false)]
        [string]$DNSSuffix,
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
        $SetDNSSuffixScriptBlockString = [string]::Format('(New-Object -ComObject Microsoft.SMS.Client).SetDNSSuffix("{0}")', $DNSSuffix)
        $SetDNSSuffixScriptBlock = [scriptblock]::Create($SetDNSSuffixScriptBlockString)
        $invokeCommandSplat = @{
            ScriptBlock = $SetDNSSuffixScriptBlock
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
            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [DNSSuffix = '$DNSSuffix']", "Set-CCMDNSSuffix")) {
                try {
                    switch ($Computer -eq $env:ComputerName) {
                        $true {
                            $SetDNSSuffixScriptBlock.Invoke()
                        }
                        $false {
                            Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                        }
                    }
                    $Result['DNSSuffixSet'] = $true
                }
                catch {
                    $Result['DNSSuffixSet'] = $false
                    Write-Error "Failure to set DNS Suffix to $DNSSuffix for $Computer - $($_.Exception.Message)"
                }
                [pscustomobject]$Result
            }
        }
    }
}