function Set-CCMProvisioningMode {
    <#
        .SYNOPSIS
            Set ConfigMgr client provisioning mode to enabled or disabled, and control ProvisioningMaxMinutes
        .DESCRIPTION
            This function will allow you to set the configuration manager client provisioning mode using CIM queries.
            You can provide an array of computer names, or cimsession, or you can pass them through the pipeline.
            It will return a pscustomobject detailing the operations
        .PARAMETER Status
            Should provisioning mode be enabled, or disabled? Validate set ('Enabled','Disabled')
        .PARAMETER ProvisioningMaxMinutes
            Set the ProvisioningMaxMinutes value for provisioning mode. After this interval, provisioning mode is
            automatically disabled. This defaults to 48 hours. The client checks this every 60 minutes, so any
            value under 60 minutes will result in an effective ProvisioningMaxMinutes of 60 minutes.
        .PARAMETER CimSession
            Provides CimSessions to set provisioning mode for
        .PARAMETER ComputerName
            Provides computer names to set provisioning mode for
        .PARAMETER PSSession
            Provides PSSession to set provisioning mode for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the funtion. This is ultimately going to result in the function running faster. The typicaly usecase is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName paramter is passed to.
        .EXAMPLE
            C:\PS> Set-CCMProvisioningMode -Status Enabled
                Enables provisioning mode on the local computer
        .EXAMPLE
            C:\PS> Set-CCMProvisioningMode -ComputerName 'Workstation1234','Workstation4321' -Status Disabled
                Disables provisioning mode for Workstation1234, and Workstation4321
        .EXAMPLE
            C:\PS> Set-CCMProvisioningMode -ProvisioningMaxMinutes 360
                Sets ProvisioningMaxMinutes to 360 on the local computer so that provisioning mode is automatically
                disabled after 6 hours, instead of the default 48 hours
        .NOTES
            FileName:    Set-CCMProvisioningMode.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-09
            Updated:     2020-02-23
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [parameter(Mandatory = $false)]
        [ValidateSet('Enabled', 'Disabled')]
        [string]$Status,
        [parameter(Mandatory = $false)]
        [ValidateRange(60, [int]::MaxValue)]
        [int]$ProvisioningMaxMinutes,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession,
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [ValidateSet('CimSession', 'PSSession')]
        [string]$ConnectionPreference
    )
    begin {
        [bool]$ProvisioningMode = switch ($Status) {
            'Enabled' {
                $true
            }
            'Disabled' {
                $false
            }
        }
        $SetProvisioningModeSplat = @{
            Namespace  = 'root\CCM'
            ClassName  = 'SMS_Client'
            MethodName = 'SetClientProvisioningMode'
            Arguments  = @{
                bEnable = $ProvisioningMode
            }
        }
        $invokeCommandSplat = @{
            FunctionsToLoad = 'Set-CCMProvisioningMode', 'Get-CCMConnection'
        }
        $setCIMRegistryPropertySplat = @{
            RegRoot      = 'HKEY_LOCAL_MACHINE'
            Key          = 'Software\Microsoft\CCM\CcmExec'
            Property     = 'ProvisioningMaxMinutes'
            Value        = $ProvisioningMaxMinutes
            PropertyType = 'DWORD'
            Force        = $true
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
            $Return['ProvisioningModeChanged'] = $false
            $Return['ProvisioningMaxMinutesChanged'] = $false
            try {
                if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [ProvisioningMode = '$Status'] [ProvisioningMaxMinutes = '$ProvisioningMaxMinutes']", "Set CCM Provisioning Mode")) {
                    switch ($PSBoundParameters.Keys) {
                        'Status' {
                            $Invocation = switch ($Computer -eq $env:ComputerName) {
                                $true {
                                    Invoke-CimMethod @SetProvisioningModeSplat
                                }
                                $false {
                                    $ScriptBlock = [string]::Format('Set-CCMProvisioningMode -Status {0}', $Status)
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
                            if ($Invocation) {
                                Write-Verbose "Successfully set provisioning mode to $Status for $Computer via the 'SetClientProvisioningMode' CIM method"
                                $Return['ProvisioningModeChanged'] = $true
                            }
                        }
                        'ProvisioningMaxMinutes' {
                            # ENHANCE - Need to factor in when both actual CIM and remote work need done. Should 'everything' use CIM, or remoting? So perform this in the invoke command? Would allow for 1 session type input
                            $MaxMinutesChange = Set-CIMRegistryProperty @setCIMRegistryPropertySplat @connectionSplat
                            if ($MaxMinutesChange[$Computer]) {
                                Write-Verbose "Successfully set ProvisioningMaxMinutes for $Computer to $ProvisioningMaxMinutes"
                                $Return['ProvisioningMaxMinutesChanged'] = $true
                            }
                        }
                    }
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
