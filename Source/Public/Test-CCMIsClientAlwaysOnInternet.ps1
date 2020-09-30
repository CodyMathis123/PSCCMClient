function Test-CCMIsClientAlwaysOnInternet {
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param(
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
        $IsClientAlwaysOnInternetScriptBlock = {
            $Client = New-Object -ComObject Microsoft.SMS.Client
            [bool]$Client.IsClientAlwaysOnInternet()
        }
        $invokeCommandSplat = @{
            ScriptBlock = $IsClientAlwaysOnInternetScriptBlock
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

            try {
                switch ($Computer -eq $env:ComputerName) {
                    $true {
                        $Result['IsClientAlwaysOnInternet'] = $IsClientAlwaysOnInternetScriptBlock.Invoke()
                    }
                    $false {
                        $Result['IsClientAlwaysOnInternet'] = Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                    }
                }
                [pscustomobject]$Result
            }
            catch {
                Write-Error "Failure to determine if the MEMCM client is set to always be on the internet for $Computer - $($_.Exception.Message)"
            }
        }
    }
}