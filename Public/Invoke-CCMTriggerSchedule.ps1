
function Invoke-CCMTriggerSchedule {
    <#
        .SYNOPSIS
            Triggers the specified ScheduleID on local, or remote computers
        .DESCRIPTION
            This script will allow you to invoke the specified ScheduleID on a machine (with optional credentials), providing an optional delay between invokes.
            The function will attempt for a default of 5 minutes to invoke the action, with a 10 second delay inbetween attempts. This is to account for invoke-cimmethod failures.
        .PARAMETER ScheduleID
            Define the schedule IDs to run on the machine, typically found by query another area of WMI
        .PARAMETER Delay
            Specify the delay in seconds between each schedule when more than one is ran - 0-30 seconds
        .PARAMETER Timeout
            Specifies the timeout in minutes after which any individual computer will stop attempting to invoke the schedule IDs. Default is 5 minutes.
        .PARAMETER CimSession
            Provides CimSessions to invoke IDs on
        .PARAMETER ComputerName
            Provides computer names to invoke IDs on
        .PARAMETER PSSession
            Provides PSSession to invoke IDs on
        .EXAMPLE
            C:\PS> Invoke-CCMTriggerSchedule -ScheduleID TST20000
                Performs a TriggerSchedule operation on the TST20000 ScheduleID for the local computer using the default values for Delay and Timeout
        .EXAMPLE
            C:\PS> Invoke-CCMTriggerSchedule -ScheduleID '{00000000-0000-0000-0000-000000000021}'
                Performs a TriggerSchedule operation on the {00000000-0000-0000-0000-000000000021} ScheduleID (Machine Policy Refresh) for the local
                computer using the default values for Delay and Timeout
        .NOTES
            FileName:    Invoke-CCMTriggerSchedule.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-11
            Updated:     2020-02-12
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ComputerName')]
    param
    (
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ScheduleID,
        [parameter(Mandatory = $false)]
        [ValidateRange(0, 30)]
        [int]$Delay = 0,
        [parameter(Mandatory = $false)]
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
        $TimeSpan = New-TimeSpan -Minutes $Timeout
        
        $invokeClientActionSplat = @{
            MethodName  = 'TriggerSchedule'
            Namespace   = 'root\ccm'
            ClassName   = 'sms_client'
            ErrorAction = 'Stop'
        }
        $invokeCommandSplat = @{
            FunctionsToLoad = 'Invoke-CCMTriggerSchedule', 'Get-CCMConnection'
        }
    }
    process {
        foreach ($ID in $ScheduleID) {
            foreach ($Connection in (Get-Variable -Name $PSCmdlet.ParameterSetName -ValueOnly)) {
                $getConnectionInfoSplat = @{
                    $PSCmdlet.ParameterSetName = $Connection
                }
                $ConnectionInfo = Get-CCMConnection @getConnectionInfoSplat
                $Computer = $ConnectionInfo.ComputerName
                $connectionSplat = $ConnectionInfo.connectionSplat

                $Result = [ordered]@{ }
                $Result['ComputerName'] = $Computer

                if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [ScheduleID = '$ID']", "Invoke ScheduleID")) {
                    $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
                    do {
                        try {
                            Remove-Variable MustExit -ErrorAction SilentlyContinue
                            Remove-Variable Invocation -ErrorAction SilentlyContinue
                            $invokeClientActionSplat['Arguments'] = @{
                                sScheduleID = $ID
                            }

                            Write-Verbose "Triggering a [ScheduleID = '$ID'] on $Computer via the 'TriggerSchedule' CIM method"
                            $Invocation = switch ($Computer -eq $env:ComputerName) {
                                $true {
                                    Invoke-CimMethod @invokeClientActionSplat
                                }
                                $false {
                                    $ScriptBlock = [string]::Format('Invoke-CCMTriggerSchedule -ScheduleID "{0}" -Delay {1} -Timeout {2}', $ID, $Delay, $Timeout)
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
                        }
                        catch [System.UnauthorizedAccessException] {
                            Write-Error -Message "Access denied to $Computer" -Category AuthenticationError -Exception $_.Exception
                            $MustExit = $true
                        }
                        catch {
                            Write-Warning "Failed to invoke the $ID ScheduleID via CIM. Will retry every 10 seconds until [StopWatch $($StopWatch.Elapsed) -ge $Timeout minutes] Error: $($_.Exception.Message)"
                            Start-Sleep -Seconds 10
                        }
                    }
                    until ($Invocation -or $StopWatch.Elapsed -ge $TimeSpan -or $MustExit)
                    if ($Invocation) {
                        Write-Verbose "Successfully invoked the $ID ScheduleID on $Computer via the 'TriggerSchedule' CIM method"
                        $Result['Invoked'] = $true
                        Start-Sleep -Seconds $Delay
                    }
                    elseif ($StopWatch.Elapsed -ge $TimeSpan) {
                        Write-Error "Failed to invoke the $ID ScheduleID via CIM after $Timeout minutes of retrying."
                        $Result['Invoked'] = $false
                    }
                    $StopWatch.Reset()
                    [pscustomobject]$Result
                }
            }
        }
    }
}
