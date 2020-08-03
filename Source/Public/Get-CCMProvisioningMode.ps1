function Get-CCMProvisioningMode {
    <#
        .SYNOPSIS
            Get ConfigMgr client provisioning mode info
        .DESCRIPTION
            This function will allow you to get the configuration manager client provisioning mode info using CIM queries.
            You can provide an array of computer names, or cimsession, or you can pass them through the pipeline.
            It will return a pscustomobject detailing provisioning mode
        .PARAMETER CimSession
            Provides CimSessions to get provisioning mode for
        .PARAMETER ComputerName
            Provides computer names to get provisioning mode for
        .PARAMETER PSSession
            Provides PSSessions to get provisioning mode for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Get-CCMProvisioningMode -Status Enabled
                Retrieves provisioning mode info from the local computer
        .EXAMPLE
            C:\PS> Get-CCMProvisioningMode -ComputerName 'Workstation1234','Workstation4321'
                Retrieves provisioning mode info from Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMProvisioningMode.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-09
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
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
        $getCIMRegistryPropertySplat = @{
            RegRoot  = 'HKEY_LOCAL_MACHINE'
            Key      = 'Software\Microsoft\CCM\CcmExec'
            Property = 'ProvisioningMode', 'ProvisioningEnabledTime', 'ProvisioningMaxMinutes'
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

            $Return = [ordered]@{ }
            $Return['ComputerName'] = $Computer
            try {
                $ProvisioningModeInfo = Get-CCMRegistryProperty @getCIMRegistryPropertySplat @connectionSplat
                if ($ProvisioningModeInfo -is [object]) {
                    $Return['ProvisioningMode'] = $ProvisioningModeInfo.$Computer.ProvisioningMode
                    $EnabledTime = switch ([string]::IsNullOrWhiteSpace($ProvisioningModeInfo.$Computer.ProvisioningEnabledTime)) {
                        $false {
                            [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($ProvisioningModeInfo.$Computer.ProvisioningEnabledTime))
                        }
                    }
                    $Return['ProvisioningEnabledTime'] = $EnabledTime
                    $Return['ProvisioningMaxMinutes'] = $ProvisioningModeInfo.$Computer.ProvisioningMaxMinutes
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
            [pscustomobject]$Return
        }
    }
}
