function Set-CCMManagementPoint {
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    [Alias('Set-CCMMP')]
    param(
        [parameter(Mandatory = $true)]
        [string]$ManagementPointFQDN,
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
        $SetCurrentManagementPointScriptBlockString = [string]::Format('(New-Object -ComObject Microsoft.SMS.Client).SetCurrentManagementPoint("{0}", 1)', $ManagementPointFQDN)
        $SetCurrentManagementPointScriptBlock = [scriptblock]::Create($SetCurrentManagementPointScriptBlockString)
        $invokeCommandSplat = @{
            ScriptBlock = $SetCurrentManagementPointScriptBlock
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
            $Result['ManagementPointFQDNSet'] = $false

            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [ManagementPointFQDN = '$ManagementPointFQDN']", "Set-CCMManagementPoint")) {
                try {
                    switch ($Computer -eq $env:ComputerName) {
                        $true {
                            $SetCurrentManagementPointScriptBlock.Invoke()
                        }
                        $false {
                            Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                        }
                    }
                    $Result['ManagementPointFQDNSet'] = $true
                }
                catch {
                    Write-Error "Failure to set management point to $ManagementPointFQDN for $Computer - $($_.Exception.Message)"
                }
                [pscustomobject]$Result
            }
        }
    }
}