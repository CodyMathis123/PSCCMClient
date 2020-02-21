# TODO - Add ConnectionPreference support

function Invoke-CCMClientAction {
    <#
        .SYNOPSIS
            Invokes CM Client actions on local or remote machines
        .DESCRIPTION
            This script will allow you to invoke a set of CM Client actions on a machine (with optional credentials), providing a list of the actions and an optional delay betweens actions.
            The function will attempt for a default of 5 minutes to invoke the action, with a 10 second delay inbetween attempts. This is to account for invoke-cimmethod failures.
        .PARAMETER Schedule
            Define the schedules to run on the machine - 'HardwareInv', 'FullHardwareInv', 'SoftwareInv', 'UpdateScan', 'UpdateEval', 'MachinePol', 'AppEval', 'DDR', 'SourceUpdateMessage', 'SendUnsentStateMessage'
        .PARAMETER Delay
            Specify the delay in seconds between each schedule when more than one is ran - 0-30 seconds
        .PARAMETER Timeout
            Specifies the timeout in minutes after which any individual computer will stop attempting the schedules. Default is 5 minutes.
        .PARAMETER CimSession
            Provides CimSessions to invoke actions on
        .PARAMETER ComputerName
            Provides computer names to invoke actions on
        .PARAMETER PSSession
            Provides PSSession to invoke actions on
        .EXAMPLE
            C:\PS> Invoke-CCMClientAction -Schedule MachinePol,HardwareInv
                Start a machine policy eval and a hardware inventory cycle
        .NOTES
            FileName:    Invoke-CCMClientAction.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2018-11-20
            Updated:     2020-02-15
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ComputerName')]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('HardwareInv', 'FullHardwareInv', 'SoftwareInv', 'UpdateScan', 'UpdateEval', 'MachinePol', 'AppEval', 'DDR', 'SourceUpdateMessage', 'SendUnsentStateMessage')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Schedule,
        [parameter(Mandatory = $false)]
        [ValidateRange(0, 30)]
        [ValidateNotNullOrEmpty()]
        [int]$Delay = 0,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [int]$Timeout = 5,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession
    )
    begin {
        $invokeClientActionSplat = @{ }
        $getFullHINVSplat = @{
            Namespace   = 'root\ccm\invagt'
            ClassName   = 'InventoryActionStatus'
            ErrorAction = 'Stop'
        }
        $invokeCommandSplat = @{
            FunctionsToLoad = 'Invoke-CCMClientAction', 'Invoke-CCMTriggerSchedule', 'Get-CCMConnection'
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

            foreach ($Option in $Schedule) {
                if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [Schedule = '$Option']", "Invoke Schedule")) {
                    $Result['Action'] = $Option
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
                    try {
                        $Invocation = switch ($Computer -eq $env:ComputerName) {
                            $true {
                                if ($Option -eq 'FullHardwareInv') {
                                    $getFullHINVSplat['Filter'] = "InventoryActionID ='$Action'"

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
                                $invokeClientActionSplat['ScheduleID'] = $Action

                                Write-Verbose "Triggering a $Option Cycle on $Computer via the 'TriggerSchedule' CIM method"
                                Invoke-CCMTriggerSchedule @invokeClientActionSplat -Delay $Delay -Timeout $Timeout
                            }
                            $false {
                                $ScriptBlock = [string]::Format('Invoke-CCMClientAction -Schedule {0} -Delay {1} -Timeout {2}', $Option, $Delay, $Timeout)
                                $invokeCommandSplat['ScriptBlock'] = [scriptblock]::Create($ScriptBlock)
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
                        Start-Sleep -Seconds $Delay
                    }
                    [pscustomobject]$Result
                }
            }
        }
    }
    end {
        Write-Verbose "Following actions invoked - $Schedule"
    }
}
