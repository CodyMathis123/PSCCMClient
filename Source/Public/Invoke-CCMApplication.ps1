Function Invoke-CCMApplication {
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ID,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [bool[]]$IsMachineTarget,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$Revision,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Install', 'Uninstall')]
        [Alias('Action')]
        [string]$Method,
        [Parameter(Mandatory = $false)]
        [ValidateSet('Immediate', 'NonBusinessHours', 'AdminSchedule')]
        [string]$EnforcePreference = 'Immediate',
        [Parameter(Mandatory = $false)]
        [ValidateSet('Foreground', 'High', 'Normal', 'Low')]
        [string]$Priority = 'High',
        [Parameter(Mandatory = $false)]
        [bool]$IsRebootIfNeeded = $false,
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
        $EnforcePreferenceMap = @{
            'Immediate'        = [uint32]0
            'NonBusinessHours' = [uint32]1
            'AdminSchedule'    = [uint32]2
        }
        $invokeAppMethodSplat = @{
            NameSpace  = 'root\CCM\ClientSDK'
            ClassName  = 'CCM_Application'
            MethodName = $Method
            Arguments  = @{
                Priority          = $Priority
                EnforcePreference = $EnforcePreferenceMap[$EnforcePreference]
                IsRebootIfNeeded  = $IsRebootIfNeeded
            }
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
            $Result['AppMethodInvoked'] = $false

            foreach ($AppID in $ID) {
                if ($PSCmdlet.ShouldProcess("[Method = '$Method'] [ID = '$AppID'] [ComputerName = '$Computer']", "Invoke-CCMApplication")) {
                    $invokeAppMethodSplat.Arguments['ID'] = [string]$AppID
                    $invokeAppMethodSplat.Arguments['Revision'] = [string]$Revision
                    $invokeAppMethodSplat.Arguments['IsMachineTarget'] = [bool]$IsMachineTarget
                    try {
                        $Invocation = switch -regex ($ConnectionInfo.ConnectionType) {
                            '^CimSession$|^ComputerName$' {
                                Invoke-CimMethod @invokeAppMethodSplat @connectionSplat
                            }
                            '^PSSession$' {
                                $InvokeCommandSplat = @{
                                    ArgumentList = $invokeAppMethodSplat
                                    ScriptBlock  = {
                                        param($invokeAppMethodSplat)
                                        Invoke-CimMethod @invokeAppMethodSplat
                                    }
                                }
                                Invoke-CCMCommand @InvokeCommandSplat @connectionSplat
                            }
                        }

                        switch ($Invocation.ReturnValue) {
                            0 {
                                $Result['AppMethodInvoked'] = $true
                            }
                        }
                    }
                    catch {
                        Write-Error "Failed to invoke [Method = '$Method'] [ID = '$AppID'] [ComputerName = '$Computer'] - $($_.Exception.Message)"
                    }
                    [pscustomobject]$Result
                }
            }
        }
    }
}