
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
        .EXAMPLE
            C:\PS> Invoke-CCMClientAction -Schedule MachinePol,HardwareInv
                Start a machine policy eval and a hardware inventory cycle
        .NOTES
            FileName:    Invoke-CCMClientAction.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2018-11-20
            Updated:     2020-01-11
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
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        $TimeSpan = New-TimeSpan -Minutes $Timeout

        $connectionSplat = @{ }
        $invokeClientActionSplat = @{ }
        $getFullHINVSplat = @{
            Namespace   = 'root\ccm\invagt'
            ClassName   = 'InventoryActionStatus'
            ErrorAction = 'Stop'
        }
        $invokeCIMPowerShellSplat = @{
            FunctionsToLoad = 'Invoke-CCMClientAction', 'Invoke-CCMTriggerSchedule'
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
                    $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
                    do {
                        try {
                            Remove-Variable MustExit -ErrorAction SilentlyContinue
                            Remove-Variable Invocation -ErrorAction SilentlyContinue
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
                            $Invocation = switch ($Computer -eq $env:ComputerName) {
                                $true {
                                    Invoke-CCMTriggerSchedule @invokeClientActionSplat
                                }
                                $false {
                                    $ScriptBlock = [string]::Format('Invoke-CCMClientAction -Schedule {0} -Delay {1} -Timeout {2}', $Option, $Delay, $Timeout)
                                    $invokeCIMPowerShellSplat['ScriptBlock'] = [scriptblock]::Create($ScriptBlock)
                                    Invoke-CIMPowerShell @invokeCIMPowerShellSplat @connectionSplat
                                }
                            }
                        }
                        catch [System.UnauthorizedAccessException] {
                            Write-Error -Message "Access denied to $Computer" -Category AuthenticationError -Exception $_.Exception
                            $MustExit = $true
                        }
                        catch {
                            Write-Warning "Failed to invoke the $Option cycle via CIM. Will retry every 10 seconds until [StopWatch $($StopWatch.Elapsed) -ge $Timeout minutes] Error: $($_.Exception.Message)"
                            Start-Sleep -Seconds 10
                        }
                    }
                    until ($Invocation -or $StopWatch.Elapsed -ge $TimeSpan -or $MustExit)
                    if ($Invocation) {
                        Write-Verbose "Successfully invoked the $Option Cycle on $Computer via the 'TriggerSchedule' CIM method"
                        $Result['Invoked'] = $true
                        Start-Sleep -Seconds $Delay
                    }
                    elseif ($StopWatch.Elapsed -ge $TimeSpan) {
                        Write-Error "Failed to invoke $Option cycle via CIM after $Timeout minutes of retrying."
                        $Result['Invoked'] = $false
                    }
                    $StopWatch.Reset()
                    [pscustomobject]$Result
                }
            }
        }
    }
    end {
        Write-Verbose "Following actions invoked - $Schedule"
    }
}
