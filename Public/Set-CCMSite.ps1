function Set-CCMSite {
    <#
        .SYNOPSIS
            Sets the current MEMCM Site for the MEMCM Client
        .DESCRIPTION
            This function will set the current MEMCM Site for the MEMCM Client. This is done using the Microsoft.SMS.Client COM Object.
        .PARAMETER SiteCode
            The desired MEMCM Site that will be set for the specified computers/cimsessions
        .PARAMETER CimSession
            Provides CimSessions to set the current MEMCM Site for
        .PARAMETER ComputerName
            Provides computer names to set the current MEMCM Site for
        .PARAMETER PSSession
            Provides PSSession to set the current MEMCM Site for
        .EXAMPLE
            C:\PS> Set-CCMSite -SiteCode 'TST'
                Sets the local computer's MEMCM Site to TST
        .EXAMPLE
            C:\PS> Set-CCMSite -ComputerName 'Workstation1234','Workstation4321' -SiteCode 'TST'
                Sets the MEMCM Site for Workstation1234, and Workstation4321 to TST
        .NOTES
            FileName:    Set-CCMSite.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-18
            Updated:     2020-02-12
    #>
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
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession
    )
    begin {
        $invokeCommandSplat = @{
            FunctionsToLoad = 'Set-CCMSite', 'Get-CCMConnection'
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

            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [Site = '$SiteCode']", "Set-CCMSite")) {
                try {
                    switch ($Computer -eq $env:ComputerName) {
                        $true {
                            $Client = New-Object -ComObject Microsoft.SMS.Client
                            $Client.SetAssignedSite($SiteCode, 0)
                            $Result['SiteSet'] = $true
                            [pscustomobject]$Result
                        }
                        $false {
                            $ScriptBlock = [string]::Format('Set-CCMSite -SiteCode "{0}"', $SiteCode)
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
                    $Result['SiteSet'] = $false
                    Write-Error "Failure to set MEMCM Site to $SiteCode for $Computer - $($_.Exception.Message)"
                }
            }
        }
    }
}