# TODO - Finish writing function

Function Invoke-CCMApplication {

    Param
    (
        [Parameter(Mandatory = $false)]
        [string[]]$ApplicationName,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Install', 'Uninstall', 'DownloadContents')]
        [string]$Method,
        [Parameter(Mandatory = $false)]
        [ValidateSet('Immediate', 'NonBusinessHours', 'AdminSchedule')]
        [string]$EnforcePreference = 'Immediate',
        [Parameter(Mandatory = $false)]
        [string]$Priority = 'High',
        [Parameter(Mandatory = $false)]
        [bool]$IsRebootIfNeeded = $false,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        $Application = (Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" -ComputerName $Computername | Where-Object { $_.Name -like $AppName })
        $connectionSplat = @{ }
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
                EnforcePreference = $EnforcePreferenceMap[$EnforcePreference]
                IsRebootIfNeeded  = $IsRebootIfNeeded
                Priority          = $Priority
            }
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

            foreach ($AppToInvoke in $NeedToFigureOut) {
                $invokeAppMethodArgs.Arguments['ID'] = $AppToInvoke.ID
                $invokeAppMethodSplat.Arguments['Revision'] = $AppToInvoke.Revision
                $invokeAppMethodSplat.Arguments['IsMachineTarget'] = $AppToInvoke.IsMachineTarget
                Invoke-CimMethod  -MethodName $Method -Arguments $Args
            }
        }
    }
}