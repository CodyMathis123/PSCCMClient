function Set-CCMDNSSuffix {
    <#
        .SYNOPSIS
            Sets the current DNS suffix for the MEMCM Client
        .DESCRIPTION
            This function will set the current DNS suffix for the MEMCM Client. This is done using the Microsoft.SMS.Client COM Object.
        .PARAMETER DNSSuffix
            The desired DNS Suffix that will be set for the specified computers/cimsessions
        .PARAMETER CimSession
            Provides CimSessions to set the current DNS suffix for
        .PARAMETER ComputerName
            Provides computer names to set the current DNS suffix for
        .PARAMETER PSSession
            Provides PSSession to set the current DNS suffix for
        .EXAMPLE
            C:\PS> Set-CCMDNSSuffix -DNSSuffix 'contoso.com'
                Sets the local computer's DNS Suffix to contoso.com
        .EXAMPLE
            C:\PS> Set-CCMDNSSuffix -ComputerName 'Workstation1234','Workstation4321' -DNSSuffix 'contoso.com'
                Sets the DNS Suffix for Workstation1234, and Workstation4321 to contoso.com
        .NOTES
            FileName:    Set-CCMDNSSuffix.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-18
            Updated:     2020-02-14
    #>
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
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession
    )
    begin {
        $invokeCommandSplat = @{
            FunctionsToLoad = 'Set-CCMDNSSuffix', 'Get-CCMConnection'
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
            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [DNSSuffix = '$DNSSuffix']", "Set-CCMDNSSuffix")) {
                try {
                    switch ($Computer -eq $env:ComputerName) {
                        $true {
                            $Client = New-Object -ComObject Microsoft.SMS.Client
                            $Client.SetDNSSuffix($DNSSuffix)
                        }
                        $false {
                            $ScriptBlock = [string]::Format('Set-CCMDNSSuffix -DNSSuffix {0}', $DNSSuffix)
                            $invokeCommandSplat['ScriptBlock'] = [scriptblock]::Create($ScriptBlock)
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