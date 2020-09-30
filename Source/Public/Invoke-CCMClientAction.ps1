function Invoke-CCMClientAction {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ComputerName')]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('HardwareInv', 'FullHardwareInv', 'SoftwareInv', 'UpdateScan', 'UpdateEval', 'MachinePol', 'AppEval', 'DDR', 'SourceUpdateMessage', 'SendUnsentStateMessage')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Schedule,
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
        $invokeClientActionSplat = @{
            MethodName  = 'TriggerSchedule'
            Namespace   = 'root\ccm'
            ClassName   = 'sms_client'
            ErrorAction = 'Stop'
        }

        $getFullHINVSplat = @{
            Namespace   = 'root\ccm\invagt'
            ClassName   = 'InventoryActionStatus'
            ErrorAction = 'Stop'
            Filter      = "InventoryActionID ='{00000000-0000-0000-0000-000000000001}'"
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

            foreach ($Option in $Schedule) {
                if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [Schedule = '$Option']", "Invoke Schedule")) {
                    $Result['Action'] = $Option
                    $Result['Invoked'] = $false
                    $Action = switch -Regex ($Option) {
                        '^HardwareInv$|^FullHardwareInv$' {
                            '{00000000-0000-0000-0000-000000000001}'
                        }
                        'SoftwareInv' {
                            '{00000000-0000-0000-0000-000000000002}'
                        }
                        'UpdateScan' {
                            '{00000000-0000-0000-0000-000000000113}'
                        }
                        'UpdateEval' {
                            '{00000000-0000-0000-0000-000000000108}'
                        }
                        'MachinePol' {
                            '{00000000-0000-0000-0000-000000000021}'
                        }
                        'AppEval' {
                            '{00000000-0000-0000-0000-000000000121}'
                        }
                        'DDR' {
                            '{00000000-0000-0000-0000-000000000003}'
                        }
                        'SourceUpdateMessage' {
                            '{00000000-0000-0000-0000-000000000032}'
                        }
                        'SendUnsentStateMessage' {
                            '{00000000-0000-0000-0000-000000000111}'
                        }
                    }

                    $invokeClientActionSplat['Arguments'] =  @{
                        sScheduleID = $Action
                    }

                    try {
                        $Invocation = switch ($Computer -eq $env:ComputerName) {
                            $true {
                                if ($Option -eq 'FullHardwareInv') {
                                    Write-Verbose "Attempting to delete Hardware Inventory history for $Computer as a FullHardwareInv was requested"
                                    $HWInv = Get-CimInstance @getFullHINVSplat @connectionSplat
                                    if ($null -ne $HWInv) {
                                        Remove-CimInstance -InputObject $HWInv
                                        Write-Verbose "Hardware Inventory history deleted for $Computer"
                                    }
                                    else {
                                        Write-Verbose "No Hardware Inventory history to delete for $Computer"
                                    }
                                }

                                Write-Verbose "Triggering a $Option Cycle on $Computer via the 'TriggerSchedule' CIM method"
                                Invoke-CimMethod @invokeClientActionSplat
                            }
                            $false {
                                $invokeCommandSplat = @{ }

                                if ($Option -eq 'FullHardwareInv') {
                                    $invokeCommandSplat['ScriptBlock'] = {
                                        param($getFullHINVSplat)
                                        $HWInv = Get-CimInstance @getFullHINVSplat
                                        if ($null -ne $HWInv) {
                                            Remove-CimInstance -InputObject $HWInv
                                        }
                                    }
                                    $invokeCommandSplat['ArgumentList'] = $getFullHINVSplat
                                    Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                                }

                                $invokeCommandSplat['ScriptBlock'] = {
                                    param($invokeClientActionSplat)
                                    Invoke-CimMethod @invokeClientActionSplat
                                }
                                $invokeCommandSplat['ArgumentList'] = $invokeClientActionSplat
                                Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                            }
                        }
                    }
                    catch [System.UnauthorizedAccessException] {
                        Write-Error -Message "Access denied to $Computer" -Category AuthenticationError -Exception $_.Exception
                    }
                    catch {
                        Write-Warning "Failed to invoke the $Option cycle via CIM. Error: $($_.Exception.Message)"
                    }
                    if ($Invocation) {
                        Write-Verbose "Successfully invoked the $Option Cycle on $Computer via the 'TriggerSchedule' CIM method"
                        $Result['Invoked'] = $true
                    }
                    [pscustomobject]$Result
                }
            }
        }
    }
}