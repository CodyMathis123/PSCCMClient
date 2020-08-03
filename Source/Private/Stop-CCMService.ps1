function Stop-CCMService {
    <#
    .SYNOPSIS
        Stops a service for the specified computers using WMI
    .DESCRIPTION
        This function will stop a service on the specified computers, including a 'timeout' value where the
        process for the service will be forcefully stopped, unless it can't be stopped due to access, dependenct services, etc.
        You can provide computer names, and credentials. Providing a timeout implies you want to monitor the service being stopped.
        Otherwise, the command is simply invoked and you receive the output
    .PARAMETER Name
        The name of the service(s) you would like to stop
    .PARAMETER Timeout
        The timeout in minutes, after which the PID for the service will be forcefully stopped, unless it can't be stopped due to access, dependenct services, etc.
    .PARAMETER Force
        Will attempt to stop dependent services as well as the requested service
    .PARAMETER ComputerName
        Provides computer names to stop the service on
    .PARAMETER Credential
        Provides optional credentials to use for the WMI cmdlets.
    .EXAMPLE
        C:\PS> Stop-CCMService -Name ccmexec -Timeout 2
            Stops the ccmexec service on the local computer, giving 2 minutes before the equivalent process is force stopped
    .NOTES
        FileName:    Stop-CCMService.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2019-11-8
        Updated:     2019-12-9
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName)]
        [Alias('ServiceName', 'Service')]
        [string[]]$Name,
        [parameter(Mandatory = $false)]
        [int]$Timeout,
        [parameter(Mandatory = $false)]
        [switch]$Force,
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
        [Alias('Computer', 'PSComputerName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [parameter(Mandatory = $false)]
        [pscredential]$Credential
    )
    begin {
        # ENHANCE - Convert function to CIM
        $getWmiObjectSplat = @{
            Namespace   = 'root\cimv2'
            ErrorAction = 'Stop'
        }
        if ($PSBoundParameters.ContainsKey('Credential')) {
            $getWmiObjectSplat['Credential'] = $Credential
        }

        $ServiceExitCode = @{
            '0'  = 'The request was accepted.'
            '1'  = 'The request is not supported.'
            '2'  = 'The user did not have the necessary access.'
            '3'  = 'The service cannot be stopped because other services that are running are dependent on it.'
            '4'  = 'The requested control code is not valid, or it is unacceptable to the service.'
            '5'  = 'The requested control code cannot be sent to the service because the state of the service (Win32_BaseService.State property) is equal to 0, 1, or 2.'
            '6'  = 'The service has not been started.'
            '7'  = 'The service did not respond to the start request in a timely fashion.'
            '8'  = 'Unknown failure when starting the service.'
            '9'  = 'The directory path to the service executable file was not found.'
            '10' = 'The service is already running.'
            '11' = 'The database to add a new service is locked.'
            '12' = 'A dependency this service relies on has been removed from the system.'
            '13' = 'The service failed to find the service needed from a dependent service.'
            '14' = 'The service has been disabled from the system.'
            '15' = 'The service does not have the correct authentication to run on the system.'
            '16' = 'This service is being removed from the system.'
            '17' = 'The service has no execution thread.'
            '18' = 'The service has circular dependencies when it starts.'
            '19' = 'A service is running under the same name.'
            '20' = 'The service name has invalid characters.'
            '21' = 'Invalid parameters have been passed to the service.'
            '22' = 'The account under which this service runs is either invalid or lacks the permissions to run the service.'
            '23' = 'The service exists in the database of services available from the system.'
            '24' = 'The service is currently paused in the system.'
        }
    }
    process {
        foreach ($Computer in $ComputerName) {
            foreach ($Svc in $Name) {
                if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [ServiceName = '$Svc']", "Stop-CCMService")) {
                    $getWmiObjectSplat['ComputerName'] = $Computer
                    $getWmiObjectSplat['Query'] = [string]::Format("SELECT * FROM Win32_Service WHERE Name = '{0}'", $Svc)
                    try {
                        Write-Verbose "Retrieving service object [ComputerName = '$Computer'] [ServiceName = '$Svc']"
                        $SvcObject = Get-WmiObject @getWmiObjectSplat
                        if ($SvcObject -is [Object]) {
                            Write-Verbose "Service found [ComputerName = '$Computer'] [ServiceName = '$Svc'] [State = '$($SvcObject.State)']"
                            switch ($SvcObject.State) {
                                'Stopped' {
                                    Write-Verbose "Service is already stopped [ComputerName = '$Computer'] [ServiceName = '$Svc'] [State = '$($SvcObject.State)']"
                                    # service already stopped
                                }
                                default {
                                    Write-Verbose "Attempting to stop service [ComputerName = '$Computer'] [ServiceName = '$Svc']"
                                    $SvcStop = $SvcObject.StopService()
                                    switch ($SvcStop.ReturnValue) {
                                        0 {
                                            Write-Verbose "Stop service invoke succeeded [ComputerName = '$Computer'] [ServiceName = '$Svc']"
                                            switch ($PSBoundParameters.ContainsKey('Timeout')) {
                                                $true {
                                                    $newLoopActionSplat = @{
                                                        LoopTimeoutType = 'Minutes'
                                                        ScriptBlock     = {
                                                            $SvcObject = Get-WmiObject @getWmiObjectSplat
                                                            switch ($SvcObject.State) {
                                                                'Stopped' {
                                                                    Write-Verbose "Verified service stopped [ComputerName = '$Computer'] [ServiceName = '$Svc'] [State = '$($SvcObject.State)']"
                                                                    $ServiceStopped = $true
                                                                }
                                                                default {
                                                                    Write-Verbose "Waiting for service to stop [ComputerName = '$Computer'] [ServiceName = '$Svc'] [State = '$($SvcObject.State)']"
                                                                    $script:SvcStop = $SvcObject.StopService()
                                                                }
                                                            }
                                                        }
                                                        ExitCondition   = { $ServiceStopped }
                                                        IfTimeoutScript = {
                                                            Write-Verbose "There was a timeout while stopping $SVC - will attempt to stop the associated process"
                                                            $getWmiObjectSplat['Query'] = [string]::Format("SELECT * FROM Win32_Process WHERE ProcessID = {0}", $SvcObject.ProcessID)
                                                            $ProcessObject = Get-WmiObject @getWmiObjectSplat
                                                            $ProcessTermination = $ProcessObject.Terminate()
                                                            switch ($ProcessTermination.ReturnValue) {
                                                                0 {
                                                                    Write-Verbose "Successfully stopped the associated process"
                                                                }
                                                                default {
                                                                    Write-Error "Failed to stop the associated process"
                                                                }
                                                            }
                                                        }
                                                        LoopDelayType   = 'Seconds'
                                                        LoopDelay       = 5
                                                        LoopTimeout     = $Timeout
                                                    }
                                                    New-LoopAction @newLoopActionSplat
                                                }
                                            }
                                        }
                                        3 {
                                            switch ($Force.IsPresent) {
                                                $true {
                                                    $getWmiObjectSplat['Query'] = [string]::Format("Associators of {{Win32_Service.Name='{0}'}} Where AssocClass=Win32_DependentService Role=Antecedent", $SvcObject.Name)
                                                    $DependentServices = Get-WmiObject @getWmiObjectSplat
                                                    $stopCCMServiceSplat = @{
                                                        ComputerName = $Computer
                                                        Name         = $DependentServices.Name
                                                    }
                                                    switch ($PSBoundParameters.ContainsKey('Timeout')) {
                                                        $true {
                                                            $stopCCMServiceSplat['Timeout'] = $Timeout
                                                        }
                                                    }
                                                    switch ($PSBoundParameters.ContainsKey('Credential')) {
                                                        $true {
                                                            $stopCCMServiceSplat['Credential'] = $Credential
                                                        }
                                                    }
                                                    Stop-CCMService @stopCCMServiceSplat
                                                    $stopCCMServiceSplat['Name'] = $SvcObject.Name
                                                    Stop-CCMService @stopCCMServiceSplat
                                                }
                                                $false {
                                                    Write-Error "Failed to stop service due to service dependencies [ComputerName = '$Computer'] [ServiceName = '$Svc'] [State = '$($SvcObject.State)'] - retry with -Force to attempt to stop dependent services"
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            $ServiceStopMessage = switch ($SvcStop.ReturnValue) {
                                $null {
                                    $null
                                }
                                default {
                                    $ServiceExitCode["$PSItem"]
                                }
                            }
                            $getWmiObjectSplat['Query'] = [string]::Format("SELECT * FROM Win32_Service WHERE Name = '{0}'", $Svc)
                            Get-WmiObject @getWmiObjectSplat | Select-Object -Property @{name = 'ComputerName'; expression = { $_.SystemName } }, Name, StartMode, State, @{name = 'ServiceStopResult'; expression = { $ServiceStopMessage } }
                        }
                        else {
                            Write-Error -Message "Service not found [ComputerName = '$Computer'] [ServiceName = '$Svc']"
                        }
                    }
                    catch {
                        $ErrorMessage = $_.Exception.Message
                        Write-Error $ErrorMessage
                    }
                }
            }
        }
    }
}