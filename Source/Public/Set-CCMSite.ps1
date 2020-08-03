function Set-CCMSite {
    <#
        .SYNOPSIS
            Sets the current MEMCM Site for the MEMCM Client
        .DESCRIPTION
            This function will set the current MEMCM Site for the MEMCM Client. This is done using the Microsoft.SMS.Client COM Object.
        .PARAMETER SiteCode
            The desired MEMCM Site that will be set for the specified computers
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
            Updated:     2020-08-01
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param(
        [parameter(Mandatory = $true)]
        [string]$SiteCode,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [Alias('Session')]      
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession
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
                Prefer                     = 'PSSession'
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