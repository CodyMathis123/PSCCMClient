function Test-CCMIsClientAlwaysOnInternet {
    <#
        .SYNOPSIS
            Return the status of the MEMCM client having AlwaysOnInternet set
        .DESCRIPTION
            This function will invoke the IsClientAlwaysOnInternet of the MEMCM Client.
             This is done using the Microsoft.SMS.Client COM Object.
        .PARAMETER CimSession
            Provides CimSessions to return AlwaysOnInternet setting info from
        .PARAMETER ComputerName
            Provides computer names to return AlwaysOnInternet setting info from
        .PARAMETER PSSession
            Provides PSSession to return AlwaysOnInternet setting info from
        .EXAMPLE
            C:\PS> Test-CCMIsClientAlwaysOnInternet
                Returns the status of the local computer having IsAlwaysOnInternet set
        .EXAMPLE
            C:\PS> Test-CCMIsClientAlwaysOnInternet -ComputerName 'Workstation1234','Workstation4321'
                Returns the status of 'Workstation1234','Workstation4321' having IsAlwaysOnInternet set
        .NOTES
            FileName:    Test-CCMIsClientAlwaysOnInternet.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-29
            Updated:     2020-02-12
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param(
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession
    )
    begin {
        $invokeCommandSplat = @{
            FunctionsToLoad = 'Test-CCMIsClientAlwaysOnInternet', 'Get-CCMConnection'
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
            $Result = [ordered]@{ }
            $Result['ComputerName'] = $Computer

            try {
                switch ($Computer -eq $env:ComputerName) {
                    $true {
                        $Client = New-Object -ComObject Microsoft.SMS.Client
                        $Result['IsClientAlwaysOnInternet'] = [bool]$Client.IsClientAlwaysOnInternet()
                        [pscustomobject]$Result
                    }
                    $false {
                        $ScriptBlock = 'Test-CCMIsClientAlwaysOnInternet'
                        $invokeCommandSplat['ScriptBlock'] = [scriptblock]::Create($ScriptBlock)
                        switch ($ConnectionInfo.ConnectionType) {
                            'CimSession' {
                                Invoke-CIMPowerShell @invokeCommandSplat @connectionSplat
                            }
                            'PSSession' {
                                Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                            }
                        }
                    }
                }
            }
            catch {
                Write-Error "Failure to determine if the MEMCM client is set to always be on the internet for $Computer - $($_.Exception.Message)"
            }
        }
    }
}