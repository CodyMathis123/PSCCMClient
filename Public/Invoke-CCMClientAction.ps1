function Invoke-CCMClientAction {
    <#
        .SYNOPSIS
            Invokes MEMCM Client actions on local or remote machines
        .DESCRIPTION
            This script will allow you to invoke a set of MEMCM Client actions on a machine, providing a list of the actions
        .PARAMETER Schedule
            Define the schedules to run on the machine - 'HardwareInv', 'FullHardwareInv', 'SoftwareInv', 'UpdateScan', 'UpdateEval', 'MachinePol', 'AppEval', 'DDR', 'SourceUpdateMessage', 'SendUnsentStateMessage'
        .PARAMETER CimSession
            Provides CimSessions to invoke actions on
        .PARAMETER ComputerName
            Provides computer names to invoke actions on
        .PARAMETER PSSession
            Provides PSSession to invoke actions on
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the funtion. This is ultimately going to result in the function running faster. The typicaly usecase is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Invoke-CCMClientAction -Schedule MachinePol,HardwareInv
                Start a machine policy eval and a hardware inventory cycle
        .NOTES
            FileName:    Invoke-CCMClientAction.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2018-11-20
            Updated:     2020-03-02
    #>
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
        $invokeClientActionSplat = @{ }
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
                                $invokeClientActionSplat['ScheduleID'] = $Action

                                Write-Verbose "Triggering a $Option Cycle on $Computer via the 'TriggerSchedule' CIM method"
                                Invoke-CCMTriggerSchedule @invokeClientActionSplat
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
                                $invokeClientActionSplat = @{
                                    MethodName  = 'TriggerSchedule'
                                    Namespace   = 'root\ccm'
                                    ClassName   = 'sms_client'
                                    ErrorAction = 'Stop'
                                    Arguments = @{
                                        sScheduleID = $Action
                                    }
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