function Invoke-CCMTriggerSchedule {
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
                        $invokeClientActionSplat['Arguments'] = @{
                            sScheduleID = $ID
                        }

                        Write-Verbose "Triggering a [ScheduleID = '$ID'] on $Computer via the 'TriggerSchedule' CIM method"
                        $Invocation = switch ($Computer -eq $env:ComputerName) {
                            $true {
                                Invoke-CimMethod @invokeClientActionSplat
                            }
                            $false {
                                $invokeCommandSplat = @{
                                    ScriptBlock  = {
                                        param($invokeClientActionSplat)
                                        Invoke-CimMethod @invokeClientActionSplat
                                    }
                                    ArgumentList = $invokeClientActionSplat
                                }
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