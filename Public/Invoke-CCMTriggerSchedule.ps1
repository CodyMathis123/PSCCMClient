function Invoke-CCMTriggerSchedule {
    <#
        .SYNOPSIS
            Triggers the specified ScheduleID on local, or remote computers
        .DESCRIPTION
            This script will allow you to invoke the specified ScheduleID on a machine. If the machine is remote, it will
            usie the Invoke-CCMCommand to ensure the command can be invoked. The sms_client class does not work when
            invokeing methods remotely over CIM.
        .PARAMETER ScheduleID
            Define the schedule IDs to run on the machine, typically found by query another area of WMI
        .PARAMETER CimSession
            Provides CimSessions to invoke IDs on
        .PARAMETER ComputerName
            Provides computer names to invoke IDs on
        .PARAMETER PSSession
            Provides PSSession to invoke IDs on
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the funtion. This is ultimately going to result in the function running faster. The typicaly usecase is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName paramter is passed to.
        .EXAMPLE
            C:\PS> Invoke-CCMTriggerSchedule -ScheduleID TST20000
                Performs a TriggerSchedule operation on the TST20000 ScheduleID for the local computer
        .EXAMPLE
            C:\PS> Invoke-CCMTriggerSchedule -ScheduleID '{00000000-0000-0000-0000-000000000021}'
                Performs a TriggerSchedule operation on the {00000000-0000-0000-0000-000000000021} ScheduleID (Machine Policy Refresh) for the local
                computer
        .NOTES
            FileName:    Invoke-CCMTriggerSchedule.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-11
            Updated:     2020-02-25
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ComputerName')]
    param
    (
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ScheduleID,
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
                $Result['Invoked'] = $false

                if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [ScheduleID = '$ID']", "Invoke ScheduleID")) {
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
                                Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                            }
                        }
                    }
                    catch [System.UnauthorizedAccessException] {
                        Write-Error -Message "Access denied to $Computer" -Category AuthenticationError -Exception $_.Exception
                    }
                    catch {
                        Write-Warning "Failed to invoke the $ID ScheduleID via CIM. Error: $($_.Exception.Message)"
                    }
                    if ($Invocation) {
                        Write-Verbose "Successfully invoked the $ID ScheduleID on $Computer via the 'TriggerSchedule' CIM method"
                        $Result['Invoked'] = $true
                    }

                    [pscustomobject]$Result
                }
            }
        }
    }
}