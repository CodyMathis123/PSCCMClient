function Set-CCMProvisioningMode {
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
        [Alias('Session')]
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
                                    $invokeCommandSplat = @{
                                        ArgumentList = $SetProvisioningModeSplat
                                        ScriptBlock  = {
                                            param($StatuSetProvisioningModeSplats)
                                            Invoke-CimMethod @SetProvisioningModeSplat
                                        }
                                    }
                                    Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                                }
                            }
                            if ($Invocation) {
                                Write-Verbose "Successfully set provisioning mode to $Status for $Computer via the 'SetClientProvisioningMode' CIM method"
                                $Return['ProvisioningModeChanged'] = $true
                            }
                        }
                        'ProvisioningMaxMinutes' {
                            $MaxMinutesChange = Set-CCMRegistryProperty @setCIMRegistryPropertySplat @connectionSplat
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
