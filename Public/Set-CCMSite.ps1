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
            Updated:     2020-01-29
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param(
        [parameter(Mandatory = $true)]
        [string]$SiteCode,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        $connectionSplat = @{ }
        $invokeCIMPowerShellSplat = @{
            FunctionsToLoad = 'Set-CCMSite'
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
                            $invokeCIMPowerShellSplat['ScriptBlock'] = [scriptblock]::Create($ScriptBlock)
                            Invoke-CIMPowerShell @invokeCIMPowerShellSplat @connectionSplat
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