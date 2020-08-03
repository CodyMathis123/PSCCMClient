#Region '.\Private\Convert-FunctionToString.ps1' 0
function Convert-FunctionToString {
    <#
        .SYNOPSIS
            Convert function to string
        .DESCRIPTION
            This function is used to take a function, and convert it to a string. This allows it to be
            moved around more easily
        .PARAMETER FunctionToConvert
            The name of the function(s) you wish to convert to a string. You can provide multiple
        .EXAMPLE
            PS C:\> Convert-FunctionTostring -FunctionToConvert 'Get-CMClientMaintenanceWindow'
        .NOTES
            FileName:    Convert-FunctionTostring.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-07
            Updated:     2020-01-07
#>
    param(
        [Parameter(Mandatory = $True)]
        [string[]]$FunctionToConvert
    )
    $AllFunctions = foreach ($FunctionName in $FunctionToConvert) {
        try {
            $Function = Get-Command -Name $FunctionName -CommandType Function -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to find the specified function [Name = '$FunctionName']"
            continue
        }
        $ScriptBlock = $Function.ScriptBlock
        if ($null -ne $ScriptBlock) {
            [string]::Format("`r`nfunction {0} {{{1}}}", $FunctionName, $ScriptBlock)
        }
        else {
            Write-Error "Function $FunctionName does not have a Script Block and cannot be converted."
        }
    }
    [string]::Join("`r`n", $AllFunctions)
}
#EndRegion '.\Private\Convert-FunctionToString.ps1' 40
#Region '.\Private\Get-CCMConnection.ps1' 0
# ENHANCE - Rework the 'prefer' option?
function Get-CCMConnection {
    <#
    .SYNOPSIS
        Determine, and return the preferred connection type
    .DESCRIPTION
        The purpose of this function is to determine the best possible connection type to be used for the functions
        in the PSCCMClient PowerShell Module. Optinally, a 'preference' can be specified with the Prefer parameter.
        By default the preference is a CimSession, falling back to ComputerName if one is not found. In some cases
        it can be beneficial to return a PSSession for the connection type. This can be helpful as an alternative to
        using the Invoke-CIMPowerShell function. The Invoke-CIMPowerShell function executes code remotely by converting
        scriptblocks to base64 and execting them throuth the 'Create' method of the Win32_Process CIM Class.
    .PARAMETER Prefer
        The preferred remoting type, either CimSession, or PSSession which is used in fallback scenarios where ComputerName
        is passed to the function.
    .PARAMETER CimSession
        CimSession that will be passed back out after formatting
    .PARAMETER PSSession
        PSSession that will be passed back out after formatting
    .PARAMETER ComputerName
        The computer name that will be used to determine, and return the connection type
    .EXAMPLE
        C:\PS> Get-CCMConnection -ComputerName Test123 -Prefer Session
            Return a Session if found, otherwise return Computer Name
    .EXAMPLE
        C:\PS> Get-CCMConnection -ComputerName Test123
            Check for a CimSession, and return if one is found, otherwise return ComputerName
    .EXAMPLE
        C:\PS> Get-CCMConnection -ComputerName Test123 -Prefer PSSession
            Check for a PSSession, and return if one is found, otherwise return ComputerName
    .EXAMPLE
        C:\PS> Get-CCMConnection -PSSession $PSS
            Process the PSSession passed in, and return in appropriate format for consumption in module functions
    .NOTES
        FileName:    Get-CCMConnection.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-02-06
        Updated:     2020-08-01
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [ValidateSet('CimSession', 'PSSession')]
        [string]$Prefer = 'CimSession',
        [Parameter(Mandatory = $false)]
        [Microsoft.Management.Infrastructure.CimSession]$CimSession,
        [Parameter(Mandatory = $false)]
        [Alias('Session')]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession,
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string]$ComputerName = $env:ComputerName
    )

    $return = @{
        connectionSplat = @{ }
    }

    switch ($PSBoundParameters.Keys) {
        'CimSession' {
            Write-Verbose "CimSession passed to Get-CCMConnection - Passing CimSession out"
            $return['connectionSplat'] = @{ CimSession = $CimSession }
            $return['ComputerName'] = $CimSession.ComputerName
            $return['ConnectionType'] = 'CimSession'
        }
        'PSSession' {
            Write-Verbose "Session passed to Get-CCMConnection - Passing Session out"
            $return['connectionSplat'] = @{ Session = $PSSession }
            $return['ComputerName'] = $PSSession.ComputerName
            $return['ConnectionType'] = 'PSSession'
        }
        'ComputerName' {
            $return['ComputerName'] = $ComputerName
            switch ($ComputerName -eq $env:ComputerName) {
                $true {
                    Write-Verbose "Local computer provided - will return empty connection"
                    $return['connectionSplat'] = @{ }
                    $return['ConnectionType'] = 'ComputerName'
                }
                $false {
                    switch ($Prefer) {
                        'CimSession' {
                            if ($ExistingCimSession = Get-CimSession -ComputerName $ComputerName -ErrorAction Ignore) {
                                Write-Verbose "Active CimSession found for $ComputerName - Passing CimSession out"
                                $return['connectionSplat'] = @{ CimSession = $ExistingCimSession }
                                $return['ConnectionType'] = 'CimSession'
                            }
                            else {
                                Write-Verbose "No active CimSession (preferred) found for $Connection - falling back to -ComputerName"
                                $return['connectionSplat'] = @{ ComputerName = $Connection }
                                $return['ConnectionType'] = 'CimSession'
                            }
                        }
                        'PSSession' {
                            if ($ExistingSession = (Get-PSSession -ErrorAction Ignore).Where({$_.ComputerName -eq $ComputerName -and $_.State -eq 'Opened'})) {
                                Write-Verbose "Active PSSession found for $ComputerName - Passing Session out"
                                $return['connectionSplat'] = @{ Session = $ExistingSession }
                                $return['ConnectionType'] = 'PSSession'
                            }
                            else {
                                Write-Verbose "No active PSSession (preferred) found for $ComputerName - falling back to -ComputerName"
                                $return['connectionSplat'] = @{ ComputerName = $ComputerName }
                                $return['ConnectionType'] = 'PSSession'
                            }
                        }
                    }
                }
            }
        }
    }

    Write-Output $return
}
#EndRegion '.\Private\Get-CCMConnection.ps1' 114
#Region '.\Private\Get-StringFromTimespan.ps1' 0
function Get-StringFromTimespan {
    <#
        .SYNOPSIS
            Return a descriptive string based on timespan input
        .DESCRIPTION
            Reutrn a string describing a timespace, such as '1 day, 3 hours, 10 seconds'
            This is helpful when you desire to output a length of time in an easily readible
            format. The function accepts either a proper [timespan] as input, or you can
            alternatively provide the various time intervals that comprise a timespan.
        .PARAMETER Days
            The integer count of Days you wish to convert to a 'human readable string'
        .PARAMETER Hours
            The integer count of Hours you wish to convert to a 'human readable string'
        .PARAMETER Minutes
            The integer count of Minutes you wish to convert to a 'human readable string'
        .PARAMETER Seconds
            The integer count of Seconds you wish to convert to a 'human readable string'
        .PARAMETER Milliseconds
            The integer count of Milliseconds you wish to convert to a 'human readable string'
        .PARAMETER TimeSpan
            A timespan object you wish to convert to a 'human readable string'
        .EXAMPLE
            C:\PS> Get-StringFromTimespan -Seconds 3630
                1 Hour 30 Seconds
        .EXAMPLE
            C:\PS> $TS = New-TimeSpan -Hours 123 -Minutes 234
                Get-StringFromTimespan -TimeSpan $TS

                5 Days 6 Hours 54 Minutes
        .NOTES
            FileName:    Get-StringFromTimespan.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-02-20
            Updated:     2020-02-20
    #>
    param(
        [parameter(Mandatory = $false, ParameterSetName = 'ByTimeInterval')]
        [int]$Days,
        [parameter(Mandatory = $false, ParameterSetName = 'ByTimeInterval')]
        [int]$Hours,
        [parameter(Mandatory = $false, ParameterSetName = 'ByTimeInterval')]
        [int]$Minutes,
        [parameter(Mandatory = $false, ParameterSetName = 'ByTimeInterval')]
        [int]$Seconds,
        [parameter(Mandatory = $false, ParameterSetName = 'ByTimeInterval')]
        [int]$Milliseconds,
        [parameter(Mandatory = $true, ParameterSetName = 'ByTimeSpan')]
        [timespan]$TimeSpan
    )

    $TS = switch ($PSCmdlet.ParameterSetName) {
        'ByTimeInterval' {
            New-TimeSpan @PSBoundParameters
        }
        'ByTimeSpan' {
            Write-Output $TimeSpan
        }
    }

    $DescriptiveTSArray = switch ('Days', 'Hours', 'Minutes', 'Seconds', 'Milliseconds') {
        default {
            $TimeIncrement = $PSItem
            switch ($TS.$TimeIncrement) {
                0 {
                    continue
                }
                1 {
                    [string]::Format('{0} {1}', $PSItem, ($TimeIncrement -replace 's$'))
                }
                default {
                    [string]::Format('{0} {1}', $PSItem, $TimeIncrement)
                }
            }
        }
    }

    switch ($DescriptiveTSArray.Count) {
        0 {
            $PSItem
        }
        default {
            [string]::Join(' ', $DescriptiveTSArray)
        }
    }
}
#EndRegion '.\Private\Get-StringFromTimespan.ps1' 86
#Region '.\Private\Restart-CCMService.ps1' 0
# TODO  - Write Function
#EndRegion '.\Private\Restart-CCMService.ps1' 1
#Region '.\Private\Start-CCMService.ps1' 0
# TODO  - Write Function
#EndRegion '.\Private\Start-CCMService.ps1' 1
#Region '.\Private\Stop-CCMService.ps1' 0
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
#EndRegion '.\Private\Stop-CCMService.ps1' 199
#Region '.\Public\ConvertFrom-CCMSchedule.ps1' 0
Function ConvertFrom-CCMSchedule {
    <#
    .SYNOPSIS
        Convert Configuration Manager Schedule Strings
    .DESCRIPTION
        This function will take a Configuration Manager Schedule String and convert it into a readable object, including
        the calculated description of the schedule
    .PARAMETER ScheduleString
        Accepts an array of strings. This should be a schedule string in the MEMCM format
    .EXAMPLE
        PS C:\> ConvertFrom-CCMSchedule -ScheduleString 1033BC7B10100010
        SmsProviderObjectPath : SMS_ST_RecurInterval
        DayDuration           : 0
        DaySpan               : 2
        HourDuration          : 2
        HourSpan              : 0
        IsGMT                 : False
        MinuteDuration        : 59
        MinuteSpan            : 0
        StartTime             : 11/19/2019 1:04:00 AM
        Description           : Occurs every 2 days effective 11/19/2019 1:04:00 AM
    .NOTES
        This function was created to allow for converting MEMCM schedule strings without relying on the SDK / Site Server
        It also happens to be a TON faster than the Convert-CMSchedule cmdlet and the CIM method on the site server
    #>
    Param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Schedules')]
        [string[]]$ScheduleString
    )
    begin {
        #region TypeMap for returning readable window type
        $TypeMap = @{
            1 = 'SMS_ST_NonRecurring'
            2 = 'SMS_ST_RecurInterval'
            3 = 'SMS_ST_RecurWeekly'
            4 = 'SMS_ST_RecurMonthlyByWeekday'
            5 = 'SMS_ST_RecurMonthlyByDate'
        }
        #endregion TypeMap for returning readable window type

        #region function to return a formatted day such as 1st, 2nd, or 3rd
        function Get-FancyDay {
            <#
                .SYNOPSIS
                Convert the input 'Day' integer to a 'fancy' value such as 1st, 2nd, 4d, 4th, etc.
            #>
            param(
                [int]$Day
            )
            $Suffix = switch -regex ($Day) {
                '1(1|2|3)$' {
                    'th'
                    break
                }
                '.?1$' {
                    'st'
                    break
                }
                '.?2$' {
                    'nd'
                    break
                }
                '.?3$' {
                    'rd'
                    break
                }
                default {
                    'th'
                    break
                }
            }
            [string]::Format('{0}{1}', $Day, $Suffix)
        }
        #endregion function to return a formatted day such as 1st, 2nd, or 3rd
    }
    process {
        # we will split the schedulestring input into 16 characters, as some are stored as multiple in one
        foreach ($Schedule in ($ScheduleString -split '(\w{16})' | Where-Object { $_ })) {
            $MW = [ordered]@{ }

            # the first 8 characters are the Start of the MW, while the last 8 characters are the recurrence schedule
            $Start = $Schedule.Substring(0, 8)
            $Recurrence = $Schedule.Substring(8, 8)

            # Convert to binary string and pad left with 0 to ensure 32 character length for consistent parsing
            $binaryRecurrence = [Convert]::ToString([int64]"0x$Recurrence".ToString(), 2).PadLeft(32, 48)

            [bool]$IsGMT = [Convert]::ToInt32($binaryRecurrence.Substring(31, 1), 2)

            switch ($Start) {
                '00012000' {
                    # this is as 'simple' schedule, such as a CI that 'runs once a day' or 'every 8 hours'
                }
                default {
                    # Convert to binary string and pad left with 0 to ensure 32 character length for consistent parsing
                    $binaryStart = [Convert]::ToString([int64]"0x$Start".ToString(), 2).PadLeft(32, 48)

                    # Collect timedata and ensure we pad left with 0 to ensure 2 character length
                    [string]$StartMinute = ([Convert]::ToInt32($binaryStart.Substring(0, 6), 2).ToString()).PadLeft(2, 48)
                    [string]$MinuteDuration = [Convert]::ToInt32($binaryStart.Substring(26, 6), 2).ToString()
                    [string]$StartHour = ([Convert]::ToInt32($binaryStart.Substring(6, 5), 2).ToString()).PadLeft(2, 48)
                    [string]$StartDay = ([Convert]::ToInt32($binaryStart.Substring(11, 5), 2).ToString()).PadLeft(2, 48)
                    [string]$StartMonth = ([Convert]::ToInt32($binaryStart.Substring(16, 4), 2).ToString()).PadLeft(2, 48)
                    [String]$StartYear = [Convert]::ToInt32($binaryStart.Substring(20, 6), 2) + 1970

                    # set our StartDateTimeObject variable by formatting all our calculated datetime components and piping to Get-Date
                    $Kind = switch ($IsGMT) {
                        $true {
                            [DateTimeKind]::Utc
                        }
                        $false {
                            [DateTimeKind]::Local
                        }
                    }
                    $StartDateTimeObject = [datetime]::new($StartYear, $StartMonth, $StartDay, $StartHour, $StartMinute, '00', $Kind)
                }
            }

            <#
                Day duration is found by calculating how many times 24 goes into our TotalHourDuration (number of times being DayDuration)
                and getting the remainder for HourDuration by using % for modulus
            #>
            $TotalHourDuration = [Convert]::ToInt32($binaryRecurrence.Substring(0, 5), 2)

            switch ($TotalHourDuration -gt 24) {
                $true {
                    $Hours = $TotalHourDuration % 24
                    $DayDuration = ($TotalHourDuration - $Hours) / 24
                    $HourDuration = $Hours
                }
                $false {
                    $HourDuration = $TotalHourDuration
                    $DayDuration = 0
                }
            }

            $RecurType = [Convert]::ToInt32($binaryRecurrence.Substring(10, 3), 2)

            $MW['SmsProviderObjectPath'] = $TypeMap[$RecurType]
            $MW['DayDuration'] = $DayDuration
            $MW['HourDuration'] = $HourDuration
            $MW['MinuteDuration'] = $MinuteDuration
            $MW['IsGMT'] = $IsGMT
            $MW['StartTime'] = $StartDateTimeObject

            Switch ($RecurType) {
                1 {
                    $MW['Description'] = [string]::Format('Occurs on {0}', $StartDateTimeObject)
                }
                2 {
                    $MinuteSpan = [Convert]::ToInt32($binaryRecurrence.Substring(13, 6), 2)
                    $Hourspan = [Convert]::ToInt32($binaryRecurrence.Substring(19, 5), 2)
                    $DaySpan = [Convert]::ToInt32($binaryRecurrence.Substring(24, 5), 2)
                    if ($MinuteSpan -ne 0) {
                        $Span = 'minutes'
                        $Interval = $MinuteSpan
                    }
                    elseif ($HourSpan -ne 0) {
                        $Span = 'hours'
                        $Interval = $HourSpan
                    }
                    elseif ($DaySpan -ne 0) {
                        $Span = 'days'
                        $Interval = $DaySpan
                    }

                    $MW['Description'] = [string]::Format('Occurs every {0} {1} effective {2}', $Interval, $Span, $StartDateTimeObject)
                    $MW['MinuteSpan'] = $MinuteSpan
                    $MW['HourSpan'] = $Hourspan
                    $MW['DaySpan'] = $DaySpan
                }
                3 {
                    $Day = [Convert]::ToInt32($binaryRecurrence.Substring(13, 3), 2)
                    $WeekRecurrence = [Convert]::ToInt32($binaryRecurrence.Substring(16, 3), 2)
                    $MW['Description'] = [string]::Format('Occurs every {0} weeks on {1} effective {2}', $WeekRecurrence, $([DayOfWeek]($Day - 1)), $StartDateTimeObject)
                    $MW['Day'] = $Day
                    $MW['ForNumberOfWeeks'] = $WeekRecurrence
                }
                4 {
                    $Day = [Convert]::ToInt32($binaryRecurrence.Substring(13, 3), 2)
                    $ForNumberOfMonths = [Convert]::ToInt32($binaryRecurrence.Substring(16, 4), 2)
                    $WeekOrder = [Convert]::ToInt32($binaryRecurrence.Substring(20, 3), 2)
                    $WeekRecurrence = switch ($WeekOrder) {
                        0 {
                            'Last'
                        }
                        default {
                            $(Get-FancyDay -Day $WeekOrder)
                        }
                    }
                    $MW['Description'] = [string]::Format('Occurs the {0} {1} of every {2} months effective {3}', $WeekRecurrence, $([DayOfWeek]($Day - 1)), $ForNumberOfMonths, $StartDateTimeObject)
                    $MW['Day'] = $Day
                    $MW['ForNumberOfMonths'] = $ForNumberOfMonths
                    $MW['WeekOrder'] = $WeekOrder
                }
                5 {
                    $MonthDay = [Convert]::ToInt32($binaryRecurrence.Substring(13, 5), 2)
                    $MonthRecurrence = switch ($MonthDay) {
                        0 {
                            # $Today = [datetime]::Today
                            # [datetime]::DaysInMonth($Today.Year, $Today.Month)
                            'the last day'
                        }
                        default {
                            "day $PSItem"
                        }
                    }
                    $ForNumberOfMonths = [Convert]::ToInt32($binaryRecurrence.Substring(18, 4), 2)
                    $MW['Description'] = [string]::Format('Occurs {0} of every {1} months effective {2}', $MonthRecurrence, $ForNumberOfMonths, $StartDateTimeObject)
                    $MW['ForNumberOfMonths'] = $ForNumberOfMonths
                    $MW['MonthDay'] = $MonthDay
                }
                Default {
                    Write-Error "Parsing Schedule String resulted in invalid type of $RecurType"
                }
            }

            [pscustomobject]$MW
        }
    }
}
#EndRegion '.\Public\ConvertFrom-CCMSchedule.ps1' 222
#Region '.\Public\Get-CCMApplication.ps1' 0
function Get-CCMApplication {
    <#
        .SYNOPSIS
            Return deployed applications from a computer
        .DESCRIPTION
            Pulls a list of deployed applications from the specified computer(s) or CIMSession(s) with optional filters, and can be passed on
            to Invoke-CCMApplication if desired.

            Note that the parameters for filter are all joined together with OR.
        .PARAMETER ApplicationName
            An array of ApplicationName to filter on
        .PARAMETER ApplicationID
            An array of application ID to filter on
        .PARAMETER IncludeIcon
            Switch that determines if the Icon property will be included in the output. As this can be a sizeable field, it is excluded by
            default to minimize the time it takes for this to run, and the amount of memory that will be consumed.
        .PARAMETER CimSession
            Provides CimSession to gather deployed application info from
        .PARAMETER ComputerName
            Provides computer names to gather deployed application info from
        .PARAMETER PSSession
           Provides PSSessions to gather deployed application info from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the 
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then 
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to. 
        .EXAMPLE
            PS> Get-CCMApplication
                Returns all deployed applications listed in WMI on the local computer
        .EXAMPLE
            PS> Get-CCMApplication -ApplicationID ScopeId_BE389CA5-D6CC-42AF-B8F5-A059F9C9AD91/Application_0607d288-fc0b-42b7-9a61-76abedf0673e -ApplicationName 'Software Install - Silent'
                Returns all deployed applications listed in WMI on the local computer which have either a application name of 'Software Install' or
                a ID of 'ScopeId_BE389CA5-D6CC-42AF-B8F5-A059F9C9AD91/Application_0607d288-fc0b-42b7-9a61-76abedf0673e'
        .NOTES
            FileName:    Get-CCMApplication.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-21
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$ApplicationName,
        [Parameter(Mandatory = $false)]
        [string[]]$ApplicationID,
        [Parameter(Mandatory = $false)]
        [switch]$IncludeIcon,
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
        #region define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
        $getapplicationsplat = @{
            NameSpace = 'root\CCM\ClientSDK'
            ClassName = 'CCM_Application'
        }
        #endregion define our hash tables for parameters to pass to Get-CIMInstance and our return hash table

        #region EvaluationState hashtable for mapping
        $evaluationStateMap = @{
            0  = 'No state information is available.'
            1  = 'Application is enforced to desired/resolved state.'
            2  = 'Application is not required on the client.'
            3  = 'Application is available for enforcement (install or uninstall based on resolved state). Content may/may not have been downloaded.'
            4  = 'Application last failed to enforce (install/uninstall).'
            5  = 'Application is currently waiting for content download to complete.'
            6  = 'Application is currently waiting for content download to complete.'
            7  = 'Application is currently waiting for its dependencies to download.'
            8  = 'Application is currently waiting for a service (maintenance) window.'
            9  = 'Application is currently waiting for a previously pending reboot.'
            10 =	'Application is currently waiting for serialized enforcement.'
            11 =	'Application is currently enforcing dependencies.'
            12 =	'Application is currently enforcing.'
            13 =	'Application install/uninstall enforced and soft reboot is pending.'
            14 =	'Application installed/uninstalled and hard reboot is pending.'
            15 =	'Update is available but pending installation.'
            16 =	'Application failed to evaluate.'
            17 =	'Application is currently waiting for an active user session to enforce.'
            18 =	'Application is currently waiting for all users to logoff.'
            19 =	'Application is currently waiting for a user logon.'
            20 =	'Application in progress, waiting for retry.'
            21 =	'Application is waiting for presentation mode to be switched off.'
            22 =	'Application is pre-downloading content (downloading outside of install job).'
            23 =	'Application is pre-downloading dependent content (downloading outside of install job).'
            24 =	'Application download failed (downloading during install job).'
            25 =	'Application pre-downloading failed (downloading outside of install job).'
            26 =	'Download success (downloading during install job).'
            27 =	'Post-enforce evaluation.'
            28 =	'Waiting for network connectivity.'
        }
        #endregion EvaluationState hashtable for mapping
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

            $Return = [ordered]@{ }
            $Return['ComputerName'] = $Computer

            try {
                $FilterParts = switch ($PSBoundParameters.Keys) {
                    'ApplicationName' {
                        [string]::Format('$AppFound.Name -eq "{0}"', [string]::Join('" -or $AppFound.Name -eq "', $ApplicationName))
                    }
                    'ApplicationID' {
                        [string]::Format('$AppFound.ID -eq "{0}"', [string]::Join('" -or $AppFound.ID -eq "', $ApplicationID))
                    }
                }
                [ciminstance[]]$applications = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getapplicationsplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getapplicationsplat @connectionSplat
                    }
                }
                if ($applications -is [Object] -and $applications.Count -gt 0) {
                    #region Filterering is not possible on the CCM_Application class, so instead we loop and compare properties to filter
                    $Condition = switch ($null -ne $FilterParts) {
                        $true {
                            [scriptblock]::Create([string]::Join(' -or ', $FilterParts))
                        }
                    }
                    foreach ($AppFound in $applications) {
                        $AppToReturn = switch ($null -ne $Condition) {
                            $true {
                                switch ($Condition.Invoke()) {
                                    $true {
                                        $AppFound
                                    }
                                }
                            }
                            $false {
                                $AppFound
                            }
                        }
                        switch ($null -ne $AppToReturn) {
                            $true {
                                $Return['Name'] = $AppToReturn.Name
                                $Return['FullName'] = $AppToReturn.FullName
                                $Return['SoftwareVersion'] = $AppToReturn.SoftwareVersion
                                $Return['Publisher'] = $AppToReturn.Publisher
                                $Return['Description'] = $AppToReturn.Description
                                $Return['Id'] = $AppToReturn.Id
                                $Return['Revision'] = $AppToReturn.Revision
                                $Return['EvaluationState'] = $evaluationStateMap[[int]$AppToReturn.EvaluationState]
                                $Return['ErrorCode'] = $AppToReturn.ErrorCode
                                $Return['AllowedActions'] = $AppToReturn.AllowedActions
                                $Return['ResolvedState'] = $AppToReturn.ResolvedState
                                $Return['InstallState'] = $AppToReturn.InstallState
                                $Return['ApplicabilityState'] = $AppToReturn.ApplicabilityState
                                $Return['ConfigureState'] = $AppToReturn.ConfigureState
                                $Return['LastEvalTime'] = $AppToReturn.LastEvalTime
                                $Return['LastInstallTime'] = $AppToReturn.LastInstallTime
                                $Return['StartTime'] = $AppToReturn.StartTime
                                $Return['Deadline'] = $AppToReturn.Deadline
                                $Return['NextUserScheduledTime'] = $AppToReturn.NextUserScheduledTime
                                $Return['IsMachineTarget'] = $AppToReturn.IsMachineTarget
                                $Return['IsPreflightOnly'] = $AppToReturn.IsPreflightOnly
                                $Return['NotifyUser'] = $AppToReturn.NotifyUser
                                $Return['UserUIExperience'] = $AppToReturn.UserUIExperience
                                $Return['OverrideServiceWindow'] = $AppToReturn.OverrideServiceWindow
                                $Return['RebootOutsideServiceWindow'] = $AppToReturn.RebootOutsideServiceWindow
                                $Return['AppDTs'] = $AppToReturn.AppDTs
                                $Return['ContentSize'] = $AppToReturn.ContentSize
                                $Return['DeploymentReport'] = $AppToReturn.DeploymentReport
                                $Return['EnforcePreference'] = $AppToReturn.EnforcePreference
                                $Return['EstimatedInstallTime'] = $AppToReturn.EstimatedInstallTime
                                $Return['FileTypes'] = $AppToReturn.FileTypes
                                $Return['HighImpactDeployment'] = $AppToReturn.HighImpactDeployment
                                $Return['InformativeUrl'] = $AppToReturn.InformativeUrl
                                $Return['InProgressActions'] = $AppToReturn.InProgressActions
                                $Return['PercentComplete'] = $AppToReturn.PercentComplete
                                $Return['ReleaseDate'] = $AppToReturn.ReleaseDate
                                $Return['SupersessionState'] = $AppToReturn.SupersessionState
                                $Return['Type'] = $AppToReturn.Type
                                switch ($IncludeIcon.IsPresent) {
                                    $true {
                                        $Return['Icon'] = $AppToReturn.Icon
                                    }
                                }
                                [pscustomobject]$Return
                            }
                        }
                    }
                    #endregion Filterering is not possible on the CCM_Application class, so instead we loop and compare properties to filter
                }
                else {
                    Write-Warning "No deployed applications found for $Computer based on input filters"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMApplication.ps1' 222
#Region '.\Public\Get-CCMBaseline.ps1' 0
function Get-CCMBaseline {
    <#
        .SYNOPSIS
            Get MEMCM Configuration Baselines on the specified computer(s) or cimsession(s)
        .DESCRIPTION
            This function is used to identify baselines on computers. You can provide an array of computer names, or cimsessions, and
            configuration baseline names which will be queried for. If you do not specify a baseline name, then there will be no filter applied.
            A [PSCustomObject] is returned that outlines the findings.
        .PARAMETER BaselineName
            Provides the configuration baseline names that you wish to search for.
        .PARAMETER ComputerName
            Provides computer names to find the configuration baselines on.
        .PARAMETER CimSession
            Provides cimsessions to return baselines from.
        .PARAMETER PSSession
           Provides PSSessions to return baselines from.
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the 
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then 
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to. 
        .EXAMPLE
            C:\PS> Get-CCMBaseline
                Gets all baselines identified in WMI on the local computer.
        .EXAMPLE
            C:\PS> Get-CCMBaseline -ComputerName 'Workstation1234','Workstation4321' -BaselineName 'Check Connection Compliance','Double Check Connection Compliance'
                Gets the two baselines on the Computers specified. This demonstrates that both ComputerName and BaselineName accept string arrays.
        .EXAMPLE
            C:\PS> Get-CCMBaseline -ComputerName 'Workstation1234','Workstation4321'
                Gets all baselines identified in WMI for the Computers specified.
        .NOTES
            FileName:    Get-CCMBaseline.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2019-07-24
            Updated:     2020-02-27

            It is important to note that if a configuration baseline has user settings, the only way to search for it is if the user is logged in, and you run this script
            with those credentials provided to a CimSession. An example would be if Workstation1234 has user Jim1234 logged in, with a configuration baseline 'FixJimsStuff'
            that has user settings,

            This command would successfully find FixJimsStuff
            Get-CCMBaseline -ComputerName 'Workstation1234' -BaselineName 'FixJimsStuff' -CimSession $CimSessionWithJimsCreds

            This command would not find the baseline FixJimsStuff
            Get-CCMBaseline -ComputerName 'Workstation1234' -BaselineName 'FixJimsStuff'

            You could remotely query for that baseline AS Jim1234, with either a runas on PowerShell, or providing Jim's credentials to a cimsesion passed to -cimsession param.
            If you try to query for this same baseline without Jim's credentials being used in some way you will see that the baseline is not found.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CCMCB')]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string[]]$BaselineName = 'NotSpecified',
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
        #region Setup our *-CIM* parameters that will apply to the CIM cmdlets in use based on input parameters
        $getBaselineSplat = @{
            Namespace   = 'root\ccm\dcm'
            ErrorAction = 'Stop'
        }
        #endregion Setup our common *-CIM* parameters that will apply to the CIM cmdlets in use based on input parameters

        #region hash table for translating compliance status
        $LastComplianceStatus = @{
            0 = 'Non-Compliant'
            1 = 'Compliant'
            2 = 'Compliance State Unknown'
            4 = 'Error'
        }
        #endregion hash table for translating compliance status
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

            $Return = [ordered]@{ }
            $Return['ComputerName'] = $Computer

            $BLQuery = switch ($PSBoundParameters.ContainsKey('BaselineName') -and $BaselineName -ne 'NotSpecified') {
                $true {
                    [string]::Format('SELECT * FROM SMS_DesiredConfiguration WHERE DisplayName = "{0}"', [string]::Join('" OR DisplayName = "', $BaselineName))
                }
                $false {
                    "SELECT * FROM SMS_DesiredConfiguration"
                }
            }

            #region Query WMI for Configuration Baselines based off DisplayName
            Write-Verbose "Checking for Configuration Baselines on [ComputerName='$Computer'] with [Query=`"$BLQuery`"]"
            $getBaselineSplat['Query'] = $BLQuery
            try {
                $Baselines = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getBaselineSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getBaselineSplat @connectionSplat
                    }
                }
            }
            catch {
                # need to improve this - should catch access denied vs RPC, and need to do this on ALL CIM related queries across the module.
                # Maybe write a function???
                Write-Error "Failed to query for baselines on $Connection - $($_)"
                continue
            }
            #endregion Query WMI for Configuration Baselines based off DisplayName

            #region Based on results of CIM Query, return additional information around compliance and eval time
            switch ($null -eq $Baselines) {
                $false {
                    foreach ($BL in $Baselines) {
                        $Return['BaselineName'] = $BL.DisplayName
                        $Return['Version'] = $BL.Version
                        $Return['LastComplianceStatus'] = $LastComplianceStatus[[int]$BL.LastComplianceStatus]
                        $Return['LastEvalTime'] = $BL.LastEvalTime
                        [pscustomobject]$Return
                    }
                }
                $true {
                    Write-Warning "Failed to identify any Configuration Baselines on [ConnectionName='$Connection'] with [Query=`"$BLQuery`"]"
                }
            }
            #endregion Based on results of CIM Query, return additional information around compliance and eval time
        }
    }
}
#EndRegion '.\Public\Get-CCMBaseline.ps1' 153
#Region '.\Public\Get-CCMCacheContent.ps1' 0
function Get-CCMCacheContent {
    <#
        .SYNOPSIS
            Returns the content of the MEMCM cache
        .DESCRIPTION
            This function will return the content of the MEMCM cache. This is pulled from the CacheInfoEx WMI Class
        .PARAMETER CimSession
            Provides CimSessions to gather the content of the MEMCM cache from
        .PARAMETER ComputerName
            Provides computer names to gather the content of the MEMCM cache from
        .PARAMETER PSSession
            Provides PSSessions to gather the content of the MEMCM cache from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the 
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then 
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to. 
        .EXAMPLE
            C:\PS> Get-CCMCacheContent
                Returns the content of the MEMCM cache for the local computer
        .EXAMPLE
            C:\PS> Get-CCMCacheContent -ComputerName 'Workstation1234','Workstation4321'
                Returns the content of the MEMCM cache for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMCacheContent.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-12
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
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
        $getCacheContentSplat = @{
            Namespace   = 'root\CCM\SoftMgmtAgent'
            ClassName   = 'CacheInfoEx'
            ErrorAction = 'Stop'
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

            try {
                [ciminstance[]]$CacheContent = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getCacheContentSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getCacheContentSplat @connectionSplat
                    }
                }
                if ($CacheContent -is [Object] -and $CacheContent.Count -gt 0) {
                    foreach ($Item in $CacheContent) {
                        $Result['ContentId'] = $Item.ContentId
                        $Result['ContentVersion'] = $Item.ContentVer
                        $Result['Location'] = $Item.Location
                        $Result['LastReferenceTime'] = $Item.LastReferenced
                        $Result['ReferenceCount'] = $Item.ReferenceCount
                        $Result['ContentSize'] = $Item.ContentSize
                        $Result['ContentComplete'] = $Item.ContentComplete
                        $Result['CacheElementId'] = $Item.CacheID
                        [pscustomobject]$Result
                    }
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMCacheContent.ps1' 100
#Region '.\Public\Get-CCMCacheInfo.ps1' 0
function Get-CCMCacheInfo {
    <#
        .SYNOPSIS
            Get ConfigMgr client cache directory info from computers via CIM
        .DESCRIPTION
            This function will allow you to gather the ConfigMgr client cache directory info from multiple computers using CIM queries.
            You can provide an array of computer names, or cimsessions, or you can pass them through the pipeline.
        .PARAMETER CimSession
            Provides CimSession to gather cache info from.
        .PARAMETER ComputerName
            Provides computer names to gather cache info from.
        .PARAMETER PSSession
            Provides PSSessions to gather cache info from.
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the 
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then 
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to. 
        .EXAMPLE
            C:\PS> Get-CCMCacheInfo
                Return ConfigMgr client cache directory info for the local computer
        .EXAMPLE
            C:\PS> Get-CCMCacheInfo -ComputerName 'Workstation1234','Workstation4321'
                Return ConfigMgr client cache directory info for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMCacheInfo.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2019-11-06
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
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
        $getCacheInfoSplat = @{
            Namespace   = 'root\CCM\SoftMgmtAgent'
            ClassName   = 'CacheConfig'
            ErrorAction = 'Stop'
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

            try {
                [ciminstance[]]$CimResult = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getCacheInfoSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getCacheInfoSplat @connectionSplat
                    }
                }
                if ($CimResult -is [Object] -and $CimResult.Count -gt 0) {
                    foreach ($Object in $CimResult) {
                        $Result['Location'] = $Object.Location
                        $Result['Size'] = $Object.Size
                        [PSCustomObject]$Result
                    }
                }
                else {
                    $Result['Location'] = $null
                    $Result['Size'] = $null
                    [PSCustomObject]$Result
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMCacheInfo.ps1' 100
#Region '.\Public\Get-CCMCimInstance.ps1' 0
<#
		.SYNOPSIS
			Invoke a Get-CimInstance command
		.DESCRIPTION
			This function is used to invoke a Get-CimInstance command. What differentiates this from just running
			Get-CimInstance is that the function will also accept a PSSession as a parameter, and invoke the
			Get-CimInstance command over that PSSession transparently.
		.PARAMETER Namespace
			Specifies the namespace of CIM class.

			The default namespace is root/cimv2.
		.PARAMETER ClassName
			Specifies the name of the CIM class for which to retrieve the CIM instances.
		.PARAMETER Filter
			Specifies a where clause to use as a filter. Specify the clause in either the WQL or the CQL query language.
		.PARAMETER Query
			Specifies a query to run on the CIM server. For WQL-based queries, you can only use a SELECT query that returns
			instances.

			If the value specified contains double quotes (“), single quotes (‘), or a backslash (\), you must escape those
			characters by prefixing them with the backslash (\) character. If the value specified uses the WQL LIKE operator,
			then you must escape the following characters by enclosing them in square brackets ([]): percent (%), underscore
			(_), or opening square bracket ([).

			You cannot use a metadata query to retrieve a list of classes or an event query. To retrieve a list of classes,
			use the Get-CimClass cmdlet. To retrieve an event query, use the Register-CimIndicationEvent cmdlet.

			You can specify the query dialect using the QueryDialect parameter.
		.PARAMETER CimSession
			Computer CimSession(s) which you want to query a CimInstance on
		.PARAMETER ComputerName
			Computer name(s) which you want to query a CimInstance on
		.PARAMETER PSSession
			PSSessions which you want to query a CimInstance on
		.PARAMETER ConnectionPreference
			Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
			is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
			when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
			pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
			specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
			falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
			the ComputerName parameter is passed to.
		.EXAMPLE
			C:\PS> Get-CCMCimInstance -Query "SELECT * FROM Win32_ComputerSystem" -ComputerName Workstation123 -ConnectionPreference PSSession
				Query for the Win32_ComputerSystem CimClass, preferring a PSSession first, falling back to CimSession
		.EXAMPLE
			C:\PS> Get-CCMCimInstance -Query "SELECT * FROM Win32_ComputerSystem" -ComputerName Workstation123 -ConnectionPreference CimSession
				Query for the Win32_ComputerSystem CimClass, preferring a CimSession first, falling back to PSSession
		.EXAMPLE
			C:\PS> Get-CCMCimInstance -Query "SELECT * FROM Win32_ComputerSystem" -PSSession $PSS
				Query for the Win32_ComputerSystem CimClass against the machine that the $PSS targets via a PSSession
		.EXAMPLE
			C:\PS> Get-CCMCimInstance -Query "SELECT * FROM Win32_ComputerSystem" -CimSession $CIM
				Query for the Win32_ComputerSystem CimClass against the machine that the $CIM targets via a CimSession
		.NOTES
            FileName:    Get-CCMCimInstance.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     Don't recall
            Updated:     2020-03-17	
#>
function Get-CCMCimInstance {
	[CmdletBinding(DefaultParameterSetName = 'CimQuery-ComputerName')]
	param
	(
		[Parameter(Mandatory = $false)]
		[string]$Namespace = 'root\cimv2',
		[Parameter(Mandatory = $true, ParameterSetName = 'CimFilter-CimSession')]
		[Parameter(Mandatory = $true, ParameterSetName = 'CimFilter-PSSession')]
		[Parameter(Mandatory = $true, ParameterSetName = 'CimFilter-ComputerName')]
		[string]$ClassName,
		[Parameter(Mandatory = $false, ParameterSetName = 'CimFilter-CimSession')]
		[Parameter(Mandatory = $false, ParameterSetName = 'CimFilter-PSSession')]
		[Parameter(Mandatory = $false, ParameterSetName = 'CimFilter-ComputerName')]
		[string]$Filter,
		[Parameter(Mandatory = $true, ParameterSetName = 'CimQuery-CimSession')]
		[Parameter(Mandatory = $true, ParameterSetName = 'CimQuery-PSSession')]
		[Parameter(Mandatory = $true, ParameterSetName = 'CimQuery-ComputerName')]
		[string]$Query,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimQuery-CimSession')]
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimFilter-CimSession')]
		[Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'PassThrough-ComputerName')]
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimQuery-ComputerName')]
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimFilter-ComputerName')]
		[Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
		[string[]]$ComputerName = $env:ComputerName,
		[Parameter(Mandatory = $false, ParameterSetName = 'CimQuery-PSSession')]
		[Parameter(Mandatory = $false, ParameterSetName = 'CimFilter-PSSession')]
		[Alias('Session')]
		[System.Management.Automation.Runspaces.PSSession[]]$PSSession,
		[Parameter(Mandatory = $false, ParameterSetName = 'CimQuery-ComputerName')]
		[Parameter(Mandatory = $false, ParameterSetName = 'CimFilter-ComputerName')]
		[ValidateSet('CimSession', 'PSSession')]
		[string]$ConnectionPreference = 'CimSession'
	)
	begin {
		$ConnectionChecker = ($PSCmdlet.ParameterSetName).Split('-')[1]

		$GetCimInstanceSplat = @{ }
		switch ($PSBoundParameters.Keys) {
			'Namespace' {
				$GetCimInstanceSplat['NameSpace'] = $Namespace
			}
			'ClassName' {
				$GetCimInstanceSplat['ClassName'] = $ClassName
			}
			'Filter' {
				$GetCimInstanceSplat['Filter'] = $Filter
			}
			'Query' {
				$GetCimInstanceSplat['Query'] = $Query
			}
		}
	}
	process {
		foreach ($Connection in (Get-Variable -Name $ConnectionChecker -ValueOnly -Scope Local)) {
			$getConnectionInfoSplat = @{
				$ConnectionChecker = $Connection
			}
			$ConnectionInfo = Get-CCMConnection @getConnectionInfoSplat -Prefer $ConnectionPreference
			$ConnectionPreference = $ConnectionInfo.ConnectionType
			$connectionSplat = $ConnectionInfo.connectionSplat

			switch ($ConnectionPreference) {
				'CimSession' {
					Get-CimInstance @GetCimInstanceSplat @connectionSplat
				}
				'PSSession' {
					$GetCimInstanceOverPSSessionSplat = @{
						ArgumentList = $GetCimInstanceSplat
						ScriptBlock  = {
							param($GetCimInstanceSplat)
							Get-CimInstance @GetCimInstanceSplat
						}
					}
					
					Invoke-Command @GetCimInstanceOverPSSessionSplat @connectionSplat
				}
			}
		}
	}
}
#EndRegion '.\Public\Get-CCMCimInstance.ps1' 143
#Region '.\Public\Get-CCMClientDirectory.ps1' 0
function Get-CCMClientDirectory {
    <#
        .SYNOPSIS
            Return the MEMCM Client Directory
        .DESCRIPTION
            Checks the registry of the local machine and will return the 'Local SMS Path' property of the 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SMS\Client\Configuration\Client Properties'
            registry key. This function uses the Get-CIMRegistryProperty function which uses CIM to query the registry
        .PARAMETER CimSession
            Provides CimSessions to gather the MEMCM Client Directory from
        .PARAMETER ComputerName
            Provides computer names to gather the MEMCM Client Directory from
        .PARAMETER PSSession
            Provides PSSessions to gather the MEMCM Client Directory from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the 
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then 
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to. 
        .EXAMPLE
            C:\PS> Get-CCMClientDirectory
                Returns the MEMCM Client Directory for the local computer
        .EXAMPLE
            C:\PS> Get-CCMClientDirectory -ComputerName 'Workstation1234','Workstation4321'
                Returns the MEMCM Client Directory for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMClientDirectory.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-12
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
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
        $getRegistryPropertySplat = @{
            Key      = "SOFTWARE\Microsoft\SMS\Client\Configuration\Client Properties"
            Property = "Local SMS Path"
            RegRoot  = 'HKEY_LOCAL_MACHINE'
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

            $ReturnHashTable = Get-CCMRegistryProperty @getRegistryPropertySplat @connectionSplat
            foreach ($PC in $ReturnHashTable.GetEnumerator()) {
                $Result['ClientDirectory'] = $ReturnHashTable[$PC.Key].'Local SMS Path'.TrimEnd('\')
            }
            [pscustomobject]$Result
        }
    }
}
#EndRegion '.\Public\Get-CCMClientDirectory.ps1' 80
#Region '.\Public\Get-CCMClientInfo.ps1' 0
function Get-CCMClientInfo {
    <#
        .SYNOPSIS
            Returns info about the MEMCM Client
        .DESCRIPTION
            This function will return a large amount of info for the MEMCM client using CIM. It leverages many of the existing Get-CCM* functions
            in the module to present the data as one object.
        .PARAMETER CimSession
            Provides CimSessions to gather the client info from
        .PARAMETER ComputerName
            Provides computer names to gather the client info from
        .PARAMETER PSSession
            Provides PSSessions to gather the client info from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Get-CCMClientInfo
                Returns the client info from local computer
        .EXAMPLE
            C:\PS> Get-CCMClientInfo -ComputerName 'Workstation1234','Workstation4321'
                Returns the client info from Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMClientInfo.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-24
            Updated:     2020-05-26
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
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

            # ENHANCE - Decide on an order for the properties

            $Result = [ordered]@{ }
            $Result['ComputerName'] = $Computer

            #region site code
            $SiteCode = Get-CCMSite @connectionSplat
            $Result['SiteCode'] = $SiteCode.SiteCode
            #endregion site code

            #region Current Management Point
            $Result['CurrentManagementPoint'] = (Get-CCMCurrentManagementPoint @connectionSplat).CurrentManagementPoint
            $Result['CurrentSoftwareUpdatePoint'] = (Get-CCMCurrentSoftwareUpdatePoint @connectionSplat).CurrentSoftwareUpdatePoint
            #endregion Current Management Point

            #region cache info
            $CacheInfo = Get-CCMCacheInfo @connectionSplat
            $Result['CacheLocation'] = $CacheInfo.Location
            $Result['CacheSize'] = $CacheInfo.Size
            #endregion cache info

            #region MEMCM Client Directory
            $Result['ClientDirectory'] = (Get-CCMClientDirectory @connectionSplat).ClientDirectory
            #endregion MEMCM Client Directory
                                    
            #region DNS Suffix
            $Result['DNSSuffix'] = (Get-CCMDNSSuffix @connectionSplat).DNSSuffix
            #endregion DNS Suffix

            #region MEMCM Client GUID
            $GUIDInfo = Get-CCMGUID @connectionSplat
            $Result['GUID'] = $GUIDInfo.GUID
            $Result['ClientGUIDChangeDate'] = $GUIDInfo.ClientGUIDChangeDate
            $Result['PreviousGUID'] = $GUIDInfo.PreviousGUID
            #endregion MEMCM Client GUID

            #region MEMCM Client Version
            $Result['ClientVersion'] = (Get-CCMClientVersion @connectionSplat).ClientVersion
            #endregion MEMCM Client Version

            #region Last Heartbeat Cycle
            $LastHeartbeat = Get-CCMLastHeartbeat @connectionSplat
            $Result['DDR-LastCycleStartedDate'] = $LastHeartbeat.LastCycleStartedDate
            $Result['DDR-LastReportDate'] = $LastHeartbeat.LastReportDate
            $Result['DDR-LastMajorReportVersion'] = $LastHeartbeat.LastMajorReportVersion
            $Result['DDR-LastMinorReportVersion'] = $LastHeartbeat.LastMinorReportVersion
            #endregion Last Heartbeat Cycle

            #region Last Hardware Inventory Cycle
            $LastHardwareInventory = Get-CCMLastHardwareInventory @connectionSplat
            $Result['HINV-LastCycleStartedDate'] = $LastHardwareInventory.LastCycleStartedDate
            $Result['HINV-LastReportDate'] = $LastHardwareInventory.LastReportDate
            $Result['HINV-LastMajorReportVersion'] = $LastHardwareInventory.LastMajorReportVersion
            $Result['HINV-LastMinorReportVersion'] = $LastHardwareInventory.LastMinorReportVersion
            #endregion Last Hardware Inventory Cycle

            #region Last Software Inventory Cycle
            $LastSoftwareInventory = Get-CCMLastSoftwareInventory @connectionSplat
            $Result['SINV-LastCycleStartedDate'] = $LastSoftwareInventory.LastCycleStartedDate
            $Result['SINV-LastReportDate'] = $LastSoftwareInventory.LastReportDate
            $Result['SINV-LastMajorReportVersion'] = $LastSoftwareInventory.LastMajorReportVersion
            $Result['SINV-LastMinorReportVersion'] = $LastSoftwareInventory.LastMinorReportVersion
            #endregion Last Software Inventory Cycle

            #region MEMCM Client Log Configuration
            $LogConfiguration = Get-CCMLoggingConfiguration @connectionSplat
            $Result['LogDirectory'] = $LogConfiguration.LogDirectory
            $Result['LogMaxSize'] = $LogConfiguration.LogMaxSize
            $Result['LogMaxHistory'] = $LogConfiguration.LogMaxHistory
            $Result['LogLevel'] = $LogConfiguration.LogLevel
            $Result['LogEnabled'] = $LogConfiguration.LogEnabled
            #endregion MEMCM Client Log Configuration

            #region MEMCM Client internet configuration
            $Result['IsClientOnInternet'] = (Test-CCMIsClientOnInternet @connectionSplat).IsClientOnInternet[0]
            $Result['IsClientAlwaysOnInternet'] = (Test-CCMIsClientAlwaysOnInternet @connectionSplat).IsClientAlwaysOnInternet[0]
            #endregion MEMCM Client internet configuration

            [pscustomobject]$Result
        }
    }
}
#EndRegion '.\Public\Get-CCMClientInfo.ps1' 147
#Region '.\Public\Get-CCMClientVersion.ps1' 0
function Get-CCMClientVersion {
    <#
        .SYNOPSIS
            Returns the current MEMCM client version
        .DESCRIPTION
            This function will return the current version for the MEMCM client using CIM.
        .PARAMETER CimSession
            Provides CimSessions to gather the version from
        .PARAMETER ComputerName
            Provides computer names to gather the version from
        .PARAMETER PSSession
            Provides PSSessions to gather the version from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the 
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then 
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to. 
        .EXAMPLE
            C:\PS> Get-CCMClientVersion
                Returns the MEMCM client version from local computer
        .EXAMPLE
            C:\PS> Get-CCMClientVersion -ComputerName 'Workstation1234','Workstation4321'
                Returns the MEMCM client version from Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMClientVersion.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-24
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
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
        $getClientVersionSplat = @{
            Namespace = 'root\CCM'
            Query     = 'SELECT ClientVersion FROM SMS_Client'
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

            try {
                [ciminstance[]]$Currentversion = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getClientVersionSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getClientVersionSplat @connectionSplat
                    }
                }
                if ($Currentversion -is [Object] -and $Currentversion.Count -gt 0) {
                    foreach ($SMSClient in $Currentversion) {
                        $Result['ClientVersion'] = $SMSClient.ClientVersion
                        [PSCustomObject]$Result
                    }
                }
                else {
                    Write-Warning "No client version found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMClientVersion.ps1' 95
#Region '.\Public\Get-CCMCurrentManagementPoint.ps1' 0
function Get-CCMCurrentManagementPoint {
    <#
        .SYNOPSIS
            Returns the current assigned MP from a client
        .DESCRIPTION
            This function will return the current assigned MP for the client using CIM. 
        .PARAMETER CimSession
            Provides CimSessions to gather the current assigned MP from
        .PARAMETER ComputerName
            Provides computer names to gather the current assigned MP from
        .PARAMETER PSSession
            Provides PSSessions to gather the current assigned MP from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the 
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then 
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to. 
        .EXAMPLE
            C:\PS> Get-CCMCurrentManagementPoint
                Returns the current assigned MP from local computer
        .EXAMPLE
            C:\PS> Get-CCMCurrentManagementPoint -ComputerName 'Workstation1234','Workstation4321'
                Returns the current assigned MP from Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMCurrentManagementPoint.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-16
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CCMCurrentMP', 'Get-CCMMP')]
    param (
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
        $getCurrentMPSplat = @{
            Namespace = 'root\CCM'
            Query     = 'SELECT CurrentManagementPoint FROM SMS_Authority'
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

            try {
                [ciminstance[]]$CurrentMP = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getCurrentMPSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getCurrentMPSplat @connectionSplat
                    }
                }
                if ($CurrentMP -is [Object] -and $CurrentMP.Count -gt 0) {
                    foreach ($MP in $CurrentMP) {
                        $Result['CurrentManagementPoint'] = $MP.CurrentManagementPoint
                        [PSCustomObject]$Result
                    }
                }
                else {
                    Write-Warning "No Management Point infomration found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMCurrentManagementPoint.ps1' 96
#Region '.\Public\Get-CCMCurrentSoftwareUpdatePoint.ps1' 0
function Get-CCMCurrentSoftwareUpdatePoint {
    <#
        .SYNOPSIS
            Returns the current assigned SUP from a client
        .DESCRIPTION
            This function will return the current assigned SUP for the client using CIM.
        .PARAMETER CimSession
            Provides CimSessions to gather the current assigned SUP from
        .PARAMETER ComputerName
            Provides computer names to gather the current assigned SUP from
        .PARAMETER PSSession
            Provides PSSessions to gather the current assigned SUP from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the 
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then 
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to. 
        .EXAMPLE
            C:\PS> Get-CCMCurrentSoftwareUpdatePoint
                Returns the current assigned SUP from local computer
        .EXAMPLE
            C:\PS> Get-CCMCurrentSoftwareUpdatePoint -ComputerName 'Workstation1234','Workstation4321'
                Returns the current assigned SUP from Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMCurrentSoftwareUpdatePoint.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-16
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CCMCurrentSUP', 'Get-CCMSUP')]
    param (
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
        $CurrentSUPSplat = @{
            Namespace = 'root\ccm\SoftwareUpdates\WUAHandler'
            Query     = 'SELECT ContentLocation FROM CCM_UpdateSource'
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

            try {
                [ciminstance[]]$CurrentSUP = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @CurrentSUPSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @CurrentSUPSplat @connectionSplat
                    }
                }
                if ($CurrentSUP -is [Object] -and $CurrentSUP.Count -gt 0) {
                    foreach ($SUP in $CurrentSUP) {
                        $Result['CurrentSoftwareUpdatePoint'] = $SUP.ContentLocation
                        [PSCustomObject]$Result
                    }
                }
                else {
                    Write-Warning "No Software Update Point information found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMCurrentSoftwareUpdatePoint.ps1' 96
#Region '.\Public\Get-CCMCurrentWindowAvailableTime.ps1' 0
function Get-CCMCurrentWindowAvailableTime {
    <#
        .SYNOPSIS
            Return the time left in the current window based on input.
        .DESCRIPTION
            This function uses the GetCurrentWindowAvailableTime method of the CCM_ServiceWindowManager CIM class. It will allow you to
            return the time left in the current window based on your input parameters.

            It also will determine your client settings for software updates to appropriately fall back to an 'All Deployment Service Window'
            according to both your settings, and whether a 'Software Update Service Window' is available
        .PARAMETER MWType
            Specifies the types of MW you want information for. Defaults to 'Software Update Service Window'. Valid options are below
                'All Deployment Service Window',
                'Program Service Window',
                'Reboot Required Service Window',
                'Software Update Service Window',
                'Task Sequences Service Window',
                'Corresponds to non-working hours'
        .PARAMETER CimSession
            Provides CimSession to gather Maintenance Window information info from
        .PARAMETER ComputerName
            Provides computer names to gather Maintenance Window information info from
        .PARAMETER PSSession
            Provides a PSSession to gather Maintenance Window information info from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Get-CCMCurrentWindowAvailableTime
                Return the available time fro the default MWType of 'Software Update Service Window' with fallback
                based on client settings and 'Software Update Service Window' availability.
        .EXAMPLE
            C:\PS> Get-CCMCurrentWindowAvailableTime -ComputerName 'Workstation1234','Workstation4321' -MWType 'Task Sequences Service Window'
                Return the available time left in a current 'Task Sequences Service Window' for 'Workstation1234','Workstation4321'
        .NOTES
            FileName:    Get-CCMCurrentWindowAvailableTime.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-02-01
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
        [parameter(Mandatory = $false)]
        [ValidateSet('All Deployment Service Window',
            'Program Service Window',
            'Reboot Required Service Window',
            'Software Update Service Window',
            'Task Sequences Service Window',
            'Corresponds to non-working hours')]
        [string[]]$MWType = 'Software Update Service Window',
        [Parameter(Mandatory = $false)]
        [bool]$FallbackToAllProgramsWindow,
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
        #region Create hashtable for mapping MW types
        $MW_Type = @{
            'All Deployment Service Window'    = 1
            'Program Service Window'           = 2
            'Reboot Required Service Window'   = 3
            'Software Update Service Window'   = 4
            'Task Sequences Service Window'    = 5
            'Corresponds to non-working hours' = 6
        }
        #endregion Create hashtable for mapping MW types

        $getCurrentWindowTimeLeft = @{
            Namespace  = 'root\CCM\ClientSDK'
            ClassName  = 'CCM_ServiceWindowManager'
            MethodName = 'GetCurrentWindowAvailableTime'
            Arguments  = @{ }
        }
        $getUpdateMWExistenceSplat = @{
            Namespace = 'root\CCM\ClientSDK'
            Query     = 'SELECT Duration FROM CCM_ServiceWindow WHERE Type = 4'
        }
        $getSoftwareUpdateFallbackSettingsSplat = @{
            Namespace = 'root\CCM\Policy\Machine\ActualConfig'
            Query     = 'SELECT ServiceWindowManagement FROM CCM_SoftwareUpdatesClientConfig'
        }
        $invokeCommandSplat = @{
            FunctionsToLoad = 'Get-CCMCurrentWindowAvailableTime', 'Get-CCMConnection'
        }

        $StringArgs = @(switch ($PSBoundParameters.Keys) {
                'FallbackToAllProgramsWindow' {
                    [string]::Format('-FallbackToAllProgramsWindow ${0}', $FallbackToAllProgramsWindow)
                }
            })
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

            try {
                switch ($Computer -eq $env:ComputerName) {
                    $true {
                        $HasUpdateMW = $null -ne (Get-CimInstance @getUpdateMWExistenceSplat @connectionSplat).Duration
                        $FallbackSetting = (Get-CimInstance @getSoftwareUpdateFallbackSettingsSplat @connectionSplat).ServiceWindowManagement

                        foreach ($MW in $MWType) {
                            $MWFallback = switch ($FallbackToAllProgramsWindow) {
                                $true {
                                    switch ($MWType) {
                                        'Software Update Service Window' {
                                            switch ($FallbackSetting -ne $FallbackToAllProgramsWindow) {
                                                $true {
                                                    Write-Warning 'Requested fallback setting does not match the computers fallback setting for software updates'
                                                }
                                            }
                                            switch ($HasUpdateMW) {
                                                $true {
                                                    $FallbackSetting -and $HasUpdateMW
                                                }
                                                $false {
                                                    $true
                                                }
                                            }
                                        }
                                        default {
                                            $FallbackToAllProgramsWindow
                                        }
                                    }
                                }
                                $false {
                                    switch ($MWType) {
                                        'Software Update Service Window' {
                                            switch ($HasUpdateMW) {
                                                $true {
                                                    $FallbackSetting -and $HasUpdateMW
                                                }
                                                $false {
                                                    $true
                                                }
                                            }
                                        }
                                        default {
                                            $false
                                        }
                                    }
                                }
                            }
                            $getCurrentWindowTimeLeft['Arguments']['FallbackToAllProgramsWindow'] = [bool]$MWFallback
                            $getCurrentWindowTimeLeft['Arguments']['ServiceWindowType'] = [uint32]$MW_Type[$MW]
                            $TimeLeft = Invoke-CimMethod @getCurrentWindowTimeLeft @connectionSplat
                            $TimeLeftTimeSpan = New-TimeSpan -Seconds $TimeLeft.WindowAvailableTime
                            $Result['MaintenanceWindowType'] = $MW
                            $Result['FallbackToAllProgramsWindow'] = $MWFallback
                            $Result['WindowAvailableTime'] = [string]::Format('{0} day(s) {1} hour(s) {2} minute(s) {3} second(s)', $TimeLeftTimeSpan.Days, $TimeLeftTimeSpan.Hours, $TimeLeftTimeSpan.Minutes, $TimeLeftTimeSpan.Seconds)
                            [pscustomobject]$Result
                        }
                    }
                    $false {
                        $ScriptBlock = [string]::Format('Get-CCMCurrentWindowAvailableTime {0} {1}', [string]::Join(' ', $StringArgs), [string]::Format("-MWType '{0}'", [string]::Join("', '", $MWType)))
                        $invokeCommandSplat['ScriptBlock'] = [scriptblock]::Create($ScriptBlock)
                        Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                    }
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMCurrentWindowAvailableTime.ps1' 194
#Region '.\Public\Get-CCMDNSSuffix.ps1' 0
function Get-CCMDNSSuffix {
    <#
        .SYNOPSIS
            Returns the current DNS suffix set for the MEMCM Client
        .DESCRIPTION
            This function will return the current DNS suffix in use for the MEMCM Client. This is done using the Microsoft.SMS.Client COM Object.
        .PARAMETER CimSession
            Provides CimSessions to return the current DNS suffix in use for
        .PARAMETER ComputerName
            Provides computer names to return the current DNS suffix in use for
        .PARAMETER PSSession
            Provides a PSSession to return the current DNS suffix in use for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Get-CCMDNSSuffix
                Return the local computers DNS Suffix setting
        .EXAMPLE
            C:\PS> Get-CCMDNSSuffix -ComputerName 'Workstation1234','Workstation4321'
                Return the DNS Suffix setting for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMDNSSuffix.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-18
            Updated:     2020-03-01
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param(
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
        $GetDNSSuffixScriptBlock = {
            $Client = New-Object -ComObject Microsoft.SMS.Client
            $Client.GetDNSSuffix()
        }
        $invokeCommandSplat = @{
            ScriptBlock = $GetDNSSuffixScriptBlock
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

            $Result['DNSSuffix'] = switch ($Computer -eq $env:ComputerName) {
                $true {
                    $GetDNSSuffixScriptBlock.Invoke()
                }
                $false {
                    Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                }
            }
            [pscustomobject]$Result
        }
    }
}
#EndRegion '.\Public\Get-CCMDNSSuffix.ps1' 84
#Region '.\Public\Get-CCMExecStartupTime.ps1' 0
function Get-CCMExecStartupTime {
    <#
        .SYNOPSIS
            Return the CCMExec service startup time based on process creation date
        .DESCRIPTION
            This function will return the startup time of the CCMExec service if it is currently running. The method used is querying
            for the Win32_Service CIM object, and passing the ProcessID to Win32_Process CIM class. This lets us determine the
            creation date of the CCMExec process, which would coorelate to service startup time.
        .PARAMETER CimSession
            Provides CimSessions to gather CCMExec service startup time from
        .PARAMETER ComputerName
            Provides computer names to gather CCMExec service startup time from
        .PARAMETER PSSession
            Provides PSSessions to gather CCMExec service startup time from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Get-CCMExecStartupTime
                Returns CCMExec service startup time for the local computer
        .EXAMPLE
            C:\PS> Get-CCMExecStartupTime -ComputerName 'Workstation1234','Workstation4321'
                Returns CCMExec service startup time for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMExecStartupTime.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-29
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
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
        $getCCMExecServiceSplat = @{
            Query = "SELECT State, ProcessID from Win32_Service WHERE Name = 'CCMExec'"
        }
        $getCCMExecProcessSplat = @{ }
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

            try {
                [ciminstance[]]$CCMExecService = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getCCMExecServiceSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getCCMExecServiceSplat @connectionSplat
                    }
                }
                if ($CCMExecService -is [Object] -and $CCMExecService.Count -gt 0) {
                    foreach ($Service in $CCMExecService) {
                        $getCCMExecProcessSplat['Query'] = [string]::Format("Select CreationDate from Win32_Process WHERE ProcessID = '{0}'", $Service.ProcessID)
                        [ciminstance[]]$CCMExecProcess = switch ($Computer -eq $env:ComputerName) {
                            $true {
                                Get-CimInstance @getCCMExecProcessSplat @connectionSplat
                            }
                            $false {
                                Get-CCMCimInstance @getCCMExecProcessSplat @connectionSplat
                            }
                        }
                        if ($CCMExecProcess -is [Object] -and $CCMExecProcess.Count -gt 0) {
                            foreach ($Process in $CCMExecProcess) {
                                $Result['ServiceState'] = $Service.State
                                $Result['StartupTime'] = $Process.CreationDate
                                [pscustomobject]$Result
                            }
                        }
                    }
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMExecStartupTime.ps1' 108
#Region '.\Public\Get-CCMGUID.ps1' 0
function Get-CCMGUID {
    <#
        .SYNOPSIS
            Returns the current client GUID
        .DESCRIPTION
            This function will return the current GUID for the MEMCM client using CIM.
        .PARAMETER CimSession
            Provides CimSessions to gather the GUID from
        .PARAMETER ComputerName
            Provides computer names to gather the GUID from
        .PARAMETER PSSEssion
            Provides PSSEssions to gather the GUID from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Get-CCMGUID
                Returns the GUID from local computer
        .EXAMPLE
            C:\PS> Get-CCMGUID -ComputerName 'Workstation1234','Workstation4321'
                Returns the GUID from Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMGUID.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-18
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
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
        $getGUIDSplat = @{
            Namespace = 'root\CCM'
            Query     = 'SELECT ClientID, ClientIDChangeDate, PreviousClientID FROM CCM_Client'
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

            try {
                [ciminstance[]]$CurrentGUID = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getGUIDSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getGUIDSplat @connectionSplat
                    }
                }
                if ($CurrentGUID -is [Object] -and $CurrentGUID.Count -gt 0) {
                    foreach ($GUID in $CurrentGUID) {
                        $Result['GUID'] = $GUID.ClientID
                        $Result['ClientGUIDChangeDate'] = $GUID.ClientIDChangeDate
                        $Result['PreviousGUID'] = $GUID.PreviousClientID
                        [PSCustomObject]$Result
                    }
                }
                else {
                    Write-Warning "No ClientID information found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMGUID.ps1' 98
#Region '.\Public\Get-CCMLastHardwareInventory.ps1' 0
function Get-CCMLastHardwareInventory {
    <#
        .SYNOPSIS
            Returns info about the last time Hardware Inventory ran
        .DESCRIPTION
            This function will return info about the last time Hardware Inventory was ran. This is pulled from the InventoryActionStatus WMI Class.
            The hardware inventory major, and minor version is included. This can be helpful in troubleshooting hardware inventory issues.
        .PARAMETER CimSession
            Provides CimSession to gather hardware inventory last run info from
        .PARAMETER ComputerName
            Provides computer names to gather hardware inventory last run info from
        .PARAMETER PSSession
            Provides PSSessions to gather hardware inventory last run info from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Get-CCMLastHardwareInventory
                Returns info regarding the last hardware inventory cycle for the local computer
        .EXAMPLE
            C:\PS> Get-CCMLastHardwareInventory -ComputerName 'Workstation1234','Workstation4321'
                Returns info regarding the last hardware inventory cycle for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMLastHardwareInventory.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-01
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CCMLastHINV')]
    param (
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
        $getLastHinvSplat = @{
            Namespace = 'root\CCM\InvAgt'
            Query     = "SELECT LastCycleStartedDate, LastReportDate, LastMajorReportVersion, LastMinorReportVersion, InventoryActionID FROM InventoryActionStatus WHERE InventoryActionID = '{00000000-0000-0000-0000-000000000001}'"
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

            try {
                [ciminstance[]]$LastHinv = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getLastHinvSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getLastHinvSplat @connectionSplat
                    }
                }
                if ($LastHinv -is [Object] -and $LastHinv.Count -gt 0) {
                    foreach ($Occurrence in $LastHinv) {
                        $Result['LastCycleStartedDate'] = $Occurrence.LastCycleStartedDate
                        $Result['LastReportDate'] = $Occurrence.LastReportDate
                        $Result['LastMajorReportVersion'] = $Occurrence.LastMajorReportVersion
                        $Result['LastMinorReportVersion'] = $Occurrence.LastMinorReportVersion
                        [PSCustomObject]$Result
                    }
                }
                else {
                    Write-Warning "No hardware inventory run found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMLastHardwareInventory.ps1' 101
#Region '.\Public\Get-CCMLastHeartbeat.ps1' 0
function Get-CCMLastHeartbeat {
    <#
        .SYNOPSIS
            Returns info about the last time a heartbeat ran. Also known as a DDR.
        .DESCRIPTION
            This function will return info about the last time Discovery Data Collection Cycle was ran. This is pulled from the InventoryActionStatus WMI Class.
            The Discovery Data Collection Cycle major, and minor version is included.

            This is also known as a 'Heartbeat' or 'DDR'
        .PARAMETER CimSession
            Provides CimSessions to gather Discovery Data Collection Cycle last run info from
        .PARAMETER ComputerName
            Provides computer names to gather Discovery Data Collection Cycle last run info from
        .PARAMETER PSSession
            Provides PSSession to gather Discovery Data Collection Cycle last run info from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Get-CCMLastHeartbeat
                Returns info regarding the last Discovery Data Collection Cycle for the local computer
        .EXAMPLE
        C:\PS> Get-CCMLastHeartbeat -ComputerName 'Workstation1234','Workstation4321'
            Returns info regarding the last Discovery Data Collection Cycle for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMLastHeartbeat.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-01
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CCMLastDDR')]
    param (
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
        $getLastDDRSplat = @{
            Namespace = 'root\CCM\InvAgt'
            Query     = "SELECT LastCycleStartedDate, LastReportDate, LastMajorReportVersion, LastMinorReportVersion, InventoryActionID FROM InventoryActionStatus WHERE InventoryActionID = '{00000000-0000-0000-0000-000000000003}'"
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

            try {
                [ciminstance[]]$LastDDR = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getLastDDRSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getLastDDRSplat @connectionSplat
                    }
                }
                if ($LastDDR -is [Object] -and $LastDDR.Count -gt 0) {
                    foreach ($Occurrence in $LastDDR) {
                        $Result['LastCycleStartedDate'] = $Occurrence.LastCycleStartedDate
                        $Result['LastReportDate'] = $Occurrence.LastReportDate
                        $Result['LastMajorReportVersion'] = $Occurrence.LastMajorReportVersion
                        $Result['LastMinorReportVersion'] = $Occurrence.LastMinorReportVersion
                        [PSCustomObject]$Result
                    }
                }
                else {
                    Write-Warning "No Discovery Data Collection Cycle run found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMLastHeartbeat.ps1' 103
#Region '.\Public\Get-CCMLastScheduleTrigger.ps1' 0
function Get-CCMLastScheduleTrigger {
    <#
        .SYNOPSIS
            Returns the last time a specified schedule was triggered
        .DESCRIPTION
            This function will return the last time a schedule was triggered. Keep in mind this is when a scheduled run happens, such as the periodic machine
            policy refresh. This is why you won't see the timestamp increment if you force a eval, and then check the schedule LastTriggerTime.
        .PARAMETER Schedule
            Specifies the schedule to get trigger history info for. This has a validate set of all possible 'standard' options that the client can perform
            on a schedule.
        .PARAMETER ScheduleID
            Specifies the ScheduleID to get trigger history info for. This is a non-validated parameter that lets you simply query for a ScheduleID of your choosing.
        .PARAMETER ForceWildcard
            Switch that forces the CIM queries to surround your ScheduleID with % and changes the condition to 'LIKE' instead of =
        .PARAMETER CimSession
            Provides CimSessions to gather schedule trigger info from
        .PARAMETER ComputerName
            Provides computer names to gather schedule trigger info from
        .PARAMETER PSSession
            Provides PSSessions to gather schedule trigger info from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the 
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then 
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to. 
        .EXAMPLE
            C:\PS> Get-CCMLastScheduleTrigger -Schedule 'Hardware Inventory'
            Returns a [pscustomobject] detailing the schedule trigger history info available in WMI for Hardware Inventory
        .EXAMPLE
            C:\PS> Get-CCMLastScheduleTrigger -ComputerName 'Workstation1234','Workstation4321' -MWType 'Software Update Service Window'
                Return all the 'Software Update Service Window' Maintenance Windows for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMLastScheduleTrigger.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2019-12-31
            Updated:     2020-02-23
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
        [parameter(Mandatory = $true, ParameterSetName = 'ByName-CimSession')]
        [parameter(Mandatory = $true, ParameterSetName = 'ByName-PSSession')]
        [parameter(Mandatory = $true, ParameterSetName = 'ByName-ComputerName')]
        [ValidateSet('Hardware Inventory',
            'Software Inventory',
            'Discovery Inventory',
            'File Collection',
            'IDMIF Collection',
            'Request Machine Assignments',
            'Evaluate Machine Policies',
            'Refresh Default MP Task',
            'LS (Location Service) Refresh Locations Task',
            'LS Timeout Refresh Task',
            'Policy Agent Request Assignment (User)',
            'Policy Agent Evaluate Assignment (User)',
            'Software Metering Generating Usage Report',
            'Source Update Message',
            'Clearing proxy settings cache',
            'Machine Policy Agent Cleanup',
            'User Policy Agent Cleanup',
            'Policy Agent Validate Machine Policy / Assignment',
            'Policy Agent Validate User Policy / Assignment',
            'Retrying/Refreshing certificates in AD on MP',
            'Peer DP Status reporting',
            'Peer DP Pending package check schedule',
            'SUM Updates install schedule',
            'Hardware Inventory Collection Cycle',
            'Software Inventory Collection Cycle',
            'Discovery Data Collection Cycle',
            'File Collection Cycle',
            'IDMIF Collection Cycle',
            'Software Metering Usage Report Cycle',
            'Windows Installer Source List Update Cycle',
            'Software Updates Policy Action Software Updates Assignments Evaluation Cycle',
            'PDP Maintenance Policy Branch Distribution Point Maintenance Task',
            'DCM policy',
            'Send Unsent State Message',
            'State System policy cache cleanout',
            'Update source policy',
            'Update Store Policy',
            'State system policy bulk send high',
            'State system policy bulk send low',
            'Application manager policy action',
            'Application manager user policy action',
            'Application manager global evaluation action',
            'Power management start summarizer',
            'Endpoint deployment reevaluate',
            'Endpoint AM policy reevaluate',
            'External event detection')]
        [string[]]$Schedule,
        [parameter(Mandatory = $true, ParameterSetName = 'ByID-CimSession')]
        [parameter(Mandatory = $true, ParameterSetName = 'ByID-PSSession')]
        [parameter(Mandatory = $true, ParameterSetName = 'ByID-ComputerName')]
        [string[]]$ScheduleID,
        [parameter(Mandatory = $false, ParameterSetName = 'ByID-CimSession')]
        [parameter(Mandatory = $false, ParameterSetName = 'ByID-PSSession')]
        [parameter(Mandatory = $false, ParameterSetName = 'ByID-ComputerName')]
        [switch]$ForceWildcard,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByName-CimSession')]
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByID-CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByName-ComputerName')]
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByID-ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName,
        [parameter(Mandatory = $true, ParameterSetName = 'ByName-PSSession')]
        [parameter(Mandatory = $true, ParameterSetName = 'ByID-PSSession')]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession,
        [parameter(Mandatory = $true, ParameterSetName = 'ByName-ComputerName')]
        [parameter(Mandatory = $true, ParameterSetName = 'ByID-ComputerName')]
        [ValidateSet('CimSession', 'PSSession')]
        [string]$ConnectionPreference
    )
    begin {
        $ConnectionChecker = ($PSCmdlet.ParameterSetName).Split('-')[1]

        #region hashtable for mapping schedule names to IDs, and create CIM query
        $ScheduleTypeMap = @{
            'Hardware Inventory'                                                           = '{00000000-0000-0000-0000-000000000001}'
            'Software Inventory'                                                           = '{00000000-0000-0000-0000-000000000002}'
            'Discovery Inventory'                                                          = '{00000000-0000-0000-0000-000000000003}'
            'File Collection'                                                              = '{00000000-0000-0000-0000-000000000010}'
            'IDMIF Collection'                                                             = '{00000000-0000-0000-0000-000000000011}'
            'Request Machine Assignments'                                                  = '{00000000-0000-0000-0000-000000000021}'
            'Evaluate Machine Policies'                                                    = '{00000000-0000-0000-0000-000000000022}'
            'Refresh Default MP Task'                                                      = '{00000000-0000-0000-0000-000000000023}'
            'LS (Location Service) Refresh Locations Task'                                 = '{00000000-0000-0000-0000-000000000024}'
            'LS Timeout Refresh Task'                                                      = '{00000000-0000-0000-0000-000000000025}'
            'Policy Agent Request Assignment (User)'                                       = '{00000000-0000-0000-0000-000000000026}'
            'Policy Agent Evaluate Assignment (User)'                                      = '{00000000-0000-0000-0000-000000000027}'
            'Software Metering Generating Usage Report'                                    = '{00000000-0000-0000-0000-000000000031}'
            'Source Update Message'                                                        = '{00000000-0000-0000-0000-000000000032}'
            'Clearing proxy settings cache'                                                = '{00000000-0000-0000-0000-000000000037}'
            'Machine Policy Agent Cleanup'                                                 = '{00000000-0000-0000-0000-000000000040}'
            'User Policy Agent Cleanup'                                                    = '{00000000-0000-0000-0000-000000000041}'
            'Policy Agent Validate Machine Policy / Assignment'                            = '{00000000-0000-0000-0000-000000000042}'
            'Policy Agent Validate User Policy / Assignment'                               = '{00000000-0000-0000-0000-000000000043}'
            'Retrying/Refreshing certificates in AD on MP'                                 = '{00000000-0000-0000-0000-000000000051}'
            'Peer DP Status reporting'                                                     = '{00000000-0000-0000-0000-000000000061}'
            'Peer DP Pending package check schedule'                                       = '{00000000-0000-0000-0000-000000000062}'
            'SUM Updates install schedule'                                                 = '{00000000-0000-0000-0000-000000000063}'
            'Hardware Inventory Collection Cycle'                                          = '{00000000-0000-0000-0000-000000000101}'
            'Software Inventory Collection Cycle'                                          = '{00000000-0000-0000-0000-000000000102}'
            'Discovery Data Collection Cycle'                                              = '{00000000-0000-0000-0000-000000000103}'
            'File Collection Cycle'                                                        = '{00000000-0000-0000-0000-000000000104}'
            'IDMIF Collection Cycle'                                                       = '{00000000-0000-0000-0000-000000000105}'
            'Software Metering Usage Report Cycle'                                         = '{00000000-0000-0000-0000-000000000106}'
            'Windows Installer Source List Update Cycle'                                   = '{00000000-0000-0000-0000-000000000107}'
            'Software Updates Policy Action Software Updates Assignments Evaluation Cycle' = '{00000000-0000-0000-0000-000000000108}'
            'PDP Maintenance Policy Branch Distribution Point Maintenance Task'            = '{00000000-0000-0000-0000-000000000109}'
            'DCM policy'                                                                   = '{00000000-0000-0000-0000-000000000110}'
            'Send Unsent State Message'                                                    = '{00000000-0000-0000-0000-000000000111}'
            'State System policy cache cleanout'                                           = '{00000000-0000-0000-0000-000000000112}'
            'Update source policy'                                                         = '{00000000-0000-0000-0000-000000000113}'
            'Update Store Policy'                                                          = '{00000000-0000-0000-0000-000000000114}'
            'State system policy bulk send high'                                           = '{00000000-0000-0000-0000-000000000115}'
            'State system policy bulk send low'                                            = '{00000000-0000-0000-0000-000000000116}'
            'Application manager policy action'                                            = '{00000000-0000-0000-0000-000000000121}'
            'Application manager user policy action'                                       = '{00000000-0000-0000-0000-000000000122}'
            'Application manager global evaluation action'                                 = '{00000000-0000-0000-0000-000000000123}'
            'Power management start summarizer'                                            = '{00000000-0000-0000-0000-000000000131}'
            'Endpoint deployment reevaluate'                                               = '{00000000-0000-0000-0000-000000000221}'
            'Endpoint AM policy reevaluate'                                                = '{00000000-0000-0000-0000-000000000222}'
            'External event detection'                                                     = '{00000000-0000-0000-0000-000000000223}'
        }

        $RequestedSchedulesRaw = switch ($PSBoundParameters.Keys) {
            'Schedule' {
                foreach ($One in $Schedule) {
                    $ScheduleTypeMap[$One]
                }
            }
            'ScheduleID' {
                $ScheduleID
            }
        }
        $RequestedScheduleQuery = switch($ForceWildcard) {
            $true {
                switch ($RequestedSchedulesRaw -match '%') {
                    $true {
                        [string]::Format('SELECT * FROM CCM_Scheduler_History WHERE ScheduleID LIKE "{0}"', [string]::Join('" OR ScheduleID LIKE "', $RequestedSchedulesRaw))
                    }
                    $false {
                        [string]::Format('SELECT * FROM CCM_Scheduler_History WHERE ScheduleID LIKE "%{0}%"', [string]::Join('%" OR ScheduleID LIKE "%', $RequestedSchedulesRaw))
                    }
                }
            }
            $false {
                [string]::Format('SELECT * FROM CCM_Scheduler_History WHERE ScheduleID = "{0}"', [string]::Join('" OR ScheduleID = "', $RequestedSchedulesRaw))
            }
        }
        #endregion hashtable for mapping schedule names to IDs, and create CIM query

        $getSchedHistSplat = @{
            Namespace = 'root\CCM\Scheduler'
            Query     = $RequestedScheduleQuery
        }
    }
    process {
		foreach ($Connection in (Get-Variable -Name $ConnectionChecker -ValueOnly -Scope Local)) {
			$getConnectionInfoSplat = @{
				$ConnectionChecker = $Connection
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

            try {
                [ciminstance[]]$ScheduleHistory = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getSchedHistSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getSchedHistSplat @connectionSplat
                    }
                }
                if ($ScheduleHistory -is [Object] -and $ScheduleHistory.Count -gt 0) {
                    foreach ($Trigger in $ScheduleHistory) {
                        $Result['ScheduleID'] = $Trigger.ScheduleID
                        $Result['Schedule'] = $ScheduleTypeMap.Keys.Where( { $ScheduleTypeMap[$_] -eq $Trigger.ScheduleID } )
                        $Result['UserSID'] = $Trigger.UserSID
                        $Result['FirstEvalTime'] = $Trigger.FirstEvalTime
                        $Result['ActivationMessageSent'] = $Trigger.ActivationMessageSent
                        $Result['ActivationMessageSentIsGMT'] = $Trigger.ActivationMessageSentIsGMT
                        $Result['ExpirationMessageSent'] = $Trigger.ExpirationMessageSent
                        $Result['ExpirationMessageSentIsGMT'] = $Trigger.ExpirationMessageSentIsGMT
                        $Result['LastTriggerTime'] = $Trigger.LastTriggerTime
                        $Result['TriggerState'] = $Trigger.TriggerState
                        [PSCustomObject]$Result
                    }
                }
                else {
                    Write-Warning "No triggered schedules found for [Query = '$RequestedScheduleQuery']"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMLastScheduleTrigger.ps1' 253
#Region '.\Public\Get-CCMLastSoftwareInventory.ps1' 0
function Get-CCMLastSoftwareInventory {
    <#
        .SYNOPSIS
            Returns info about the last time Software Inventory ran
        .DESCRIPTION
            This function will return info about the last time Software Inventory was ran. This is pulled from the InventoryActionStatus WMI Class.
            The Software inventory major, and minor version is included. This can be helpful in troubleshooting Software inventory issues.
        .PARAMETER CimSession
            Provides CimSession to gather Software inventory last run info from
        .PARAMETER ComputerName
            Provides computer names to gather Software inventory last run info from
        .PARAMETER PSSession
            Provides PSSessions to gather Software inventory last run info from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Get-CCMLastSoftwareInventory
                Returns info regarding the last Software inventory cycle for the local computer
        .EXAMPLE
            C:\PS> Get-CCMLastSoftwareInventory -ComputerName 'Workstation1234','Workstation4321'
                Returns info regarding the last Software inventory cycle for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMLastSoftwareInventory.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-01
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CCMLastSINV')]
    param (
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
        $getLastSINVSplat = @{
            Namespace = 'root\CCM\InvAgt'
            Query     = "SELECT LastCycleStartedDate, LastReportDate, LastMajorReportVersion, LastMinorReportVersion, InventoryActionID FROM InventoryActionStatus WHERE InventoryActionID = '{00000000-0000-0000-0000-000000000002}'"
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

            try {
                [ciminstance[]]$LastSINV = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getLastSINVSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getLastSINVSplat @connectionSplat
                    }
                }
                if ($LastSINV -is [Object] -and $LastSINV.Count -gt 0) {
                    foreach ($Occurrence in $LastSINV) {
                        $Result['LastCycleStartedDate'] = $Occurrence.LastCycleStartedDate
                        $Result['LastReportDate'] = $Occurrence.LastReportDate
                        $Result['LastMajorReportVersion'] = $Occurrence.LastMajorReportVersion
                        $Result['LastMinorReportVersion'] = $Occurrence.LastMinorReportVersion
                        [PSCustomObject]$Result
                    }
                }
                else {
                    Write-Warning "No Software inventory run found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMLastSoftwareInventory.ps1' 101
#Region '.\Public\Get-CCMLogFile.ps1' 0
Function Get-CCMLogFile {
    <#
        .SYNOPSIS
            Parse Configuration Manager format logs
        .DESCRIPTION
            This function is used to take Configuration Manager formatted logs and turn them into a PSCustomObject so that it can be
            searched and manipulated easily with PowerShell
        .PARAMETER Path
            Path to the log file(s) you would like to parse.
        .PARAMETER ParseSMSTS
            Only pulls out the TS actions. This is for parsing an SMSTSLog specifically
        .PARAMETER Filter
            A custom regex filter to use when reading in log lines
        .PARAMETER Severity
            A filter to return only messages of a particular severity. By default, all severities are returned.
        .PARAMETER TimestampGreaterThan
            A [datetime] object that will filter the returned log lines. They will only be returned if they are greater than or 
            equal to the provided [datetime]
        .PARAMETER TimestampLessThan
            A [datetime] object that will filter the returned log lines. They will only be returned if they are less than or 
            equal to the provided [datetime]
        .EXAMPLE
            PS C:\> Get-CCMLogFile -Path 'c:\windows\ccm\logs\ccmexec.log'
                Returns the CCMExec.log as a PSCustomObject
        .EXAMPLE
            PS C:\> Get-CCMLogFile -Path 'c:\windows\ccm\logs\AppEnforce.log', 'c:\windows\ccm\logs\AppDiscovery.log' | Sort-Object -Property Timestamp
                Returns the AppEnforce.log and AppDiscovery.log as a PSCustomObject sorted by Timestamp
        .EXAMPLE
            PS C:\> Get-CCMLogFile -Path 'c:\windows\ccm\logs\smstslog.log' -ParseSMSTS
                Returns all the actions that ran according to the SMSTSLog provided
        .EXAMPLE
            PS C:\> Get-CCMLogFile -Path 'c:\windows\ccm\logs\cas.log' -Filter "Successfully created download  request \{(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}\} for content (\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}\.\d+"
                Return all log entires from the CAS.Log which pertain creating download requests for updates
        .EXAMPLE
            PS C:\> Get-CCMLogFile -Path C:\windows\ccm\logs\AppDiscovery.log -TimestampGreaterThan (Get-Date).AddDays(-1)
                Returns all log entries from the AppDiscovery.log file which have a timestamp within the last day
        .OUTPUTS
            [pscustomobject[]]
        .NOTES
            I've done my best to test this against various MEMCM log files. They are all generally 'formatted' the same, but do have some
            variance. I had to also balance speed and parsing.

            With that said, it can still parse a typical MEMCM log VERY quickly. Smaller logs are parsed in milliseconds in my testing.
            Rolled over logs that are 5mb can be parsed in a couple seconds or less. The -Filter option provides a great deal of
            flexibility and speed as well.

                FileName: Get-CCMLogFile.ps1
                Author:   Cody Mathis
                Contact:  @CodyMathis123
                Created:  2019-09-19
                Updated:  2020-08-02
    #>
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    [OutputType([pscustomobject[]]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)]
        [Alias('Fullname', 'LogFilePath')]
        [string[]]$Path,
        [Parameter(Mandatory = $false, ParameterSetName = 'ParseSMSTS')]
        [switch]$ParseSMSTS,
        [Parameter(Mandatory = $false, ParameterSetName = 'CustomFilter')]
        [string]$Filter,
        [Parameter(Mandatory = $false)]
        [ValidateSet('None', 'Informational', 'Warning', 'Error')]
        [string[]]$Severity = @('None', 'Informational', 'Warning', 'Error'),
        [Parameter(Mandatory = $false)]
        [datetime]$TimestampGreaterThan,
        [Parameter(Mandatory = $false)]
        [datetime]$TimestampLessThan
    )
    begin {
        enum Severity {
            None
            Informational
            Warning
            Error
        }
        function Get-TimeStampFromLogLine {
            <#
            .SYNOPSIS
                Parses a datetime object from an MEMCM log line
            .DESCRIPTION
                This will return a datetime object if it is passed the part of an MEMCM log line that contains the date and time
            .PARAMETER DateString
                The Date String component from a MEMCM log line. For example, '01-31-2020'
            .PARAMETER TimeString
                 The Time String component from a MEMCM log line. For example, '14:20:41.461'
            .EXAMPLE
                PS C:\> Get-TimeStampFromLogLine -LogLineSubArray $LogLineSubArray
                return datetime object from the log line that was split into a subarray
            #>
            param (
                [Parameter(Mandatory = $true)]
                [string]$DateString,
                [Parameter(Mandatory = $true)]
                [string]$TimeString
            )
            $DateStringArray = $DateString.Split([char]45)

            $MonthParser = $DateStringArray[0] -replace '\d', 'M'
            $DayParser = $DateStringArray[1] -replace '\d', 'd'

            $DateTimeFormat = [string]::Format('{0}-{1}-yyyyHH:mm:ss.fff', $MonthParser, $DayParser)
            $DateTimeString = [string]::Format('{0}{1}', $DateString, $TimeString)
            [datetime]::ParseExact($DateTimeString, $DateTimeFormat, $null)
        }

        function Test-TimestampFilter {
            <#
                .SYNOPSIS
                    Returns boolean based on timestamp meeting ge/le conditons
                .DESCRIPTION
                    This function is used to determine if a particular time stamp is less than or equal to, and/or greater than
                    or equal to the specified timestamps
                .PARAMETER TimeStamp
                    The timestamp to compare as a [datetime] object
                .PARAMETER GreaterThanDateTime
                    A [datetime] object used to ensure the $Timestmap is greater than or equal to
                .PARAMETER LessThanDateTime
                    A [datetime] object used to ensure the $Timestmap is less than or equal to
                .EXAMPLE
                    C:\PS> Test-TimestampFilter -TimeStamp (get-date) -GreaterThanDateTime (get-date).AddDays(-1) -LessThanDateTime (get-date).AddDays(1)
                        This will return a result of $True as we test if the current date is greater than 1 day ago, and less than 1 day from now
                .OUTPUTS
                    [bool]
            #>
            param(
                [parameter(Mandatory = $true)]
                [datetime]$TimeStamp,
                [parameter(Mandatory = $false)]
                [datetime]$TimestampGreaterThan,
                [parameter(Mandatory = $false)]
                [datetime]$TimestampLessThan
            )
            [array]$Result = switch ($PSBoundParameters.Keys) {
                TimestampGreaterThan {
                    $TimeStamp -ge $TimestampGreaterThan
                }
                TimestampLessThan {
                    $TimeStamp -le $TimestampLessThan
                }
                default {
                    $true
                }
            }

            $Result.Contains($true) -and !$Result.Contains($false)
        }

        #region setup the TestTimeStampSplat, if either parameter is specified we will validate the timestamp
        $CheckTimestampFilter = $false
        $TestTimestampSplat = @{}
        switch ($PSBoundParameters.Keys) {
            TimestampGreaterThan {
                $CheckTimestampFilter = $true
                $TestTimestampSplat.Add($PSItem, $TimestampGreaterThan)
            }
            TimestampLessThan {
                $CheckTimestampFilter = $true
                $TestTimestampSplat.Add($PSItem, $TimestampLessThan)
            }
        }
        #endregion setup the TestTimeStampSplat, if either parameter is specified we will validate the timestamp
    }
    process {
        foreach ($LogFile in $Path) {
            #region ingest log file with StreamReader. Quick, and prevents locks
            $File = [System.IO.File]::Open($LogFile, 'Open', 'Read', 'ReadWrite')
            $StreamReader = New-Object System.IO.StreamReader($File)
            [string]$LogFileRaw = $StreamReader.ReadToEnd()
            $StreamReader.Close()
            $File.Close()
            #endregion ingest log file with StreamReader. Quick, and prevents locks

            #region perform a regex match to determine the 'type' of log we are working with and parse appropriately
            switch -regex ($LogFileRaw) {
                #region parse a 'typical' MEMCM log
                'LOG\[(.*?)\]LOG(.*?)time(.*?)date' {
                    # split on what we know is a line beginning
                    switch -regex ([regex]::Split($LogFileRaw, '<!\[LOG\[')) {
                        #region ignore empty lines in file
                        '^\s*$' {
                            # ignore empty lines
                            continue
                        }
                        #endregion ignore empty lines in file

                        #region process non-empty lines from file
                        default {
                            <#
                                split Log line into an array on what we know is the end of the message section
                                first item contains the message which can be parsed
                                second item contains all the information about the message/line (ie. type, component, datetime, thread) which can be parsed
                            #>
                            $LogLineArray = [regex]::Split($PSItem, ']LOG]!><')

                            # Strip the log message out of our first array index
                            $Message = $LogLineArray[0]

                            # Split LogLineArray into a a sub array based on double quotes to pull log line information
                            $LogLineSubArray = $LogLineArray[1].Split([char]34)

                            $LogLine = [ordered]@{ }
                            # Rebuild the LogLine into a hash table
                            $LogLine['Message'] = $Message
                            $Type = [Severity]$LogLineSubArray[9]
                            $LogLine['Type'] = $Type
                            $LogLine['Component'] = $LogLineSubArray[5]
                            $LogLine['Thread'] = $LogLineSubArray[11]

                            #region prase log based on severity, which defaults to any severity if the parameter is not specified
                            switch ($Severity) {
                                ($Type) {
                                    switch ($PSCmdlet.ParameterSetName) {
                                        #region if ParseSMSTS specified, check message for known string for SMS step success / failure
                                        ParseSMSTS {
                                            switch -regex ($Message) {
                                                'win32 code 0|failed to run the action' {
                                                    $DateString = $LogLineSubArray[3]
                                                    $TimeString = $LogLineSubArray[1].Split([char]43, [char]45, [System.StringSplitOptions]::RemoveEmptyEntries)[0].Substring(0, 12)
                                                    $LogLine['TimeStamp'] = Get-TimeStampFromLogLine -DateString $DateString -TimeString $TimeString
                                                    switch ($CheckTimestampFilter) {
                                                        $true {
                                                            switch (Test-TimestampFilter -TimeStamp $LogLine.TimeStamp @TestTimestampSplat) {
                                                                $true {
                                                                    [pscustomobject]$LogLine
                                                                }
                                                            }
                                                        }
                                                        $false {
                                                            [pscustomobject]$LogLine
                                                        }
                                                    }
                                                }
                                                default {
                                                    continue
                                                }
                                            }
                                        }
                                        #endregion if ParseSMSTS specified, check message for known string for SMS step success / failure

                                        #region if CustomerFilter is specified, check message against the string as a regex match
                                        CustomFilter {
                                            switch -regex ($Message) {
                                                $Filter {
                                                    $DateString = $LogLineSubArray[3]
                                                    $TimeString = $LogLineSubArray[1].Split([char]43, [char]45, [System.StringSplitOptions]::RemoveEmptyEntries)[0].Substring(0, 12)
                                                    $LogLine['TimeStamp'] = Get-TimeStampFromLogLine -DateString $DateString -TimeString $TimeString
                                                    switch ($CheckTimestampFilter) {
                                                        $true {
                                                            switch (Test-TimestampFilter -TimeStamp $LogLine.TimeStamp @TestTimestampSplat) {
                                                                $true {
                                                                    [pscustomobject]$LogLine
                                                                }
                                                            }
                                                        }
                                                        $false {
                                                            [pscustomobject]$LogLine
                                                        }
                                                    }
                                                }
                                                default {
                                                    continue
                                                }
                                            }
                                        }
                                        #endregion if CustomerFilter is specified, check message against the string as a regex match

                                        #region if no filtering is provided then the we return all messages
                                        default {
                                            $DateString = $LogLineSubArray[3]
                                            $TimeString = $LogLineSubArray[1].Split([char]43, [char]45, [System.StringSplitOptions]::RemoveEmptyEntries)[0].Substring(0, 12)
                                            $LogLine['TimeStamp'] = Get-TimeStampFromLogLine -DateString $DateString -TimeString $TimeString
                                            switch ($CheckTimestampFilter) {
                                                $true {
                                                    switch (Test-TimestampFilter -TimeStamp $LogLine.TimeStamp @TestTimestampSplat) {
                                                        $true {
                                                            [pscustomobject]$LogLine
                                                        }
                                                    }
                                                }
                                                $false {
                                                    [pscustomobject]$LogLine
                                                }
                                            }
                                        }
                                        #endregion if no filtering is provided then the we return all messages
                                    }
                                }
                                default {
                                    continue
                                }
                            }
                            #endregion prase log based on severity, which defaults to any severity if the parameter is not specified
                        }
                        #endregion process non-empty lines from file
                    }
                }
                #endregion parse a 'typical' MEMCM log

                #region parse a 'simple' MEMCM log, usually found on site systems
                '\$\$\<(.*?)\>\<thread=' {
                    switch -regex ($LogFileRaw -split [System.Environment]::NewLine) {
                        #region ignore empty lines in file
                        '^\s*$' {
                            # ignore empty lines
                            continue
                        }
                        #endregion ignore empty lines in file

                        #region process non-empty lines from file
                        default {
                            <#
                                split Log line into an array
                                first item contains the message which can be parsed
                                second item contains all the information about the message/line (ie. type, component, timestamp, thread) which can be parsed
                            #>
                            $LogLineArray = [regex]::Split($PSItem, '\$\$<')

                            # Strip the log message out of our first array index
                            $Message = $LogLineArray[0]

                            # Split LogLineArray into a a sub array based on double quotes to pull log line information
                            $LogLineSubArray = $LogLineArray[1].Split('><', [System.StringSplitOptions]::RemoveEmptyEntries)

                            switch -regex ($Message) {
                                #region ignore empty message lines
                                '^\s*$' {
                                    # ignore empty messages
                                    continue
                                }
                                #endregion ignore empty message lines

                                #region process non-empty message lines
                                default {
                                    $LogLine = [ordered]@{ }
                                    # Rebuild the LogLine into a hash table
                                    $LogLine['Message'] = $Message
                                    $LogLine['Type'] = [Severity]0
                                    $LogLine['Component'] = $LogLineSubArray[0].Trim()
                                    $LogLine['Thread'] = ($LogLineSubArray[2].Split([char]32, [System.StringSplitOptions]::RemoveEmptyEntries))[0].Substring(7)

                                    #region parse the log based on our Parameter Set Name
                                    switch ($PSCmdlet.ParameterSetName) {
                                        #region if CustomerFilter is specified, check message against the string as a regex match
                                        CustomFilter {
                                            switch -regex ($Message) {
                                                $Filter {
                                                    $DateTimeString = $LogLineSubArray[1]
                                                    $DateTimeStringArray = $DateTimeString.Split([char]32, [System.StringSplitOptions]::RemoveEmptyEntries)
                                                    $DateString = $DateTimeStringArray[0]
                                                    $TimeString = $DateTimeStringArray[1].Split([char]43, [char]45, [System.StringSplitOptions]::RemoveEmptyEntries)[0].Substring(0, 12)
                                                    $LogLine['TimeStamp'] = Get-TimeStampFromLogLine -DateString $DateString -TimeString $TimeString
                                                    switch ($CheckTimestampFilter) {
                                                        $true {
                                                            switch (Test-TimestampFilter -TimeStamp $LogLine.TimeStamp @TestTimestampSplat) {
                                                                $true {
                                                                    [pscustomobject]$LogLine
                                                                }
                                                            }
                                                        }
                                                        $false {
                                                            [pscustomobject]$LogLine
                                                        }
                                                    }
                                                }
                                                default {
                                                    continue
                                                }
                                            }
                                        }
                                        #endregion if CustomerFilter is specified, check message against the string as a regex match

                                        #region if no filtering is provided then the we return all messages
                                        default {
                                            $DateTimeString = $LogLineSubArray[1]
                                            $DateTimeStringArray = $DateTimeString.Split([char]32, [System.StringSplitOptions]::RemoveEmptyEntries)
                                            $DateString = $DateTimeStringArray[0]
                                            $TimeString = $DateTimeStringArray[1].Split([char]43, [char]45, [System.StringSplitOptions]::RemoveEmptyEntries)[0].Substring(0, 12)
                                            $LogLine['TimeStamp'] = Get-TimeStampFromLogLine -DateString $DateString -TimeString $TimeString
                                            switch ($CheckTimestampFilter) {
                                                $true {
                                                    switch (Test-TimestampFilter -TimeStamp $LogLine.TimeStamp @TestTimestampSplat) {
                                                        $true {
                                                            [pscustomobject]$LogLine
                                                        }
                                                    }
                                                }
                                                $false {
                                                    [pscustomobject]$LogLine
                                                }
                                            }
                                        }
                                        #endregion if no filtering is provided then the we return all messages
                                    }
                                    #endregion parse the log based on our Parameter Set Name
                                }
                                #region process non-empty message lines
                            }
                        }
                        #endregion process non-empty lines from file
                    }
                }
                #endregion parse a 'simple' MEMCM log, usually found on site systems
            }
            #endregion perform a regex match to determine the 'type' of log we are working with and parse appropriately
        }
    }
}
#EndRegion '.\Public\Get-CCMLogFile.ps1' 409
#Region '.\Public\Get-CCMLoggingConfiguration.ps1' 0
function Get-CCMLoggingConfiguration {
    <#
        .SYNOPSIS
            Get ConfigMgr client log info from computers via CIM
        .DESCRIPTION
            This function will allow you to gather the ConfigMgr client log info info from multiple computers using CIM queries.
            You can provide an array of computer names, or cimsessions, or you can pass them through the pipeline.
        .PARAMETER CimSession
            Provides CimSession to gather log info from.
        .PARAMETER ComputerName
            Provides computer names to gather log info from.
        .PARAMETER PSSessions
            Provides PSSessionss to gather log info from.
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Get-CCMLoggingConfiguration
                Return ConfigMgr client log info info for the local computer
        .EXAMPLE
            C:\PS> Get-CCMLoggingConfiguration -ComputerName 'Workstation1234','Workstation4321'
                Return ConfigMgr client log info info for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMLoggingConfiguration.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-10
            Updated:     2020-03-03
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
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
        $getLogInfoSplat = @{
            Namespace   = 'root\ccm\policy\machine\actualconfig'
            ClassName   = 'CCM_Logging_GlobalConfiguration'
            ErrorAction = 'Stop'
        }
        $getLogLocationSplat = @{
            Property = 'LogDirectory'
            Key      = 'SOFTWARE\Microsoft\CCM\Logging\@Global'
            RegRoot  = 'HKEY_LOCAL_MACHINE'
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

            try {
                [ciminstance[]]$CimResult = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getLogInfoSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getLogInfoSplat @connectionSplat
                    }
                }
                if ($CimResult -is [Object] -and $CimResult.Count -gt 0) {
                    foreach ($Object in $CimResult) {
                        $Result['LogDirectory'] = (Get-CCMRegistryProperty @getLogLocationSplat @connectionSplat)[$Computer].LogDirectory
                        $Result['LogMaxSize'] = $Object.LogMaxSize
                        $Result['LogMaxHistory'] = $Object.LogMaxHistory
                        $Result['LogLevel'] = $Object.LogLevel
                        $Result['LogEnabled'] = $Object.LogEnabled
                        [PSCustomObject]$Result
                    }
                }
                else {
                    $Result['LogDirectory'] = $null
                    $Result['LogMaxSize'] = $null
                    $Result['LogMaxHistory'] = $null
                    $Result['LogLevel'] = $null
                    $Result['LogEnabled'] = $null
                    [PSCustomObject]$Result
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMLoggingConfiguration.ps1' 112
#Region '.\Public\Get-CCMMaintenanceWindow.ps1' 0
function Get-CCMMaintenanceWindow {
    <#
        .SYNOPSIS
            Get ConfigMgr Maintenance Window information from computers via CIM
        .DESCRIPTION
            This function will allow you to gather maintenance window information from multiple computers using CIM queries. You can provide an array of computer names, or cimsessions,
            or you can pass them through the pipeline. You are also able to specify the Maintenance Window Type (MWType) you wish to query for.
        .PARAMETER MWType
            Specifies the types of MW you want information for. Valid options are below
                'All Deployment Service Window',
                'Program Service Window',
                'Reboot Required Service Window',
                'Software Update Service Window',
                'Task Sequences Service Window',
                'Corresponds to non-working hours'
        .PARAMETER CimSession
            Provides CimSession to gather Maintenance Window information info from
        .PARAMETER ComputerName
            Provides computer names to gather Maintenance Window information info from
        .PARAMETER PSSession
            Provides PSSessions to gather Maintenance Window information info from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Get-CCMMaintenanceWindow
                Return all the 'All Deployment Service Window', 'Software Update Service Window' Maintenance Windows for the local computer. These are the two default MW types
                that the function looks for
        .EXAMPLE
            C:\PS> Get-CCMMaintenanceWindow -ComputerName 'Workstation1234','Workstation4321' -MWType 'Software Update Service Window'
                Return all the 'Software Update Service Window' Maintenance Windows for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMMaintenanceWindow.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2019-08-14
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CCMMW')]
    param (
        [parameter(Mandatory = $false)]
        [ValidateSet('All Deployment Service Window',
            'Program Service Window',
            'Reboot Required Service Window',
            'Software Update Service Window',
            'Task Sequences Service Window',
            'Corresponds to non-working hours')]
        [string[]]$MWType = @('All Deployment Service Window', 'Software Update Service Window'),
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
        #region Create hashtable for mapping MW types, and create CIM filter based on input params
        $MW_Type = @{
            1	=	'All Deployment Service Window'
            2	=	'Program Service Window'
            3	=	'Reboot Required Service Window'
            4	=	'Software Update Service Window'
            5	=	'Task Sequences Service Window'
            6	=	'Corresponds to non-working hours'
        }

        $RequestedTypesRaw = $MW_Type.Keys.Where( { $MW_Type[$_] -in $MWType } )
        $RequestedTypesFilter = [string]::Format('Type = {0}', [string]::Join(' OR Type =', $RequestedTypesRaw))
        #endregion Create hashtable for mapping MW types, and create CIM filter based on input params

        $getMaintenanceWindowSplat = @{
            Namespace = 'root\CCM\ClientSDK'
            ClassName = 'CCM_ServiceWindow'
            Filter    = $RequestedTypesFilter
        }
        $getTimeZoneSplat = @{
            Query = 'SELECT Caption FROM Win32_TimeZone'
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

            try {
                $TZ = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getTimeZoneSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getTimeZoneSplat @connectionSplat
                    }
                }
                $Result['TimeZone'] = $TZ.Caption

                [ciminstance[]]$ServiceWindows = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getMaintenanceWindowSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getMaintenanceWindowSplat @connectionSplat
                    }
                }

                if ($ServiceWindows -is [Object] -and $ServiceWindows.Count -gt 0) {
                    foreach ($ServiceWindow in $ServiceWindows) {
                        $Result['StartTime'] = ($ServiceWindow.StartTime).ToUniversalTime()
                        $Result['EndTime'] = ($ServiceWindow.EndTime).ToUniversalTime()
                        $Result['Duration'] = $ServiceWindow.Duration
                        $Result['DurationDescription'] = Get-StringFromTimespan -Seconds $ServiceWindow.Duration
                        $Result['MWID'] = $ServiceWindow.ID
                        $Result['Type'] = $MW_Type.Item([int]$($ServiceWindow.Type))
                        [PSCustomObject]$Result
                    }
                }
                else {
                    $Result['StartTime'] = $null
                    $Result['EndTime'] = $null
                    $Result['Duration'] = $null
                    $Result['DurationDescription'] = $null
                    $Result['MWID'] = $null
                    $Result['Type'] = "No ServiceWindow of type(s) $([string]::Join(', ',$RequestedTypesRaw))"
                    [PSCustomObject]$Result
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMMaintenanceWindow.ps1' 155
#Region '.\Public\Get-CCMPackage.ps1' 0
function Get-CCMPackage {
    <#
        .SYNOPSIS
            Return deployed packages from a computer
        .DESCRIPTION
            Pulls a list of deployed packages from the specified computer(s) or CIMSession(s) with optional filters, and can be passed on
            to Invoke-CCMPackage if desired.

            Note that the parameters for filter are all joined together with OR.
        .PARAMETER PackageID
            An array of PackageID to filter on
        .PARAMETER PackageName
            An array of package names to filter on
        .PARAMETER ProgramName
            An array of program names to filter on
        .PARAMETER CimSession
            Provides CimSession to gather deployed package info from
        .PARAMETER ComputerName
            Provides computer names to gather deployed package info from
        .PARAMETER PSSession
            Provides PSSessions to gather deployed package info from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            PS> Get-CCMPackage
                Returns all deployed packages listed in WMI on the local computer
        .EXAMPLE
            PS> Get-CCMPackage -PackageName 'Software Install' -ProgramName 'Software Install - Silent'
                Returns all deployed packages listed in WMI on the local computer which have either a package name of 'Software Install' or
                a Program Name of 'Software Install - Silent'
        .NOTES
            FileName:    Get-CCMPackage.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-12
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$PackageID,
        [Parameter(Mandatory = $false)]
        [string[]]$PackageName,
        [Parameter(Mandatory = $false)]
        [string[]]$ProgramName,
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
        #region define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
        $getPackageSplat = @{
            NameSpace = 'root\CCM\Policy\Machine\ActualConfig'
        }
        #endregion define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
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

            try {
                $FilterParts = switch ($PSBoundParameters.Keys) {
                    'PackageID' {
                        [string]::Format('PKG_PackageID = "{0}"', [string]::Join('" OR PKG_PackageID = "', $PackageID))
                    }
                    'PackageName' {
                        [string]::Format('PKG_Name = "{0}"', [string]::Join('" OR PKG_Name = "', $PackageName))
                    }
                    'ProgramName' {
                        [string]::Format('PRG_ProgramName = "{0}"', [string]::Join('" OR PRG_ProgramName = "', $ProgramName))
                    }
                }
                $Filter = switch ($null -ne $FilterParts) {
                    $true {
                        [string]::Format(' WHERE {0}', [string]::Join(' OR ', $FilterParts))
                    }
                    $false {
                        ' '
                    }
                }
                $getPackageSplat['Query'] = [string]::Format('SELECT * FROM CCM_SoftwareDistribution{0}', $Filter)

                [ciminstance[]]$Packages = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getPackageSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getPackageSplat @connectionSplat
                    }
                }
                if ($Packages -is [Object] -and $Packages.Count -gt 0) {
                    Write-Output -InputObject $Packages
                }
                else {
                    Write-Warning "No deployed package found for $Computer based on input filters"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMPackage.ps1' 129
#Region '.\Public\Get-CCMPrimaryUser.ps1' 0
function Get-CCMPrimaryUser {
    <#
        .SYNOPSIS
            Return primary users for a computer
        .DESCRIPTION
            Pulls a list of primary users from WMI on the specified computer(s) or CIMSession(s)
        .PARAMETER CimSession
            Provides CimSession to gather primary users info from
        .PARAMETER ComputerName
            Provides computer names to gather primary users info from
        .PARAMETER PSSession
            Provides PSSessions to gather primary users info from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            PS> Get-CCMPrimaryUser
                Returns all primary users listed in WMI on the local computer
        .NOTES
            FileName:    Get-CCMPrimaryUser.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-05
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
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
        #region define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
        $getPrimaryUserSplat = @{
            NameSpace = 'root\CCM\CIModels'
            Query     = 'SELECT User from CCM_PrimaryUser'
        }
        #endregion define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
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

            try {
                [ciminstance[]]$PrimaryUsers = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getPrimaryUserSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getPrimaryUserSplat @connectionSplat
                    }
                }
                if ($PrimaryUsers -is [Object] -and $PrimaryUsers.Count -gt 0) {
                    $Result['PrimaryUser'] = $PrimaryUsers.User
                    [PSCustomObject]$Result
                }
                else {
                    Write-Warning "No Primary Users found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMPrimaryUser.ps1' 93
#Region '.\Public\Get-CCMProvisioningMode.ps1' 0
function Get-CCMProvisioningMode {
    <#
        .SYNOPSIS
            Get ConfigMgr client provisioning mode info
        .DESCRIPTION
            This function will allow you to get the configuration manager client provisioning mode info using CIM queries.
            You can provide an array of computer names, or cimsession, or you can pass them through the pipeline.
            It will return a pscustomobject detailing provisioning mode
        .PARAMETER CimSession
            Provides CimSessions to get provisioning mode for
        .PARAMETER ComputerName
            Provides computer names to get provisioning mode for
        .PARAMETER PSSession
            Provides PSSessions to get provisioning mode for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Get-CCMProvisioningMode -Status Enabled
                Retrieves provisioning mode info from the local computer
        .EXAMPLE
            C:\PS> Get-CCMProvisioningMode -ComputerName 'Workstation1234','Workstation4321'
                Retrieves provisioning mode info from Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMProvisioningMode.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-09
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
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
        $getCIMRegistryPropertySplat = @{
            RegRoot  = 'HKEY_LOCAL_MACHINE'
            Key      = 'Software\Microsoft\CCM\CcmExec'
            Property = 'ProvisioningMode', 'ProvisioningEnabledTime', 'ProvisioningMaxMinutes'
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

            $Return = [ordered]@{ }
            $Return['ComputerName'] = $Computer
            try {
                $ProvisioningModeInfo = Get-CCMRegistryProperty @getCIMRegistryPropertySplat @connectionSplat
                if ($ProvisioningModeInfo -is [object]) {
                    $Return['ProvisioningMode'] = $ProvisioningModeInfo.$Computer.ProvisioningMode
                    $EnabledTime = switch ([string]::IsNullOrWhiteSpace($ProvisioningModeInfo.$Computer.ProvisioningEnabledTime)) {
                        $false {
                            [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($ProvisioningModeInfo.$Computer.ProvisioningEnabledTime))
                        }
                    }
                    $Return['ProvisioningEnabledTime'] = $EnabledTime
                    $Return['ProvisioningMaxMinutes'] = $ProvisioningModeInfo.$Computer.ProvisioningMaxMinutes
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
            [pscustomobject]$Return
        }
    }
}
#EndRegion '.\Public\Get-CCMProvisioningMode.ps1' 93
#Region '.\Public\Get-CCMRegistryProperty.ps1' 0
function Get-CCMRegistryProperty {
    <#
        .SYNOPSIS
            Return registry properties using the CIM StdRegProv, or Invoke-CCMCommand
        .DESCRIPTION
            Relies on remote CIM and StdRegProv to allow for returning Registry Properties under a key. If a PSSession, or ConnectionPreference
            is used, then Invoke-CCMCommand is used instead.
        .PARAMETER RegRoot
            The root key you want to search under
            ('HKEY_LOCAL_MACHINE', 'HKEY_USERS', 'HKEY_CURRENT_CONFIG', 'HKEY_DYN_DATA', 'HKEY_CLASSES_ROOT', 'HKEY_CURRENT_USER')
        .PARAMETER Key
            The key you want to return properties of. (ie. SOFTWARE\Microsoft\SMS\Client\Configuration\Client Properties)
        .PARAMETER Property
            The property name(s) you want to return the value of. This is an optional string array [string[]] and if it is not provided, all properties
            under the key will be returned
        .PARAMETER CimSession
            Provides CimSessions to get registry properties from
        .PARAMETER ComputerName
            Provides computer names to get registry properties from
        .PARAMETER PSSession
            Provides PSSessions to get registry properties from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the 
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then 
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to. 
        .EXAMPLE
            PS> Get-CCMRegistryProperty -RegRoot HKEY_LOCAL_MACHINE -Key 'SOFTWARE\Microsoft\SMS\Client\Client Components\Remote Control' -Property "Allow Remote Control of an unattended computer"
            Name                           Value
            ----                           -----
            Computer123                 @{Allow Remote Control of an unattended computer=1}
        .OUTPUTS
            [System.Collections.Hashtable]
        .NOTES
            FileName:    Get-CCMRegistryProperty.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2019-11-07
            Updated:     2020-02-24
#>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CIMRegistryProperty')]
    param (
        [parameter(Mandatory = $true)]
        [ValidateSet('HKEY_LOCAL_MACHINE', 'HKEY_USERS', 'HKEY_CURRENT_CONFIG', 'HKEY_DYN_DATA', 'HKEY_CLASSES_ROOT', 'HKEY_CURRENT_USER')]
        [string]$RegRoot,
        [parameter(Mandatory = $true)]
        [string]$Key,
        [parameter(Mandatory = $false)]
        [string[]]$Property,
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
        #region create hash tables for translating values
        $RootKey = @{
            HKEY_CLASSES_ROOT   = 2147483648
            HKEY_CURRENT_USER   = 2147483649
            HKEY_LOCAL_MACHINE  = 2147483650
            HKEY_USERS          = 2147483651
            HKEY_CURRENT_CONFIG = 2147483653
            HKEY_DYN_DATA       = 2147483654
        }
        <#
            Maps the 'PropType' per property to the method we will invoke to get our return value.
            For example, if the 'type' is 1 (string) we have invoke the GetStringValue method to get our return data
        #>
        $RegPropertyMethod = @{
            1  = 'GetStringValue'
            2  = 'GetExpandedStringValue'
            3  = 'GetBinaryValue'
            4  = 'GetDWORDValue'
            7  = 'GetMultiStringValue'
            11 = 'GetQWORDValue'
        }

        <#
            Maps the 'PropType' per property to the property we will have to expand in our return value.
            For example, if the 'type' is 1 (string) we have to ExpandProperty sValue to get our return data
        #>
        $ReturnValName = @{
            1  = 'sValue'
            2  = 'sValue'
            3  = 'uValue'
            4  = 'uValue'
            7  = 'sValue'
            11 = 'uValue'
        }
        #endregion create hash tables for translating values

        # convert RootKey friendly name to the [uint32] equivalent so it can be used later
        $Root = $RootKey[$RegRoot]

        #region define our hash tables for parameters to pass to Invoke-CimMethod and our return hash table
        $EnumValuesSplat = @{
            Namespace = 'root\default'
            ClassName = 'StdRegProv'
        }
        #endregion define our hash tables for parameters to pass to Invoke-CimMethod and our return hash table
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

            $Return = [ordered]@{ }
            $PerPC_Reg = [ordered]@{ }

            switch -regex ($ConnectionInfo.ConnectionType) {
                '^CimSession$|^ComputerName$' {
                    $EnumValuesSplat['MethodName'] = 'EnumValues'
                    $EnumValuesSplat['Arguments'] = @{
                        hDefKey     = [uint32]$Root
                        sSubKeyName = $Key
                    }
        
                    $EnumValues = Invoke-CimMethod @EnumValuesSplat @connectionSplat
        
                    switch ($PSBoundParameters.ContainsKey('Property')) {
                        $true {
                            $PropertiesToReturn = $Property
                        }
                        $false {
                            $PropertiesToReturn = $EnumValues.sNames
                        }
                    }
        
                    foreach ($PropertyName In $PropertiesToReturn) {
                        $PropIndex = $EnumValues.sNames.IndexOf($PropertyName)
                        switch ($PropIndex) {
                            -1 {
                                Write-Error ([string]::Format('Failed to find [Property = {0}] under [Key = {1}\{2}]', $PropertyName, $RegRoot, $Key))
                            }
                            default {
                                $PropType = $EnumValues.Types[$PropIndex]
                                $Prop = $ReturnValName[$PropType]
                                $Method = $RegPropertyMethod[$PropType]
                                $EnumValuesSplat['MethodName'] = $Method
                                $EnumValuesSplat['Arguments']['sValueName'] = $PropertyName
                                $PropertyValueQuery = Invoke-CimMethod @EnumValuesSplat @connectionSplat
        
                                switch ($PropertyValueQuery.ReturnValue) {
                                    0 {
                                        $PerPC_Reg.$PropertyName = $PropertyValueQuery.$Prop
                                        $Return[$Computer] = $([pscustomobject]$PerPC_Reg)
                                    }
                                    default {
                                        $Return[$Computer] = $null
                                        Write-Error ([string]::Format('Failed to resolve value [Property = {0}] [Key = {1}\{2}]', $PropertyName, $RegRoot, $Key))
                                    }
                                }
                            }
                        }
                    }
        
                }
                '^PSSession$' {
                    $RegPath = [string]::Format('registry::{0}\{1}', $RegRoot, $Key)
                    $PropertyFilter = switch ($PSBoundParameters.ContainsKey('Property')) {
                        $true {
                            [string]::Format("-Name '{0}'", [string]::Join("', '", $Property))
                        }
                        $false {
                            ' '
                        }
                    }
                    $ScriptBlockString = [string]::Format('Get-ItemProperty -Path "{0}" {1}', $RegPath, $PropertyFilter)
                    $ScriptBlock = [scriptblock]::Create($ScriptBlockString)
                    $InvokeCommandSplat = @{
                        ScriptBlock = $ScriptBlock
                    }

                    $RegData = Invoke-CCMCommand @InvokeCommandSplat @connectionSplat
                    switch ($PSBoundParameters.ContainsKey('Property')) {
                        $true {
                            switch ($Property) {
                                default {
                                    $PerPC_Reg.$PSItem = $RegData.$PSItem
                                }
                            }
                            $Return[$Computer] = $([pscustomobject]$PerPC_Reg)
                        }
                        $false {
                            $AllProperties = Get-Member -InputObject $RegData -MemberType NoteProperty

                            switch -regex ($AllProperties.Name) {
                                '^PSChildName$|^PSComputerName$|^PSParentPath$|^PSPath$|^PSProvider$|^PSShowComputerName$|^RunspaceId$' {
                                    continue
                                }
                                default {
                                    $PerPC_Reg.$PSItem = $RegData.$PSItem
                                }
                            }
                            $Return[$Computer] = $([pscustomobject]$PerPC_Reg)
                        }
                    }
                }
            }

            Write-Output $Return
        }
    }
}
#EndRegion '.\Public\Get-CCMRegistryProperty.ps1' 224
#Region '.\Public\Get-CCMServiceWindow.ps1' 0
function Get-CCMServiceWindow {
    <#
        .SYNOPSIS
            Get ConfigMgr Service Window information from computers via CIM
        .DESCRIPTION
            This function will allow you to gather Service Window information from multiple computers using CIM queries. Note that 'ServiceWindows' are object
            that describe the schedule for a maintenance window, such as the recurrence, and date / time information. You can provide an array of computer names,
            or you can pass them through the pipeline. You are also able to specify the Service Window Type (SWType) you wish to query for, and pass credentials.
            What is returned is the data from the 'ActualConfig' section of WMI on the computer. The data returned will include the 'schedules' as well as
            the schedule type. Note that the schedules are not really 'human readable' and can be passed into ConvertFrom-CCMSchedule to convert
            them into a readable object. This is the equivalent of the 'Convert-CMSchedule' cmdlet that is part of the MEMCM PowerShell module, but
            it does not require the module and it is much faster.
        .PARAMETER SWType
            Specifies the types of SW you want information for. Valid options are below
                'All Deployment Service Window',
                'Program Service Window',
                'Reboot Required Service Window',
                'Software Update Service Window',
                'Task Sequences Service Window',
                'Corresponds to non-working hours'
        .PARAMETER CimSession
            Provides CimSessions to gather Service Window information info from
        .PARAMETER ComputerName
            Provides computer names to gather Service Window information info from
        .PARAMETER PSSession
            Provides PSSessions to gather Service Window information info from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Get-CCMSchedule
                Return all the 'All Deployment Service Window', 'Software Update Service Window' Maintenance Windows for the local computer. These are the two default MW types
                that the function looks for
        .EXAMPLE
            C:\PS> Get-CCMSchedule -ComputerName 'Workstation1234','Workstation4321' -SWType 'Software Update Service Window'
                Return all the 'Software Update Service Window' Maintenance Windows for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMSchedule.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2019-12-12
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
        [parameter(Mandatory = $false)]
        [ValidateSet('All Deployment Service Window',
            'Program Service Window',
            'Reboot Required Service Window',
            'Software Update Service Window',
            'Task Sequences Service Window',
            'Corresponds to non-working hours')]
        [Alias('MWType')]
        [string[]]$SWType = @('All Deployment Service Window', 'Software Update Service Window'),
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
        #region Create hashtable for mapping MW types, and create CIM filter based on input params
        $SW_Type = @{
            1	=	'All Deployment Service Window'
            2	=	'Program Service Window'
            3	=	'Reboot Required Service Window'
            4	=	'Software Update Service Window'
            5	=	'Task Sequences Service Window'
            6	=	'Corresponds to non-working hours'
        }

        $RequestedTypesRaw = $SW_Type.Keys.Where( { $SW_Type[$_] -in $SWType } )

        $RequestedTypesFilter = [string]::Format('ServiceWindowType = {0}', [string]::Join(' OR ServiceWindowType =', $RequestedTypesRaw))
        #endregion Create hashtable for mapping MW types, and create CIM filter based on input params
        $getServiceWindowSplat = @{
            Namespace = 'root\CCM\Policy\Machine\ActualConfig'
            ClassName = 'CCM_ServiceWindow'
            Filter    = $RequestedTypesFilter
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

            try {
                [ciminstance[]]$ServiceWindows = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getServiceWindowSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getServiceWindowSplat @connectionSplat
                    }
                }
                if ($ServiceWindows -is [Object] -and $ServiceWindows.Count -gt 0) {
                    foreach ($ServiceWindow in $ServiceWindows) {
                        $Result['Schedules'] = $ServiceWindow.Schedules
                        $Result['ServiceWindowID'] = $ServiceWindow.ServiceWindowID
                        $Result['ServiceWindowType'] = $SW_Type.Item([int]$($ServiceWindow.ServiceWindowType))
                        [PSCustomObject]$Result
                    }
                }
                else {
                    $Result['Schedules'] = $null
                    $Result['ServiceWindowID'] = $null
                    $Result['ServiceWindowType'] = "No ServiceWindow of type(s) $([string]::Join(', ', $RequestedTypesRaw))"
                    [PSCustomObject]$Result
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMServiceWindow.ps1' 140
#Region '.\Public\Get-CCMSite.ps1' 0
function Get-CCMSite {
    <#
        .SYNOPSIS
            Returns the current MEMCM Site set for the MEMCM Client
        .DESCRIPTION
            This function will return the current MEMCM Site for the MEMCM Client. This is done using the Microsoft.SMS.Client COM Object.
        .PARAMETER CimSession
            Provides CimSessions to return the current MEMCM Site for
        .PARAMETER ComputerName
            Provides computer names to return the current MEMCM Site for
        .PARAMETER PSSession
            Provides a PSSession to return the current MEMCM Site for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Get-CCMSite
                Return the local computers MEMCM Site setting
        .EXAMPLE
            C:\PS> Get-CCMSite -ComputerName 'Workstation1234','Workstation4321'
                Return the MEMCM Site setting for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Get-CCMSite.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-18
            Updated:     2020-03-01
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param(
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
        $GetSiteScriptblock = {
            $Client = New-Object -ComObject Microsoft.SMS.Client
            $Client.GetAssignedSite()
        }
        $invokeCommandSplat = @{
            ScriptBlock = $GetSiteScriptblock
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

            $Result['SiteCode'] = switch ($Computer -eq $env:ComputerName) {
                $true {
                    $GetSiteScriptblock.Invoke()
                }
                $false {
                    Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                }
            }
            [pscustomobject]$Result
        }
    }
}
#EndRegion '.\Public\Get-CCMSite.ps1' 84
#Region '.\Public\Get-CCMSoftwareUpdate.ps1' 0
function Get-CCMSoftwareUpdate {
    <#
        .SYNOPSIS
            Get pending MEMCM patches for a machine
        .DESCRIPTION
            Uses CIM to find MEMCM patches that are currently available on a machine.
        .PARAMETER IncludeDefs
            A switch that will determine if you want to include AV Definitions in your query
        .PARAMETER CimSession
            Computer CimSession(s) which you want to get pending MEMCM patches for
        .PARAMETER ComputerName
            Computer name(s) which you want to get pending MEMCM patches for
        .PARAMETER PSSesison
            PSSesisons which you want to get pending MEMCM patches for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            PS C:\> Get-CCMSoftwareUpdate -Computer Testing123
            will return all non-AV Dev patches for computer Testing123
        .NOTES
            FileName:    Get-CCMSoftwareUpdate.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-15
            Updated:     2020-03-09
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CCMUpdate')]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$IncludeDefs,
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
        $EvaluationStateMap = @{
            23 = 'WaitForOrchestration'
            22 = 'WaitPresModeOff'
            21 = 'WaitingRetry'
            20 = 'PendingUpdate'
            19 = 'PendingUserLogoff'
            18 = 'WaitUserReconnect'
            17 = 'WaitJobUserLogon'
            16 = 'WaitUserLogoff'
            15 = 'WaitUserLogon'
            14 = 'WaitServiceWindow'
            13 = 'Error'
            12 = 'InstallComplete'
            11 = 'Verifying'
            10 = 'WaitReboot'
            9  = 'PendingHardReboot'
            8  = 'PendingSoftReboot'
            7  = 'Installing'
            6  = 'WaitInstall'
            5  = 'Downloading'
            4  = 'PreDownload'
            3  = 'Detecting'
            2  = 'Submitted'
            1  = 'Available'
            0  = 'None'
        }

        $ComplianceStateMap = @{
            0 = 'NotPresent'
            1 = 'Present'
            2 = 'PresenceUnknown/NotApplicable'
            3 = 'EvaluationError'
            4 = 'NotEvaluated'
            5 = 'NotUpdated'
            6 = 'NotConfigured'
        }
        #$UpdateStatus.Get_Item("$EvaluationState")
        #endregion status type hashtable

        $Filter = switch ($IncludeDefs) {
            $true {
                "ComplianceState=0"
            }
            Default {
                "NOT (Name LIKE '%Definition%' OR Name Like 'Security Intelligence Update%') and ComplianceState=0"
            }
        }

        $getUpdateSplat = @{
            Filter    = $Filter
            Namespace = 'root\CCM\ClientSDK'
            ClassName = 'CCM_SoftwareUpdate'
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

            try {
                [ciminstance[]]$MissingUpdates = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getUpdateSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getUpdateSplat @connectionSplat
                    }
                }
                if ($MissingUpdates -is [Object] -and $MissingUpdates.Count -gt 0) {
                    foreach ($Update in $MissingUpdates) {
                        $Result['ArticleID'] = $Update.ArticleID
                        $Result['BulletinID'] = $Update.BulletinID
                        $Result['ComplianceState'] = $ComplianceStateMap[[int]$($Update.ComplianceState)]
                        $Result['ContentSize'] = $Update.ContentSize
                        $Result['Deadline'] = $Update.Deadline
                        $Result['Description'] = $Update.Description
                        $Result['ErrorCode'] = $Update.ErrorCode
                        $Result['EvaluationState'] = $EvaluationStateMap[[int]$($Update.EvaluationState)]
                        $Result['ExclusiveUpdate'] = $Update.ExclusiveUpdate
                        $Result['FullName'] = $Update.FullName
                        $Result['IsUpgrade'] = $Update.IsUpgrade
                        $Result['MaxExecutionTime'] = $Update.MaxExecutionTime
                        $Result['Name'] = $Update.Name
                        $Result['NextUserScheduledTime'] = $Update.NextUserScheduledTime
                        $Result['NotifyUser'] = $Update.NotifyUser
                        $Result['OverrideServiceWindows'] = $Update.OverrideServiceWindows
                        $Result['PercentComplete'] = $Update.PercentComplete
                        $Result['Publisher'] = $Update.Publisher
                        $Result['RebootOutsideServiceWindows'] = $Update.RebootOutsideServiceWindows
                        $Result['RestartDeadline'] = $Update.RestartDeadline
                        $Result['StartTime'] = $Update.StartTime
                        $Result['UpdateID'] = $Update.UpdateID
                        $Result['URL'] = $Update.URL
                        $Result['UserUIExperience'] = $Update.UserUIExperience
                        [pscustomobject]$Result
                    }
                }
                else {
                    Write-Verbose "No updates found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMSoftwareUpdate.ps1' 170
#Region '.\Public\Get-CCMSoftwareUpdateGroup.ps1' 0
function Get-CCMSoftwareUpdateGroup {
    <#
        .SYNOPSIS
            Get information for the Software Update Groups deployed to a computer, including compliance
        .DESCRIPTION
            Uses CIM to find information for the Software Update Groups deployed to a computer. This includes checking the currently
            reported 'compliance' for a software update group using the CCM_AssignmentCompliance CIM class
        .PARAMETER AssignmentName
            Provide an array of Software Update Group names to query for
        .PARAMETER AssignmentID
            Provide an array of Software Update Group assignment ID to query for
        .PARAMETER CimSession
            Computer CimSession(s) which you want to get information for the Software Update Groups
        .PARAMETER ComputerName
            Computer name(s) which you want to get information for the Software Update Groups
        .PARAMETER PSSession
            PSSessions which you want to get information for the Software Update Groups
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            PS C:\> Get-CCMSoftwareUpdateGroup -Computer Testing123
                Will return all info available for the Software Update Groups deployed to Testing123
        .NOTES
            FileName:    Get-CCMSoftwareUpdateGroup.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-21
            Updated:     2020-03-17
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    [Alias('Get-CCMSUG')]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$AssignmentName,
        [Parameter(Mandatory = $false)]
        [string[]]$AssignmentID,
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
        $getSUGSplat = @{
            Namespace = 'root\CCM\Policy\Machine\ActualConfig'
        }
        $getSUGComplianceSplat = @{
            Namespace = 'ROOT\ccm\SoftwareUpdates\DeploymentAgent'
        }

        $suppressRebootMap = @{
            0 = 'Not Suppressed'
            1 = 'Workstations Suppressed'
            2 = 'Servers Suppressed'
            3 = 'Workstations and Servers Suppressed'
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

            try {
                $FilterParts = switch ($PSBoundParameters.Keys) {
                    'AssignmentName' {
                        [string]::Format('AssignmentName = "{0}"', [string]::Join('" OR AssignmentName = "', $AssignmentName))
                    }
                    'AssignmentID' {
                        [string]::Format('AssignmentID = "{0}"', [string]::Join('" OR AssignmentID = "', $AssignmentID))
                    }
                }
                $Filter = switch ($null -ne $FilterParts) {
                    $true {
                        [string]::Format(' WHERE {0}', [string]::Join(' OR ', $FilterParts))
                    }
                    $false {
                        ' '
                    }
                }
                $getSUGSplat['Query'] = [string]::Format('SELECT * FROM CCM_UpdateCIAssignment{0}', $Filter)

                [ciminstance[]]$DeployedSUG = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getSUGSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getSUGSplat @connectionSplat
                    }
                }
                if ($DeployedSUG -is [Object] -and $DeployedSUG.Count -gt 0) {
                    foreach ($SUG in $DeployedSUG) {
                        $Result['AssignmentName'] = $SUG.AssignmentName

                        #region Query CCM_AssignmentCompliance to return SUG compliance
                        $getSUGComplianceSplat['Query'] = [string]::Format('SELECT IsCompliant FROM CCM_AssignmentCompliance WHERE AssignmentID = "{0}"', $SUG.AssignmentID)
                        $AssignmentCompliance = switch ($Computer -eq $env:ComputerName) {
                            $true {
                                Get-CimInstance @getSUGComplianceSplat @connectionSplat
                            }
                            $false {
                                Get-CCMCimInstance @getSUGComplianceSplat @connectionSplat
                            }
                        }
                        $Result['AssignmentCompliance'] = $AssignmentCompliance.IsCompliant
                        #endregion Query CCM_AssignmentCompliance to return SUG compliance

                        $Result['StartTime'] = $SUG.StartTime
                        $Result['EnforcementDeadline'] = $SUG.EnforcementDeadline
                        $Result['UseGMTTimes'] = $SUG.UseGMTTimes
                        $Result['NotifyUser'] = $SUG.NotifyUser
                        $Result['OverrideServiceWindows'] = $SUG.OverrideServiceWindows
                        $Result['RebootOutsideOfServiceWindows'] = $SUG.RebootOutsideOfServiceWindows
                        $Result['SuppressReboot'] = $suppressRebootMap[[int]$SUG.SuppressReboot]
                        $Result['UserUIExperience'] = $xml_Reserved1.SUMReserved.UserUIExperience
                        $Result['WoLEnabled'] = $SUG.WoLEnabled
                        # TODO - Determine if AssignmentAction needs figured out
                        $Result['AssignmentAction'] = $SUG.AssignmentAction
                        $Result['AssignmentFlags'] = $SUG.AssignmentFlags
                        $Result['AssignmentID'] = $SUG.AssignmentID
                        $Result['ConfigurationFlags'] = $SUG.ConfigurationFlags
                        $Result['DesiredConfigType'] = $SUG.DesiredConfigType
                        $Result['DisableMomAlerts'] = $SUG.DisableMomAlerts
                        $Result['DPLocality'] = $SUG.DPLocality
                        $Result['ExpirationTime'] = $SUG.ExpirationTime
                        $Result['LogComplianceToWinEvent'] = $SUG.LogComplianceToWinEvent
                        # ENHANCE - Parse NonComplianceCriticality
                        $Result['NonComplianceCriticality'] = $SUG.NonComplianceCriticality
                        $Result['PersistOnWriteFilterDevices'] = $SUG.PersistOnWriteFilterDevices
                        $Result['RaiseMomAlertsOnFailure'] = $SUG.RaiseMomAlertsOnFailure

                        #region store the 'Reserved1' property of the SUG as XML so we can parse the properties
                        [xml]$xml_Reserved1 = $SUG.Reserved1
                        $Result['StateMessageVerbosity'] = $xml_Reserved1.SUMReserved.StateMessageVerbosity
                        $Result['LimitStateMessageVerbosity'] = $xml_Reserved1.SUMReserved.LimitStateMessageVerbosity
                        $Result['UseBranchCache'] = $xml_Reserved1.SUMReserved.UseBranchCache
                        $Result['RequirePostRebootFullScan'] = $xml_Reserved1.SUMReserved.RequirePostRebootFullScan
                        #endregion store the 'Reserved1' property of the SUG as XML so we can parse the properties

                        $Result['SendDetailedNonComplianceStatus'] = $SUG.SendDetailedNonComplianceStatus
                        $Result['SettingTypes'] = $SUG.SettingTypes
                        $Result['SoftDeadlineEnabled'] = $SUG.SoftDeadlineEnabled
                        $Result['StateMessagePriority'] = $SUG.StateMessagePriority
                        $Result['UpdateDeadline'] = $SUG.UpdateDeadline
                        $Result['UseSiteEvaluation'] = $SUG.UseSiteEvaluation
                        $Result['Reserved2'] = $SUG.Reserved2
                        $Result['Reserved3'] = $SUG.Reserved3
                        $Result['Reserved4'] = $SUG.Reserved4
                        #region loop through the AssignedCIs and cast them as XML so they can be easily work with
                        $Result['AssignedCIs'] = foreach ($AssignCI in $SUG.AssignedCIs) {
                            ([xml]$AssignCI).CI
                        }
                        #endregion loop through the AssignedCIs and cast them as XML so they can be easily work with

                        [pscustomobject]$Result
                    }
                }
                else {
                    Write-Verbose "No deployed SUGs found for $Computer"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMSoftwareUpdateGroup.ps1' 191
#Region '.\Public\Get-CCMSoftwareUpdateSettings.ps1' 0
function Get-CCMSoftwareUpdateSettings {
    <#
        .SYNOPSIS
            Get software update settings for a computer
        .DESCRIPTION
            Uses CIM to find software update settings for a computer. This includes various configs
            that are set in the MEMCM Console Client Settings
        .PARAMETER CimSession
            Computer CimSession(s) which you want to get software update settings for
        .PARAMETER ComputerName
            Computer name(s) which you want to get software update settings for
        .PARAMETER PSSession
            PSSessions which you want to get software update settings for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            PS C:\> Get-CCMSoftwareUpdateSettings -Computer Testing123
                Will return all software update settings deployed to Testing123
        .NOTES
            FileName:    Get-CCMSoftwareUpdateSettings.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-29
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param(
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
        $getSoftwareUpdateSettingsSplat = @{
            Namespace = 'root\CCM\Policy\Machine\ActualConfig'
            Query     = 'SELECT * FROM CCM_SoftwareUpdatesClientConfig'
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

            [ciminstance[]]$Settings = switch ($Computer -eq $env:ComputerName) {
                $true {
                    Get-CimInstance @getSoftwareUpdateSettingsSplat @connectionSplat
                }
                $false {
                    Get-CCMCimInstance @getSoftwareUpdateSettingsSplat @connectionSplat
                }
            }
            if ($Settings -is [Object] -and $Settings.Count -gt 0) {
                foreach ($Setting in $Settings) {
                    $Result['ComponentName'] = $Setting.ComponentName
                    $Result['Enabled'] = $Setting.Enabled
                    $Result['WUfBEnabled'] = $Setting.WUfBEnabled
                    $Result['EnableThirdPartyUpdates'] = $Setting.EnableThirdPartyUpdates
                    $Result['EnableExpressUpdates'] = $Setting.EnableExpressUpdates
                    $Result['ServiceWindowManagement'] = $Setting.ServiceWindowManagement
                    $Result['ReminderInterval'] = $Setting.ReminderInterval
                    $Result['DayReminderInterval'] = $Setting.DayReminderInterval
                    $Result['HourReminderInterval'] = $Setting.HourReminderInterval
                    $Result['AssignmentBatchingTimeout'] = $Setting.AssignmentBatchingTimeout
                    $Result['BrandingSubTitle'] = $Setting.BrandingSubTitle
                    $Result['BrandingTitle'] = $Setting.BrandingTitle
                    $Result['ContentDownloadTimeout'] = $Setting.ContentDownloadTimeout
                    $Result['ContentLocationTimeout'] = $Setting.ContentLocationTimeout
                    $Result['DynamicUpdateOption'] = $Setting.DynamicUpdateOption
                    $Result['ExpressUpdatesPort'] = $Setting.ExpressUpdatesPort
                    $Result['ExpressVersion'] = $Setting.ExpressVersion
                    $Result['GroupPolicyNotificationTimeout'] = $Setting.GroupPolicyNotificationTimeout
                    $Result['MaxScanRetryCount'] = $Setting.MaxScanRetryCount
                    $Result['NEOPriorityOption'] = $Setting.NEOPriorityOption
                    $Result['PerDPInactivityTimeout'] = $Setting.PerDPInactivityTimeout
                    $Result['ScanRetryDelay'] = $Setting.ScanRetryDelay
                    $Result['SiteSettingsKey'] = $Setting.SiteSettingsKey
                    $Result['TotalInactivityTimeout'] = $Setting.TotalInactivityTimeout
                    $Result['UserJobPerDPInactivityTimeout'] = $Setting.UserJobPerDPInactivityTimeout
                    $Result['UserJobTotalInactivityTimeout'] = $Setting.UserJobTotalInactivityTimeout
                    $Result['WSUSLocationTimeout'] = $Setting.WSUSLocationTimeout
                    $Result['Reserved1'] = $Setting.Reserved1
                    $Result['Reserved2'] = $Setting.Reserved2
                    $Result['Reserved3'] = $Setting.Reserved3
                    [pscustomobject]$Result
                }
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMSoftwareUpdateSettings.ps1' 114
#Region '.\Public\Get-CCMTaskSequence.ps1' 0
function Get-CCMTaskSequence {
    <#
        .SYNOPSIS
            Return deployed task sequences from a computer
        .DESCRIPTION
            Pulls a list of deployed task sequences from the specified computer(s) or CIMSession(s) with optional filters, and can be passed on
            to Invoke-CCMTaskSequence if desired.

            Note that the parameters for filter are all joined together with OR.
        .PARAMETER PackageID
            An array of PackageID to filter on
        .PARAMETER TaskSequenceName
            An array of task sequence names to filter on
        .PARAMETER CimSession
            Provides CimSession to gather deployed task sequence info from
        .PARAMETER ComputerName
            Provides computer names to gather deployed task sequence info from
        .PARAMETER PSSession
            Provides PSSessions to gather deployed task sequence info from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            PS> Get-CCMTaskSequence
                Returns all deployed task sequences listed in WMI on the local computer
        .EXAMPLE
            PS> Get-CCMTaskSequence -TaskSequenceName 'Windows 10' -PackageID 'TST00443'
                Returns all deployed task sequences listed in WMI on the local computer which have either a task sequence name of 'Windows 10' or
                a PackageID of 'TST00443'
        .NOTES
            FileName:    Get-CCMTaskSequence.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-14
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$PackageID,
        [Parameter(Mandatory = $false)]
        [string[]]$TaskSequenceName,
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
        #region define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
        $getPackageSplat = @{
            NameSpace = 'root\CCM\Policy\Machine\ActualConfig'
        }
        #endregion define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
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

            try {
                $FilterParts = switch ($PSBoundParameters.Keys) {
                    'PackageID' {
                        [string]::Format('PKG_PackageID = "{0}"', [string]::Join('" OR PRG_ProgramName = "', $PackageID))
                    }
                    'TaskSequenceName' {
                        [string]::Format('PKG_Name = "{0}"', [string]::Join('" OR PKG_Name = "', $TaskSequenceName))
                    }
                }
                $Filter = switch ($null -ne $FilterParts) {
                    $true {
                        [string]::Format(' WHERE {0}', [string]::Join(' OR ', $FilterParts))
                    }
                    $false {
                        ' '
                    }
                }
                $getPackageSplat['Query'] = [string]::Format('SELECT * FROM CCM_TaskSequence{0}', $Filter)

                [ciminstance[]]$Packages = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getPackageSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getPackageSplat @connectionSplat
                    }
                }
                if ($Packages -is [Object] -and $Packages.Count -gt 0) {
                    Write-Output -InputObject $Packages
                }
                else {
                    Write-Warning "No deployed task sequences found for $Computer based on input filters"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Get-CCMTaskSequence.ps1' 121
#Region '.\Public\Invoke-CCMApplication.ps1' 0
Function Invoke-CCMApplication {
    <#
        .SYNOPSIS
            Invoke the provided method for an application deployed to a computer
        .DESCRIPTION
            Uses the Install, or Uninstall method of the CCM_Application CIMClass to perform actions on applications.

            Note that you cannot inherently invoke these methods on every single application. It will have to adhere
            to the same logic that any application must follow for installation. This includes meeting application 
            requirements, being 'Applicable' in the sense of trying to 'Install' an application that is not currently
            detected as installed, or trying to 'Uninstall' an application that is currently detected as installed, 
            and it has an Uninstall command. 

            The most surefire way to invoke an application method is to do so as system. Otherwise, you can also do
            the invoking as the current interactive user of the targeted machine. 
        .PARAMETER ID
            An array of ID to invoke
        .PARAMETER IsMachineTarget
            Boolean value that specifies if the application is machine targeted, or user targeted
        .PARAMETER Revision
            The revision of the application that will have an action invoked. This is needed so that MEMCM knows
                what policy it should be working with.
        .PARAMETER Method
            Install, or Uninstall. Keep in mind that you can only perform whatever action is available for an application.
                If it is a required application that does not allow uninstall, then the invoke will not work.
        .PARAMETER EnforcePreference
            When the install should take place. Options are 'Immediate', 'NonBusinessHours', or 'AdminSchedule'

            Defaults to 'Immediate'
        .PARAMETER Priority
            The priority that is passed to the method. Options are 'Foreground', 'High', 'Normal', and 'Low'

            Defaults to 'High'
        .PARAMETER IsRebootIfNeeded
            Boolean that tells MEMCM if it can reboot the computer IF a reboot is required after the method completes based on exit code.
        .PARAMETER CimSession
            Provides CimSession to invoke the application method on
        .PARAMETER ComputerName
            Provides computer names to invoke the application method on
        .PARAMETER PSSession
            Provides PSSessions to invoke the application method on
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            PS> Get-CCMApplication -ApplicationName '7-Zip' | Invoke-CCMApplication -Method Install
                Invokes the install of 7-Zip on the local computer
        .EXAMPLE
            PS> Invoke-CCMApplication -ID ScopeId_BE389CA5-D6CC-42AF-B8F5-A059F9C9AD91/Application_0607d288-fc0b-42b7-9a61-76abedf0673e -Method Uninstall
                Invokes the uninstall of the application with the specified ID
        .NOTES
            FileName:    Invoke-CCMApplication.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-21
            Updated:     2020-03-02
    #>
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
#EndRegion '.\Public\Invoke-CCMApplication.ps1' 167
#Region '.\Public\Invoke-CCMBaseline.ps1' 0
function Invoke-CCMBaseline {
    <#
        .SYNOPSIS
            Invoke MEMCCM Configuration Baselines on the specified computers
        .DESCRIPTION
            This function will allow you to provide an array of computer names, PSSessions, or cimsessions, and configuration baseline names which will be invoked.
            If you do not specify a baseline name, then ALL baselines on the machine will be invoked. A [PSCustomObject] is returned that
            outlines the results, including the last time the baseline was ran, and if the previous run returned compliant or non-compliant.
        .PARAMETER BaselineName
            Provides the configuration baseline names that you wish to invoke.
        .PARAMETER CimSession
            Provides cimsessions to invoke the configuration baselines on.
        .PARAMETER ComputerName
            Provides computer names to invoke the configuration baselines on.
        .PARAMETER PSSession
            Provides PSSessions to invoke the configuration baselines on.
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Invoke-CCMBaseline
                Invoke all baselines identified in WMI on the local computer.
        .EXAMPLE
            C:\PS> Invoke-CCMBaseline -ComputerName 'Workstation1234','Workstation4321' -BaselineName 'Check Computer Compliance','Double Check Computer Compliance'
                Invoke the two baselines on the computers specified. This demonstrates that both ComputerName and BaselineName accept string arrays.
        .EXAMPLE
            C:\PS> Invoke-CCMBaseline -ComputerName 'Workstation1234','Workstation4321'
                Invoke all baselines identified in WMI for the computers specified.
        .NOTES
            FileName:    Invoke-CCMBaseline.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2019-07-24
            Updated:     2020-03-01

            It is important to note that if a configuration baseline has user settings, the only way to invoke it is if the user is logged in, and you run this script
            with those credentials provided to a CimSession. An example would be if Workstation1234 has user Jim1234 logged in, with a configuration baseline 'FixJimsStuff'
            that has user settings,

            This command would successfully invoke FixJimsStuff
            Invoke-CCMBaseline -ComputerName 'Workstation1234' -BaselineName 'FixJimsStuff' -CimSession $CimSessionWithJimsCreds

            This command would not find the baseline FixJimsStuff, and be unable to invoke it
            Invoke-CCMBaseline -ComputerName 'Workstation1234' -BaselineName 'FixJimsStuff'

            You could remotely invoke that baseline AS Jim1234, with either a runas on PowerShell, or providing Jim's credentials to a cimsesion passed to -cimsession param.
            If you try to invoke this same baseline without Jim's credentials being used in some way you will see that the baseline is not found.

            Outside of that, it will dynamically generate the arguments to pass to the TriggerEvaluation method. I found a handful of examples on the internet for
            invoking MEMCM Configuration Baselines, and there were always comments about certain scenarios not working. This implementation has been consistent in
            invoking Configuration Baselines, including those with user settings, as long as the context is correct.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string[]]$BaselineName = 'NotSpecified',
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
        #region Setup our *-CIM* parameters that will apply to the CIM cmdlets in use based on input parameters
        $getBaselineSplat = @{
            Namespace   = 'root\ccm\dcm'
            ErrorAction = 'Stop'
        }
        $invokeBaselineEvalSplat = @{
            Namespace   = 'root\ccm\dcm'
            ClassName   = 'SMS_DesiredConfiguration'
            ErrorAction = 'Stop'
            Name        = 'TriggerEvaluation'
        }
        #endregion Setup our common *-CIM* parameters that will apply to the CIM cmdlets in use based on input parameters

        #region hash table for translating compliance status
        $LastComplianceStatus = @{
            0 = 'Non-Compliant'
            1 = 'Compliant'
            2 = 'Compliance State Unknown'
            4 = 'Error'
        }
        #endregion hash table for translating compliance status

        <#
            Not all Properties are on all Configuration Baseline instances, this is the list of possible options
            We will identify which properties exist, and pass the respective arguments to Invoke-CimMethod with typecasting
        #>
        $PropertyOptions = 'IsEnforced', 'IsMachineTarget', 'Name', 'PolicyType', 'Version'
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

            foreach ($BLName in $BaselineName) {
                #region Query CIM for Configuration Baselines based off DisplayName
                $BLQuery = switch ($PSBoundParameters.ContainsKey('BaselineName')) {
                    $true {
                        [string]::Format("SELECT * FROM SMS_DesiredConfiguration WHERE DisplayName = '{0}'", $BLName)
                    }
                    $false {
                        "SELECT * FROM SMS_DesiredConfiguration"
                    }
                }
                Write-Verbose "Checking for Configuration Baselines on [ComputerName='$Computer'] with [Query=`"$BLQuery`"]"
                $getBaselineSplat['Query'] = $BLQuery
                try {
                    $Baselines = switch -regex ($ConnectionInfo.ConnectionType) {
                        '^ComputerName$|^CimSession$' {
                            Get-CimInstance @getBaselineSplat @connectionSplat
                        }
                        'PSSession' {
                            Get-CCMCimInstance @getBaselineSplat @connectionSplat
                        }
                    }
                }
                catch {
                    # need to improve this - should catch access denied vs RPC, and need to do this on ALL CIM related queries across the module.
                    # Maybe write a function???
                    Write-Error "Failed to query for baselines on $Computer - $_"
                }
                #endregion Query CIM for Configuration Baselines based off DisplayName

                #region Based on results of CIM Query, identify arguments and invoke TriggerEvaluation
                switch ($null -eq $Baselines) {
                    $false {
                        foreach ($BL in $Baselines) {
                            if ($PSCmdlet.ShouldProcess($BL.DisplayName, "Invoke Evaluation")) {
                                $Return = [ordered]@{ }
                                $Return['ComputerName'] = $Computer
                                $Return['BaselineName'] = $BL.DisplayName
                                $Return['Version'] = $BL.Version
                                $Return['LastComplianceStatus'] = $LastComplianceStatus[[int]$BL.LastComplianceStatus]
                                $Return['LastEvalTime'] = $BL.LastEvalTime

                                #region generate a property list of existing arguments to pass to the TriggerEvaluation method. Type is important!
                                $ArgumentList = @{ }
                                foreach ($Property in $PropertyOptions) {
                                    $PropExist = Get-Member -InputObject $BL -MemberType Properties -Name $Property
                                    switch ($PropExist) {
                                        $null {
                                            continue
                                        }
                                        default {
                                            $TypeString = ($PropExist.Definition.Split(' '))[0]
                                            $Type = [scriptblock]::Create("[$TypeString]")
                                            $ArgumentList[$Property] = $BL.$Property -as (. $Type)
                                        }
                                    }
                                }
                                $invokeBaselineEvalSplat['Arguments'] = $ArgumentList
                                #endregion generate a property list of existing arguments to pass to the TriggerEvaluation method. Type is important!

                                #region Trigger the Configuration Baseline to run
                                Write-Verbose "Identified the Configuration Baseline [BaselineName='$($BL.DisplayName)'] on [ComputerName='$Computer'] will trigger via the 'TriggerEvaluation' CIM method"
                                $Return['Invoked'] = try {
                                    $Invocation = switch -regex ($ConnectionInfo.ConnectionType) {
                                        '^ComputerName$|^CimSession$' {
                                            Invoke-CimMethod @invokeBaselineEvalSplat @connectionSplat
                                        }
                                        'PSSession' {
                                            $InvokeCCMCommandSplat = @{
                                                Arguments   = $invokeBaselineEvalSplat
                                                ScriptBlock = {
                                                    param(
                                                        $invokeBaselineEvalSplat
                                                    )
                                                    Invoke-CimMethod @invokeBaselineEvalSplat
                                                }
                                            }
                                            Invoke-CCMCommand @InvokeCCMCommandSplat @connectionSplat

                                        }
                                    }
                                    switch ($Invocation.ReturnValue) {
                                        0 {
                                            $true
                                        }
                                        default {
                                            $false
                                        }
                                    }
                                }
                                catch {
                                    $false
                                }

                                [pscustomobject]$Return
                                #endregion Trigger the Configuration Baseline to run
                            }
                        }
                    }
                    $true {
                        Write-Warning "Failed to identify any Configuration Baselines on [ComputerName='$Computer'] with [Query=`"$BLQuery`"]"
                    }
                }
                #endregion Based on results of CIM Query, identify arguments and invoke TriggerEvaluation
            }
        }
    }
}
#EndRegion '.\Public\Invoke-CCMBaseline.ps1' 223
#Region '.\Public\Invoke-CCMClientAction.ps1' 0
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
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
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
#EndRegion '.\Public\Invoke-CCMClientAction.ps1' 179
#Region '.\Public\Invoke-CCMCommand.ps1' 0
function Invoke-CCMCommand {
	<#
		.SYNOPSIS
			Invoke commands remotely via Invoke-Command, allowing arguments and functions to be passed
		.DESCRIPTION
			This function is used as part of the PSCCMClient Module. It's purpose is to allow commands
			to be execute remotely, while also automatically determining the best, or preferred method
			of invoking the command. Based on the type of connection that is passed, whether a CimSession,
			PSSession, or Computername with a ConnectionPreference, the command will be executed remotely
			by either using the CreateProcess Method of the Win32_Process CIM Class, or it will use
			Invoke-Command.
		.PARAMETER ScriptBlock
			The ScriptBlock that should be executed remotely
		.PARAMETER FunctionsToLoad
			A list of functions to load into the remote command exeuction. For example, you could specify that you want 
			to load "Get-CustomThing" into the remote command, as you've already written the function and want to use
			it as part of the scriptblock that will be remotely executed.
		.PARAMETER ArgumentList
			The list of arguments that will be pass into the script block
        .PARAMETER ComputerName
            Provides computer names to invoke the specified scriptblock on
        .PARAMETER PSSession
            Provides PSSessions to invoke the specified scriptblock on
		.EXAMPLE
			C:\PS> Invoke-CCMCommand -ScriptBlock { 'Testing This' } -ComputerName Workstation123
				Would return the string 'Testing This' which was executed on the remote machine Workstation123
		.EXAMPLE
			C:\PS> function Test-This {
				'Testing This'
			}
			Invoke-CCMCommand -Scriptblock { Test-This } -FunctionsToLoad Test-This -ComputerName Workstation123
				Would load the custom Test-This function into the scriptblock, and execute it. This would return the 'Testing This'
				string, based on the function being executed remotely on Workstation123.
		.NOTES
			FileName:    Invoke-CCMCommand.ps1
			Author:      Cody Mathis
			Contact:     @CodyMathis123
			Created:     2020-02-12
			Updated:     2020-08-01
	#>
	[CmdletBinding(DefaultParameterSetName = 'ComputerName')]
	param
	(
		[Parameter(Mandatory = $true)]
		[scriptblock]$ScriptBlock,
		[Parameter(Mandatory = $false)]
		[string[]]$FunctionsToLoad,
		[Parameter(Mandatory = $false)]
		[object[]]$ArgumentList,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
		[Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
		[string[]]$ComputerName = $env:ComputerName,
		[Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
		[Alias('Session')]
		[System.Management.Automation.Runspaces.PSSession[]]$PSSession
	)
	begin {
		$HelperFunctions = switch ($PSBoundParameters.ContainsKey('FunctionsToLoad')) {
			$true {
				Convert-FunctionToString -FunctionToConvert $FunctionsToLoad
			}
		}
		$ScriptBlockString = [string]::Format(@'
				{0}

				{1}
'@ , $HelperFunctions, $ScriptBlock)
		$FullScriptBlock = [scriptblock]::Create($ScriptBlockString)

		$InvokeCommandSplat = @{
			ScriptBlock = $FullScriptBlock
		}
		switch ($PSBoundParameters.ContainsKey('ArgumentList')) {
			$true {
				$invokeCommandSplat['ArgumentList'] = $ArgumentList
			}
		}
	}
	process {
		foreach ($Connection in (Get-Variable -Name $PSCmdlet.ParameterSetName -ValueOnly -Scope Local)) {
			$getConnectionInfoSplat = @{
				$PSCmdlet.ParameterSetName = $Connection
			}
			$ConnectionInfo = Get-CCMConnection @getConnectionInfoSplat -Prefer PSSession
			$connectionSplat = $ConnectionInfo.connectionSplat

			Invoke-Command @InvokeCommandSplat @connectionSplat
		}
	}
}
#EndRegion '.\Public\Invoke-CCMCommand.ps1' 90
#Region '.\Public\Invoke-CCMPackage.ps1' 0
function Invoke-CCMPackage {
    <#
        .SYNOPSIS
            Invoke deployed packages on a computer
        .DESCRIPTION
            This function can invoke a package that is deployed to a computer. It has an optional 'Force' parameter which will
            temporarily change the RepeatRunBehavioar, and MandatoryAssignments parameters to force a pacakge to run regardless
            of the schedule and settings assigned to it.

            Note that the parameters for filter are all joined together with OR.
        .PARAMETER PackageID
            An array of PackageID to filter on
        .PARAMETER PackageName
            An array of package names to filter on
        .PARAMETER ProgramName
            An array of program names to filter on
        .PARAMETER Force
            Force the package to run by temporarily changing the RepeatRunBehavioar, and MandatoryAssignments parameters as shown below

                Property = @{
                    ADV_RepeatRunBehavior    = 'RerunAlways'
                    ADV_MandatoryAssignments = $true
                }
        .PARAMETER CimSession
            Provides CimSession to gather deployed package info from
        .PARAMETER ComputerName
            Provides computer names to gather deployed package info from
        .PARAMETER PSSession
            Provides PSSessions to gather deployed package info from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            PS> Invoke-CCMPackage
                Invoke all packages listed in WMI on the local computer
        .EXAMPLE
            PS> Invoke-CCMPackage -PackageName 'Software Install' -ProgramName 'Software Install - Silent'
                Invoke the deployed packages listed in WMI on the local computer which has either a package name of 'Software Install' or
                a Program Name of 'Software Install - Silent'
        .NOTES
            FileName:    Invoke-CCMPackage.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-12
            Updated:     2020-02-27
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('PKG_PackageID')]
        [string[]]$PackageID,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('PKG_Name')]
        [string[]]$PackageName,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('PRG_ProgramName')]
        [string[]]$ProgramName,
        [Parameter(Mandatory = $false)]
        [switch]$Force,
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
    Begin {
        $setAlwaysRerunSplat = @{
            Property = @{
                ADV_RepeatRunBehavior    = 'RerunAlways'
                ADV_MandatoryAssignments = $true
            }
        }

        #region define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
        $getPackageSplat = @{
            NameSpace = 'root\CCM\Policy\Machine\ActualConfig'
        }
        #endregion define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
    }
    process {
        # temp fix for when PSComputerName from pipeline is empty - we assume it is $env:ComputerName
        switch ($PSCmdlet.ParameterSetName) {
            'ComputerName' {
                switch ([string]::IsNullOrWhiteSpace($ComputerName)) {
                    $true {
                        $ComputerName = $env:ComputerName
                    }
                }
            }
        }
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

            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer']", "Invoke-CCMPackage")) {
                try {
                    $FilterParts = switch ($PSBoundParameters.Keys) {
                        'PackageID' {
                            [string]::Format('PKG_PackageID = "{0}"', [string]::Join('" OR PRG_ProgramName = "', $PackageID))
                        }
                        'PackageName' {
                            [string]::Format('PKG_Name = "{0}"', [string]::Join('" OR PKG_Name = "', $PackageName))
                        }
                        'ProgramName' {
                            [string]::Format('PRG_ProgramName = "{0}"', [string]::Join('" OR PRG_ProgramName = "', $ProgramName))
                        }
                    }
                    $Filter = switch ($null -ne $FilterParts) {
                        $true {
                            [string]::Format(' WHERE {0}', [string]::Join(' OR ', $FilterParts))
                        }
                        $false {
                            ' '
                        }
                    }
                    $getPackageSplat['Query'] = [string]::Format('SELECT * FROM CCM_SoftwareDistribution{0}', $Filter)

                    [ciminstance[]]$Packages = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Get-CimInstance @getPackageSplat @connectionSplat
                        }
                        $false {
                            Get-CCMCimInstance @getPackageSplat @connectionSplat
                        }
                    }
                    if ($Packages -is [Object] -and $Packages.Count -gt 0) {
                        foreach ($Advertisement in $Packages) {
                            switch ($Force.IsPresent) {
                                $true {
                                    Write-Verbose "Force parameter present - Setting package to always rerun"
                                    $setAlwaysRerunSplat['InputObject'] = $Advertisement
                                    switch -regex ($ConnectionInfo.ConnectionType) {
                                        '^ComputerName$|^CimSession$' {
                                            Set-CimInstance @setAlwaysRerunSplat @connectionSplat
                                        }
                                        'PSSession' {
                                            $invokeCommandSplat = @{
                                                ScriptBlock  = {
                                                    param (
                                                        $setAlwaysRerunSplat
                                                    )
                                                    Set-CimInstance @setAlwaysRerunSplat
                                                }
                                                ArgumentList = $setAlwaysRerunSplat
                                            }
                                            Invoke-Command @invokeCommandSplat @connectionSplat
                                        }
                                    }
                                }
                            }
                            $getPackageSplat['Query'] = [string]::Format("SELECT ScheduledMessageID FROM CCM_Scheduler_ScheduledMessage WHERE ScheduledMessageID LIKE '{0}%'", $Advertisement.ADV_AdvertisementID)
                            $ScheduledMessageID = switch ($Computer -eq $env:ComputerName) {
                                $true {
                                    Get-CimInstance @getPackageSplat @connectionSplat
                                }
                                $false {
                                    Get-CCMCimInstance @getPackageSplat @connectionSplat
                                }
                            }
                            if ($null -ne $ScheduledMessageID) {
                                Invoke-CCMTriggerSchedule -ScheduleID $ScheduledMessageID.ScheduledMessageID @connectionSplat
                            }
                            else {
                                Write-Warning "No ScheduledMessageID found for $Computer based on input filters"
                            }
                        }
                    }
                    else {
                        Write-Warning "No deployed package found for $Computer based on input filters"
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
#EndRegion '.\Public\Invoke-CCMPackage.ps1' 202
#Region '.\Public\Invoke-CCMResetPolicy.ps1' 0
function Invoke-CCMResetPolicy {
    <#
        .SYNOPSIS
            Invokes a ResetPolicy for the MEMCM client
        .DESCRIPTION
            This function will force a complete policy reset on a client for multiple computers using CIM queries.
            You can provide an array of computer names, or cimsessions, or you can pass them through the pipeline.
        .PARAMETER ResetType
            Determins the policy reset type.

            'Purge' will wipe all policy from the machine, forcing a complete redownload, and rebuilt.

            'ForceFull' will simply force the next policy refresh to be a full instead of a delta.

            https://docs.microsoft.com/en-us/previous-versions/system-center/developer/cc143785%28v%3dmsdn.10%29
        .PARAMETER CimSession
            Provides CimSession to perform a policy reset on
        .PARAMETER ComputerName
            Provides computer names to perform a policy reset on
        .PARAMETER PSSession
            Provides PSSession to perform a policy reset on
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Invoke-CCMResetPolicy
                Reset the policy on the local machine and restarts CCMExec
        .NOTES
            FileName:    Invoke-CCMResetPolicy.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2019-10-30
            Updated:     2020-03-02
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Purge', 'ForceFull')]
        [string]$ResetType = 'Purge',
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
        $uFlags = switch ($ResetType) {
            'Purge' {
                1
            }
            'ForceFull' {
                0
            }
        }
        $policyResetSplat = @{
            MethodName = 'ResetPolicy'
            Namespace  = 'root\ccm'
            ClassName  = 'sms_client'
            Arguments  = @{
                uFlags = [uint32]$uFlags
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
            $Result['PolicyReset'] = $false
            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [ResetType = '$ResetType']", "Reset CCM Policy")) {
                try {
                    $Invocation = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Invoke-CimMethod @policyResetSplat
                        }
                        $false {
                            $invokeCommandSplat = @{
                                ArgumentList = $policyResetSplat
                                ScriptBlock  = {
                                    param($policyResetSplat)
                                    Invoke-CimMethod @policyResetSplat
                                }
                            }
                            Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                        }
                    }
                    if ($Invocation) {
                        Write-Verbose "Successfully invoked policy reset on $Computer via the 'ResetPolicy' CIM method"
                        $Result['PolicyReset'] = $true
                    }
                    [pscustomobject]$Result
                }
                catch {
                    $ErrorMessage = $_.Exception.Message
                    Write-Error $ErrorMessage
                }
            }
        }
    }
}
#EndRegion '.\Public\Invoke-CCMResetPolicy.ps1' 122
#Region '.\Public\Invoke-CCMSoftwareUpdate.ps1' 0
function Invoke-CCMSoftwareUpdate {
    <#
        .SYNOPSIS
            Invokes updates deployed via Configuration Manager on a client
        .DESCRIPTION
            This script will allow you to invoke updates a machine (with optional credentials). It uses remote CIM to find updates
            based on your input, or you can optionally provide updates via the $Updates parameter, which support pipeline from
            Get-CCMSoftwareUpdate.

            Unfortunately, invoke MEMCM updates remotely via CIM does NOT seem to work. As an alternative, Invoke-CIMPowerShell is used to
            execute the command 'locally' on the remote machine.
        .PARAMETER Updates
            [ciminstance[]] object that contains MEMCM Updates from CCM_SoftwareUpdate class. Supports pipeline input for CIM object collected from Get-CCMSoftwareUpdate
        .PARAMETER CimSession
            Computer CimSession(s) which you want to get invoke MEMCM patches for
        .PARAMETER ComputerName
            Computer name(s) which you want to get invoke MEMCM patches for
        .PARAMETER PSSession
            PSSession(s) which you want to get invoke MEMCM patches for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Invoke-CCMSoftwareUpdate
                Invokes all updates on the local machine
        .EXAMPLE
            C:\PS> Invoke-CCMSoftwareUpdate -ComputerName TestingPC1
                Invokes all updates on the the remote computer TestingPC1
        .NOTES
            FileName:    Invoke-CCMSoftwareUpdate.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2018-12-22
            Updated:     2020-03-02
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ComputerName')]
    [Alias('Invoke-CCMUpdate')]
    param(
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ArticleID,
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
        $invokeCIMMethodSplat = @{
            Namespace  = 'root\ccm\clientsdk'
            MethodName = 'InstallUpdates'
            ClassName  = 'CCM_SoftwareUpdatesManager'
        }
        $getUpdateSplat = @{
            Namespace = 'root\CCM\ClientSDK'
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
            $Result['Invoked'] = $false

            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer']", "Invoke-CCMUpdate")) {
                try {
                    $getUpdateSplat['Query'] = switch ($PSBoundParameters.ContainsKey('ArticleID')) {
                        $true {
                            [string]::Format('SELECT * FROM CCM_SoftwareUpdate WHERE ComplianceState = 0 AND (ArticleID = "{0}")', [string]::Join('" OR ArticleID = "', $ArticleID))
                        }
                        $false {
                            [string]::Format('SELECT * FROM CCM_SoftwareUpdate WHERE ComplianceState = 0')
                        }
                    }

                    [ciminstance[]]$MissingUpdates = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Get-CimInstance @getUpdateSplat @connectionSplat
                        }
                        $false {
                            Get-CCMCimInstance @getUpdateSplat @connectionSplat
                        }
                    }

                    if ($MissingUpdates -is [ciminstance[]]) {
                        switch ($PSBoundParameters.ContainsKey('ArticleID')) {
                            $false {
                                $ArticleID = $MissingUpdates.ArticleID
                            }
                        }
                        $invokeCIMMethodSplat['Arguments'] = @{
                            CCMUpdates = [ciminstance[]]$MissingUpdates
                        }
                    }
                    else {
                        Write-Warning "$Computer has no updates available to invoke"
                    }
                    $Invocation = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Invoke-CimMethod @invokeCIMMethodSplat
                        }
                        $false {
                            $invokeCommandSplat = @{
                                ScriptBlock  = {
                                    param($invokeCIMMethodSplat)
                                    Invoke-CimMethod @invokeCIMMethodSplat
                                }
                                ArgumentList = $invokeCIMMethodSplat
                            }
                            Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                        }
                    }
                    if ($Invocation) {
                        Write-Verbose "Successfully invoked updates on $Computer via the 'InstallUpdates' CIM method"
                        $Result['Invoked'] = $true
                    }

                }
                catch {
                    $ErrorMessage = $_.Exception.Message
                    Write-Error $ErrorMessage
                }
                [pscustomobject]$Result
            }
        }
    }
}
#EndRegion '.\Public\Invoke-CCMSoftwareUpdate.ps1' 148
#Region '.\Public\Invoke-CCMTaskSequence.ps1' 0
function Invoke-CCMTaskSequence {
    <#
        .SYNOPSIS
            Invoke deployed task sequence on a computer
        .DESCRIPTION
            This function can invoke a task sequence that is deployed to a computer. It has an optional 'Force' parameter which will
            temporarily change the RepeatRunBehavioar, and MandatoryAssignments parameters to force a task sequence to run regardless
            of the schedule and settings assigned to it.

            Note that the parameters for filter are all joined together with OR.
        .PARAMETER PackageID
            An array of PackageID to filter on
        .PARAMETER TaskSequenceName
            An array of task sequence names to filter on
        .PARAMETER Force
            Force the task sequence to run by temporarily changing the RepeatRunBehavioar, and MandatoryAssignments parameters as shown below

                Property = @{
                    ADV_RepeatRunBehavior    = 'RerunAlways'
                    ADV_MandatoryAssignments = $true
                }
        .PARAMETER CimSession
            Provides CimSession to invoke the task sequence on
        .PARAMETER ComputerName
            Provides computer names to invoke the task sequence on
        .PARAMETER PSSession
            Provides PSSessions to invoke the task sequence on
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            PS> Invoke-CCMTaskSequence
                Invoke all task sequence listed in WMI on the local computer
        .EXAMPLE
            PS> Invoke-CCMTaskSequence -TaskSequenceName 'Windows 10' -PackageID 'TST00443'
                Invoke the deployed task sequence listed in WMI on the local computer which have either a task sequence name of 'Windows 10' or
                a PackageID of 'TST00443'
        .NOTES
            FileName:    Invoke-CCMTaskSequence.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-15
            Updated:     2020-02-27
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('PKG_PackageID')]
        [string[]]$PackageID,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias('PKG_Name')]
        [string[]]$TaskSequenceName,
        [Parameter(Mandatory = $false)]
        [switch]$Force,
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
    Begin {
        $setAlwaysRerunSplat = @{
            Property = @{
                ADV_RepeatRunBehavior    = 'RerunAlways'
                ADV_MandatoryAssignments = $true
            }
        }

        #region define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
        $getTaskSequenceSplat = @{
            NameSpace = 'root\CCM\Policy\Machine\ActualConfig'
        }
        #endregion define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
    }
    process {
        # temp fix for when PSComputerName from pipeline is empty - we assume it is $env:ComputerName
        switch ($PSCmdlet.ParameterSetName) {
            'ComputerName' {
                switch ([string]::IsNullOrWhiteSpace($ComputerName)) {
                    $true {
                        $ComputerName = $env:ComputerName
                    }
                }
            }
        }
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

            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer']", "Invoke-CCMTaskSequence")) {
                try {
                    $FilterParts = switch ($PSBoundParameters.Keys) {
                        'PackageID' {
                            [string]::Format('PKG_PackageID = "{0}"', [string]::Join('" OR PRG_ProgramName = "', $PackageID))
                        }
                        'TaskSequenceName' {
                            [string]::Format('PKG_Name = "{0}"', [string]::Join('" OR PKG_Name = "', $TaskSequenceName))
                        }
                    }
                    $Filter = switch ($null -ne $FilterParts) {
                        $true {
                            [string]::Format(' WHERE {0}', [string]::Join(' OR ', $FilterParts))
                        }
                        $false {
                            ' '
                        }
                    }
                    $getTaskSequenceSplat['Query'] = [string]::Format('SELECT * FROM CCM_TaskSequence{0}', $Filter)

                    [ciminstance[]]$TaskSequences = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Get-CimInstance @getTaskSequenceSplat @connectionSplat
                        }
                        $false {
                            Get-CCMCimInstance @getTaskSequenceSplat @connectionSplat
                        }
                    }
                    if ($TaskSequences -is [Object] -and $TaskSequences.Count -gt 0) {
                        foreach ($Advertisement in $TaskSequences) {
                            switch ($Force.IsPresent) {
                                $true {
                                    Write-Verbose "Force parameter present - Setting package to always rerun"
                                    $setAlwaysRerunSplat['InputObject'] = $Advertisement
                                    switch -regex ($ConnectionInfo.ConnectionType) {
                                        '^ComputerName$|^CimSession$' {
                                            Set-CimInstance @setAlwaysRerunSplat @connectionSplat
                                        }
                                        'PSSession' {
                                            $invokeCommandSplat = @{
                                                ScriptBlock  = {
                                                    param (
                                                        $setAlwaysRerunSplat
                                                    )
                                                    Set-CimInstance @setAlwaysRerunSplat
                                                }
                                                ArgumentList = $setAlwaysRerunSplat
                                            }
                                            Invoke-Command @invokeCommandSplat @connectionSplat
                                        }
                                    }
                                }
                            }
                            $getTaskSequenceSplat['Query'] = [string]::Format("SELECT ScheduledMessageID FROM CCM_Scheduler_ScheduledMessage WHERE ScheduledMessageID LIKE '{0}%'", $Advertisement.ADV_AdvertisementID)
                            $ScheduledMessageID = switch ($Computer -eq $env:ComputerName) {
                                $true {
                                    Get-CimInstance @getTaskSequenceSplat @connectionSplat
                                }
                                $false {
                                    Get-CCMCimInstance @getTaskSequenceSplat @connectionSplat
                                }
                            }
                            if ($null -ne $ScheduledMessageID) {
                                Invoke-CCMTriggerSchedule -ScheduleID $ScheduledMessageID.ScheduledMessageID @connectionSplat
                            }
                            else {
                                Write-Warning "No ScheduledMessageID found for $Computer based on input filters"
                            }
                        }
                    }
                    else {
                        Write-Warning "No deployed task sequences found for $Computer based on input filters"
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
#EndRegion '.\Public\Invoke-CCMTaskSequence.ps1' 194
#Region '.\Public\Invoke-CCMTriggerSchedule.ps1' 0
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
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
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
            Updated:     2020-03-02
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
#EndRegion '.\Public\Invoke-CCMTriggerSchedule.ps1' 121
#Region '.\Public\New-CCMConnection.ps1' 0
# TODO - Write Function
# TODO - Support 
# TODO - Create both a CimSession and a PSSession so that we can seamlessly move between functions that support one or the other
#EndRegion '.\Public\New-CCMConnection.ps1' 3
#Region '.\Public\New-LoopAction.ps1' 0
function New-LoopAction {
    <#
    .SYNOPSIS
        Function to loop a specified scriptblock until certain conditions are met
    .DESCRIPTION
        This function is a wrapper for a ForLoop or a DoUntil loop. This allows you to specify if you want to exit based on a timeout, or a number of iterations.
            Additionally, you can specify an optional delay between loops, and the type of dealy (Minutes, Seconds). If needed, you can also perform an action based on
            whether the 'Exit Condition' was met or not. This is the IfTimeoutScript and IfSucceedScript. 
    .PARAMETER LoopTimeout
        A time interval integer which the loop should timeout after. This is for a DoUntil loop.
    .PARAMETER LoopTimeoutType
         Provides the time increment type for the LoopTimeout, defaulting to Seconds. ('Seconds', 'Minutes', 'Hours', 'Days')
    .PARAMETER LoopDelay
        An optional delay that will occur between each loop.
    .PARAMETER LoopDelayType
        Provides the time increment type for the LoopDelay between loops, defaulting to Seconds. ('Milliseconds', 'Seconds', 'Minutes')
    .PARAMETER Iterations
        Implies that a ForLoop is wanted. This will provide the maximum number of Iterations for the loop. [i.e. "for ($i = 0; $i -lt $Iterations; $i++)..."]
    .PARAMETER ScriptBlock
        A script block that will run inside the loop. Recommend encapsulating inside { } or providing a [scriptblock]
    .PARAMETER ExitCondition
        A script block that will act as the exit condition for the do-until loop. Will be evaluated each loop. Recommend encapsulating inside { } or providing a [scriptblock]
    .PARAMETER IfTimeoutScript
        A script block that will act as the script to run if the timeout occurs. Recommend encapsulating inside { } or providing a [scriptblock]
    .PARAMETER IfSucceedScript
        A script block that will act as the script to run if the exit condition is met. Recommend encapsulating inside { } or providing a [scriptblock]
    .EXAMPLE
        C:\PS> $newLoopActionSplat = @{
                    LoopTimeoutType = 'Seconds'
                    ScriptBlock = { 'Bacon' }
                    ExitCondition = { 'Bacon' -Eq 'eggs' }
                    IfTimeoutScript = { 'Breakfast'}
                    LoopDelayType = 'Seconds'
                    LoopDelay = 1
                    LoopTimeout = 10
                }
                New-LoopAction @newLoopActionSplat
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Bacon
                Breakfast
    .EXAMPLE
        C:\PS> $newLoopActionSplat = @{
                    ScriptBlock = { if($Test -eq $null){$Test = 0};$TEST++ }
                    ExitCondition = { $Test -eq 4 }
                    IfTimeoutScript = { 'Breakfast' }
                    IfSucceedScript = { 'Dinner'}
                    Iterations  = 5
                    LoopDelay = 1
                }
                New-LoopAction @newLoopActionSplat
                Dinner
        C:\PS> $newLoopActionSplat = @{
                    ScriptBlock = { if($Test -eq $null){$Test = 0};$TEST++ }
                    ExitCondition = { $Test -eq 6 }
                    IfTimeoutScript = { 'Breakfast' }
                    IfSucceedScript = { 'Dinner'}
                    Iterations  = 5
                    LoopDelay = 1
                }
                New-LoopAction @newLoopActionSplat
                Breakfast
.NOTES
        Play with the conditions a bit. I've tried to provide some examples that demonstrate how the loops, timeouts, and scripts work!
#>
    param
    (
        [parameter(Mandatory = $true, ParameterSetName = 'DoUntil')]
        [int32]$LoopTimeout,
        [parameter(Mandatory = $true, ParameterSetName = 'DoUntil')]
        [ValidateSet('Seconds', 'Minutes', 'Hours', 'Days')]
        [string]$LoopTimeoutType,
        [parameter(Mandatory = $true)]
        [int32]$LoopDelay,
        [parameter(Mandatory = $false, ParameterSetName = 'DoUntil')]
        [ValidateSet('Milliseconds', 'Seconds', 'Minutes')]
        [string]$LoopDelayType = 'Seconds',
        [parameter(Mandatory = $true, ParameterSetName = 'ForLoop')]
        [int32]$Iterations,
        [parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        [parameter(Mandatory = $true, ParameterSetName = 'DoUntil')]
        [parameter(Mandatory = $false, ParameterSetName = 'ForLoop')]
        [scriptblock]$ExitCondition,
        [parameter(Mandatory = $false)]
        [scriptblock]$IfTimeoutScript,
        [parameter(Mandatory = $false)]
        [scriptblock]$IfSucceedScript
    )
    begin {
        switch ($PSCmdlet.ParameterSetName) {
            'DoUntil' {
                $paramNewTimeSpan = @{
                    $LoopTimeoutType = $LoopTimeout
                }    
                $TimeSpan = New-TimeSpan @paramNewTimeSpan
                $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
                $FirstRunDone = $false        
            }
        }
    }
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'DoUntil' {
                do {
                    switch ($FirstRunDone) {
                        $false {
                            $FirstRunDone = $true
                        }
                        Default {
                            $paramStartSleep = @{
                                $LoopDelayType = $LoopDelay
                            }
                            Start-Sleep @paramStartSleep
                        }
                    }
                    $ScriptBlock.Invoke()
                }
                until ($ExitCondition.Invoke() -or $StopWatch.Elapsed -ge $TimeSpan)
            }
            'ForLoop' {
                for ($i = 0; $i -lt $Iterations; $i++) {
                    switch ($FirstRunDone) {
                        $false {
                            $FirstRunDone = $true
                        }
                        Default {
                            $paramStartSleep = @{
                                $LoopDelayType = $LoopDelay
                            }
                            Start-Sleep @paramStartSleep
                        }
                    }
                    $ScriptBlock.Invoke()
                    if ($PSBoundParameters.ContainsKey('ExitCondition')) {
                        if ($ExitCondition.Invoke()) {
                            break
                        }
                    }
                }
            }
        }
    }
    end {
        switch ($PSCmdlet.ParameterSetName) {
            'DoUntil' {
                if ((-not $ExitCondition.Invoke()) -and $StopWatch.Elapsed -ge $TimeSpan -and $PSBoundParameters.ContainsKey('IfTimeoutScript')) {
                    $IfTimeoutScript.Invoke()
                }
                if ($ExitCondition.Invoke() -and $PSBoundParameters.ContainsKey('IfSucceedScript')) {
                    $IfSucceedScript.Invoke()
                }
                $StopWatch.Reset()
            }
            'ForLoop' {
                if ($PSBoundParameters.ContainsKey('ExitCondition')) {
                    if ((-not $ExitCondition.Invoke()) -and $i -ge $Iterations -and $PSBoundParameters.ContainsKey('IfTimeoutScript')) {
                        $IfTimeoutScript.Invoke()
                    }
                    elseif ($ExitCondition.Invoke() -and $PSBoundParameters.ContainsKey('IfSucceedScript')) {
                        $IfSucceedScript.Invoke()
                    }
                }
                else {
                    if ($i -ge $Iterations -and $PSBoundParameters.ContainsKey('IfTimeoutScript')) {
                        $IfTimeoutScript.Invoke()
                    }
                    elseif ($i -lt $Iterations -and $PSBoundParameters.ContainsKey('IfSucceedScript')) {
                        $IfSucceedScript.Invoke()
                    }
                }
            }
        }
    }
}
#EndRegion '.\Public\New-LoopAction.ps1' 183
#Region '.\Public\Remove-CCMCacheContent.ps1' 0
function Remove-CCMCacheContent {
    <#
        .SYNOPSIS
            Removes the provided ContentID from the MEMCM cache
        .DESCRIPTION
            This function will remove the provided ContentID from the MEMCM cache. This is done using the UIResource.UIResourceMGR COM Object.
        .PARAMETER ContentID
            ContentID that you want removed from the MEMCM cache. An array can be provided
        .PARAMETER Clear
            Remove all content from the MEMCM cache
        .PARAMETER Force
            Remove content from the cache, even if it is marked for 'persist content in client cache'
        .PARAMETER CimSession
            Provides CimSessions to remove the provided ContentID from the MEMCM cache for
        .PARAMETER ComputerName
            Provides computer names to remove the provided ContentID from the MEMCM cache for
        .PARAMETER PSSession
            Provides PSSession to remove the provided ContentID from the MEMCM cache for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Remove-CCMCacheContent -Clear
                Clears the local MEMCM cache
        .EXAMPLE
            C:\PS> Remove-CCMCacheContent -ComputerName 'Workstation1234','Workstation4321' -ContentID TST002FE
                Removes ContentID TST002FE from the MEMCM cache for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Remove-CCMCacheContent.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-12
            Updated:     2020-02-27
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param(
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ContentID,
        [parameter(Mandatory = $false)]
        [switch]$Clear,
        [parameter(Mandatory = $false)]
        [switch]$Force,
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
        switch ($PSBoundParameters.Keys -contains 'ContentID' -and $PSBoundParameters.Keys -contains 'Clear') {
            $true {
                Write-Error -ErrorAction Stop -Message 'Both ContentID and Clear parameters provided - please only provide one. Note that ParameterSetName is in use, but is currently being used for CimSession/ComputerName distinction. Feel free to make a pull request ;)'
            }
        }
        $invokeCommandSplat = @{
            FunctionsToLoad = 'Remove-CCMCacheContent', 'Get-CCMConnection'
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

            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [ContentID = '$([string]::Join('; ', $ContentID))]'", "Remove-CCMCacheContent")) {
                $removeCacheContentArgs = switch ($PSBoundParameters.Keys) {
                    'ContentID' {
                        [string]::Format('-ContentID "{0}"', [string]::Join('", "', $ContentID))
                    }
                    'Clear' {
                        '-Clear'
                    }
                    'Force' {
                        '-Force'
                    }
                }
                switch ($Computer -eq $env:ComputerName) {
                    $true {
                        $Client = New-Object -ComObject UIResource.UIResourceMGR
                        $Cache = $Client.GetCacheInfo()
                        $CacheContent = $Cache.GetCacheElements()
                        foreach ($ID in $ContentID) {
                            foreach ($CacheItem in $CacheContent) {
                                $CacheElementToRemove = switch ($PSBoundParameters.Keys) {
                                    'ContentID' {
                                        switch ($CacheItem.ContentID -eq $ID) {
                                            $true {
                                                $CacheItem.CacheElementId
                                            }
                                        }
                                    }
                                    'Clear' {
                                        $CacheItem.CacheElementId
                                    }
                                }
                                switch ($null -ne $CacheElementToRemove) {
                                    $true {
                                        switch ($Force.IsPresent) {
                                            $false {
                                                $Cache.DeleteCacheElement($CacheElementToRemove)
                                            }
                                            $true {
                                                $Cache.DeleteCacheElementEx($CacheElementToRemove, 1)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    $false {
                        $ScriptBlock = [string]::Format('Remove-CCMCacheContent {0}', [string]::Join(' ', $removeCacheContentArgs))
                        $invokeCommandSplat['ScriptBlock'] = [scriptblock]::Create($ScriptBlock)
                        Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                    }
                }
            }
        }
    }
}
#EndRegion '.\Public\Remove-CCMCacheContent.ps1' 139
#Region '.\Public\Repair-CCMCacheLocation.ps1' 0
function Repair-CCMCacheLocation {
    <#
        .SYNOPSIS
            Repairs ConfigMgr cache location from computers via CIM. This cleans up \\ and ccmcache\ccmcache in path
        .DESCRIPTION
            This function will allow you to clean the existing cache path for multiple computers using CIM queries.
            You can provide an array of computer names, or cimsessions, or you can pass them through the pipeline.
            It will return a hashtable with the computer as key and boolean as value for success
        .PARAMETER CimSession
            Provides CimSessions to repair the cache location for
        .PARAMETER ComputerName
            Provides computer names to repair the cache location for
        .PARAMETER PSSession
            Provides PSSessions to repair the cache location for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the 
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then 
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to. 
        .EXAMPLE
            C:\PS> Repair-CCMCacheLocation -Location d:\windows\ccmcache
                Repair cache for local computer
        .EXAMPLE
            C:\PS> Repair-CCMCacheLocation -ComputerName 'Workstation1234','Workstation4321'
                Repair Cache location for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Repair-CCMCacheLocation.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2019-11-06
            Updated:     2020-02-24
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
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
            $Return = [ordered]@{ }

            try {
                if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer']", "Repair CCM Cache Location")) {
                    $Cache = Get-CCMCacheInfo @connectionSplat
                    if ($Cache -is [pscustomobject]) {
                        $CurrentLocation = $Cache.Location
                        $NewLocation = $CurrentLocation -replace '\\\\', '\' -replace '(ccmcache\\?)+', 'ccmcache'
                        switch ($NewLocation -eq $CurrentLocation) {
                            $true {
                                $Return[$Computer] = $true
                            }
                            $false {
                                $connectionSplat['Location'] = $NewLocation
                                $SetCache = Set-CCMCacheLocation @connectionSplat
                                $Return[$Computer] = $SetCache.$Computer
                            }
                        }
                    }
                    Write-Output $Return
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Repair-CCMCacheLocation.ps1' 94
#Region '.\Public\Reset-CCMGUID.ps1' 0
# TODO - Write function
# TODO - Delete SMSCFG.INI
# TODO - Delete Certificates
# TODO - Restart Service
# TODO - Parse logs?
#EndRegion '.\Public\Reset-CCMGUID.ps1' 5
#Region '.\Public\Reset-CCMLoggingConfiguration.ps1' 0
function Reset-CCMLoggingConfiguration {
    <#
        .SYNOPSIS
            Reset ConfigMgr client log configuration for computers via CIM
        .DESCRIPTION
            This function will allow you to reset the ConfigMgr client log configuration for multiple computers using CIM queries.
            You can provide an array of computer names, or cimsessions, or you can pass them through the pipeline.

            The reset will set the log director to <client install directory\logs, max log size to 250000 byes, log level to 1, and max log history to 1
        .PARAMETER CimSession
            Provides CimSession to reset log configuration for
        .PARAMETER ComputerName
            Provides computer names to reset log configuration for
        .PARAMETER PSSession
            Provides PSSession to reset log configuration for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Reset-CCMLoggingConfiguration
                Resets local computer client logging configuration
        .NOTES
            FileName:    Reset-CCMLoggingConfiguration.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-11
            Updated:     2020-03-02
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
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
        $resetLogConfigSplat = @{
            Namespace   = 'root\ccm'
            ClassName   = 'SMS_Client'
            MethodName  = 'ResetGlobalLoggingConfiguration'
            ErrorAction = 'Stop'
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
            $Result['LogConfigChanged'] = $false
            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer']", "Reset-CCMLoggingConfiguration")) {
                try {
                    $Invocation = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Invoke-CimMethod @resetLogConfigSplat
                        }
                        $false {
                            $invokeCommandSplat = @{
                                ScriptBlock = {
                                    param($resetLogConfigSplat)
                                    Invoke-CimMethod @resetLogConfigSplat
                                }
                                ArgumentList = $resetLogConfigSplat
                            }
                            Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                        }
                    }
                    if ($Invocation) {
                        Write-Verbose "Successfully reset log options on $Computer via the 'ResetGlobalLoggingConfiguration' CIM method"
                        $Result['LogConfigChanged'] = $true
                    }
                    [pscustomobject]$Result
                }
                catch {
                    $ErrorMessage = $_.Exception.Message
                    Write-Error $ErrorMessage
                }
            }
        }
    }
}
#EndRegion '.\Public\Reset-CCMLoggingConfiguration.ps1' 103
#Region '.\Public\Set-CCMCacheLocation.ps1' 0
function Set-CCMCacheLocation {
    <#
        .SYNOPSIS
            Set ConfigMgr cache location from computers via CIM
        .DESCRIPTION
            This function will allow you to set the configuration manager cache location for multiple computers using CIM queries. 
            You can provide an array of computer names, or cimsession, or you can pass them through the pipeline.
            It will return a hashtable with the computer as key and boolean as value for success
        .PARAMETER Location
            Provides the desired cache location - note that ccmcache is appended if not provided as the end of the path
        .PARAMETER CimSession
            Provides CimSessions to set the cache location for
        .PARAMETER ComputerName
            Provides computer names to set the cache location for
        .PARAMETER PSSession
            Provides PSSessions to set the cache location for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the 
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then 
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to. 
        .EXAMPLE
            C:\PS> Set-CCMCacheLocation -Location d:\windows\ccmcache
                Set cache location to d:\windows\ccmcache for local computer
        .EXAMPLE
            C:\PS> Set-CCMCacheLocation -ComputerName 'Workstation1234','Workstation4321' -Location 'C:\windows\ccmcache'
                Set Cache location to 'C:\Windows\CCMCache' for Workstation1234, and Workstation4321
        .EXAMPLE
            C:\PS> Set-CCMCacheLocation -ComputerName 'Workstation1234','Workstation4321' -Location 'C:\temp\ccmcache'
                Set Cache location to 'C:\temp\CCMCache' for Workstation1234, and Workstation4321
        .EXAMPLE
            C:\PS> Set-CCMCacheLocation -Location 'D:'
                Set Cache location to 'D:\CCMCache' for the local computer
        .NOTES
            FileName:    Set-CCMCacheLocation.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2019-11-06
            Updated:     2020-03-01
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [parameter(Mandatory = $true)]
        [ValidateScript( { -not $_.EndsWith('\') } )]
        [string]$Location,
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
        $FullCachePath = switch ($Location.EndsWith('ccmcache', 'CurrentCultureIgnoreCase')) {
            $true {
                Write-Output $Location
            }
            $false {
                Join-Path -Path $Location -ChildPath 'ccmcache'
            }
        }
        
        $GetCacheSplat = @{
            Namespace = 'root\CCM\SoftMgmtAgent'
            ClassName = 'CacheConfig'
        }
        $SetCacheScriptblock = [scriptblock]::Create([string]::Format('(New-Object -ComObject UIResource.UIResourceMgr).GetCacheInfo().Location = "{0}"', (Split-Path -Path $FullCachePath -Parent)))
        $SetCacheSplat = @{
            ScriptBlock = $SetCacheScriptblock
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

            $Return = [ordered]@{ }

            try {
                if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [Location = '$Location']", "Set CCM Cache Location")) {
                    $Cache = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Get-CimInstance @GetCacheSplat @connectionSplat
                        }
                        $false {
                            Get-CCMCimInstance @GetCacheSplat @connectionSplat
                        }
                    }
                    if ($Cache -is [object]) {
                        switch ($Cache.Location) {
                            $FullCachePath {
                                $Return[$Computer] = $true
                            }
                            default {
                                switch ($Computer -eq $env:ComputerName) {
                                    $true {
                                        $SetCacheScriptblock.Invoke()
                                    }
                                    $false {
                                        Invoke-CCMCommand @SetCacheSplat @connectionSplat
                                    }
                                }
                                $Cache = switch ($Computer -eq $env:ComputerName) {
                                    $true {
                                        Get-CimInstance @GetCacheSplat @connectionSplat
                                    }
                                    $false {
                                        Get-CCMCimInstance @GetCacheSplat @connectionSplat
                                    }
                                }
                                switch ($Cache.Location) {
                                    $FullCachePath {
                                        $Return[$Computer] = $true
                                    }
                                    default {       
                                        $Return[$Computer] = $false
                                    }
                                }
                            }
                        }
                    }
                    Write-Output $Return
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Set-CCMCacheLocation.ps1' 148
#Region '.\Public\Set-CCMCacheSize.ps1' 0
function Set-CCMCacheSize {
    <#
        .SYNOPSIS
            Set ConfigMgr cache size from computers via UIResource.UIResourceMgr invoked over CIM
        .DESCRIPTION
            This function will allow you to set the configuration manager cache size for multiple computers using Invoke-CIMPowerShell.
            You can provide an array of computer names, cimsesions, or you can pass them through the pipeline.
            It will return a hashtable with the computer as key and boolean as value for success
        .PARAMETER Size
            Provides the desired cache size in MB
        .PARAMETER CimSession
            Provides CimSessions to set CCMCache size on
        .PARAMETER ComputerName
            Provides computer names to set CCMCache size on
        .PARAMETER PSSession
            Provides PSSession to set CCMCache size on
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Set-CCMCacheSize -Size 20480
                Set the cache size to 20480 MB for the local computer
        .EXAMPLE
            C:\PS> Set-CCMCacheSize -ComputerName 'Workstation1234','Workstation4321' -Size 10240
                Set the cache size to 10240 MB for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Set-CCMCacheSize.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2019-11-06
            Updated:     2020-03-01
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [parameter(Mandatory = $true)]
        [ValidateRange(1, 99999)]
        [int]$Size,
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
        $GetCacheSplat = @{
            Namespace   = 'root\CCM\SoftMgmtAgent'
            ClassName   = 'CacheConfig'
            ErrorAction = 'Stop'
        }
        $SetCacheSizeScriptBlockString = [string]::Format('(New-Object -ComObject UIResource.UIResourceMgr).GetCacheInfo().TotalSize = {0}', $Size)
        $SetCacheSizeScriptBlock = [scriptblock]::Create($SetCacheSizeScriptBlockString)
        $invokeCommandSplat = @{
            ScriptBlock = $SetCacheSizeScriptBlock
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

            $Return = [ordered]@{ }

            try {
                if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [Size = '$Size']", "Set CCM Cache Size")) {
                    $Cache = switch ($Computer -eq $env:ComputerName) {
                        $true {
                            Get-CimInstance @GetCacheSplat @connectionSplat
                        }
                        $false {
                            Get-CCMCimInstance @GetCacheSplat @connectionSplat
                        }
                    }
                    if ($Cache -is [object]) {
                        switch ($Cache.Size) {
                            $Size {
                                $Return[$Computer] = $true
                            }
                            default {
                                switch ($Computer -eq $env:ComputerName) {
                                    $true {
                                        $SetCacheSizeScriptBlock.Invoke()
                                    }
                                    $false {
                                        Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                                    }
                                }
                                $Cache = switch ($Computer -eq $env:ComputerName) {
                                    $true {
                                        Get-CimInstance @GetCacheSplat @connectionSplat
                                    }
                                    $false {
                                        Get-CCMCimInstance @GetCacheSplat @connectionSplat
                                    }
                                }
                                if ($Cache -is [Object] -and $Cache.Size -eq $Size) {
                                    $Return[$Computer] = $true
                                }
                                else {
                                    $Return[$Computer] = $false
                                }
                            }
                        }
                    }
                    Write-Output $Return
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Set-CCMCacheSize.ps1' 133
#Region '.\Public\Set-CCMClientAlwaysOnInternet.ps1' 0
function Set-CCMClientAlwaysOnInternet {
    <#
        .SYNOPSIS
            Set the ClientAlwaysOnInternet registry key on a computer
        .DESCRIPTION
            This function leverages the Set-CCMRegistryProperty function in order to configure
            the ClientAlwaysOnInternet property for the MEMCM Client.
        .PARAMETER Status
            Determines if the setting should be Enabled or Disabled
        .PARAMETER CimSession
            Provides CimSessions to set the ClientAlwaysOnInternet setting for
        .PARAMETER ComputerName
            Provides computer names to set the ClientAlwaysOnInternet setting for
        .PARAMETER PSSession
            Provides PSSessions to set the ClientAlwaysOnInternet setting for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Set-CCMClientAlwaysOnInternet -Status Enabled
                Sets ClientAlwaysOnInternet to Enabled for the local computer
        .EXAMPLE
            C:\PS> Set-CCMClientAlwaysOnInternet -ComputerName 'Workstation1234','Workstation4321' -Status Disabled
                Sets ClientAlwaysOnInternet to Disabled for 'Workstation1234', and 'Workstation4321'
        .NOTES
            FileName:    Set-CCMClientAlwaysOnInternet.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-02-13
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Enabled', 'Disabled')]
        [string]$Status,
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
        $Enablement = switch ($Status) {
            'Enabled' {
                1
            }
            'Disabled' {
                0
            }
        }
        $SetAlwaysOnInternetSplat = @{
            Force        = $true
            PropertyType = 'DWORD'
            Property     = 'ClientAlwaysOnInternet'
            Value        = $Enablement
            Key          = 'SOFTWARE\Microsoft\CCM\Security'
            RegRoot      = 'HKEY_LOCAL_MACHINE'
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

            try {
                Set-CCMRegistryProperty @SetAlwaysOnInternetSplat @connectionSplat
            }
            catch {
                Write-Error "Failure to set MEMCM ClientAlwaysOnInternet to $Enablement for $Computer - $($_.Exception.Message)"
            }
        }
    }
}
#EndRegion '.\Public\Set-CCMClientAlwaysOnInternet.ps1' 94
#Region '.\Public\Set-CCMDNSSuffix.ps1' 0
function Set-CCMDNSSuffix {
    <#
        .SYNOPSIS
            Sets the current DNS suffix for the MEMCM Client
        .DESCRIPTION
            This function will set the current DNS suffix for the MEMCM Client. This is done using the Microsoft.SMS.Client COM Object.
        .PARAMETER DNSSuffix
            The desired DNS Suffix that will be set for the specified computers/cimsessions
        .PARAMETER ComputerName
            Provides computer names to set the current DNS suffix for
        .PARAMETER PSSession
            Provides PSSession to set the current DNS suffix for
        .EXAMPLE
            C:\PS> Set-CCMDNSSuffix -DNSSuffix 'contoso.com'
                Sets the local computer's DNS Suffix to contoso.com
        .EXAMPLE
            C:\PS> Set-CCMDNSSuffix -ComputerName 'Workstation1234','Workstation4321' -DNSSuffix 'contoso.com'
                Sets the DNS Suffix for Workstation1234, and Workstation4321 to contoso.com
        .NOTES
            FileName:    Set-CCMDNSSuffix.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-18
            Updated:     2020-08-01
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param(
        [parameter(Mandatory = $false)]
        [string]$DNSSuffix,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [Alias('Session')]      
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession
    )
    begin {
        $SetDNSSuffixScriptBlockString = [string]::Format('(New-Object -ComObject Microsoft.SMS.Client).SetDNSSuffix("{0}")', $DNSSuffix)
        $SetDNSSuffixScriptBlock = [scriptblock]::Create($SetDNSSuffixScriptBlockString)
        $invokeCommandSplat = @{
            ScriptBlock = $SetDNSSuffixScriptBlock
        }
    }
    process {
        foreach ($Connection in (Get-Variable -Name $PSCmdlet.ParameterSetName -ValueOnly)) {
            $getConnectionInfoSplat = @{
                $PSCmdlet.ParameterSetName = $Connection
                Prefer                     = 'PSSession'
            }
            $ConnectionInfo = Get-CCMConnection @getConnectionInfoSplat
            $Computer = $ConnectionInfo.ComputerName
            $connectionSplat = $ConnectionInfo.connectionSplat

            $Result = [ordered]@{ }
            $Result['ComputerName'] = $Computer
            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [DNSSuffix = '$DNSSuffix']", "Set-CCMDNSSuffix")) {
                try {
                    switch ($Computer -eq $env:ComputerName) {
                        $true {
                            $SetDNSSuffixScriptBlock.Invoke()
                        }
                        $false {
                            Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                        }
                    }
                    $Result['DNSSuffixSet'] = $true
                }
                catch {
                    $Result['DNSSuffixSet'] = $false
                    Write-Error "Failure to set DNS Suffix to $DNSSuffix for $Computer - $($_.Exception.Message)"
                }
                [pscustomobject]$Result
            }
        }
    }
}
#EndRegion '.\Public\Set-CCMDNSSuffix.ps1' 76
#Region '.\Public\Set-CCMLoggingConfiguration.ps1' 0
function Set-CCMLoggingConfiguration {
    <#
        .SYNOPSIS
            Set ConfigMgr client log configuration from computers via CIM
        .DESCRIPTION
            This function will allow you to set the ConfigMgr client log configuration for multiple computers using CIM queries.
            You can provide an array of computer names, or cimsessions, or you can pass them through the pipeline.
        .PARAMETER LogLocation
            The location of MEMCM log files. Setting this will not take complete affect until the CCMExec service is restarted.
        .PARAMETER LogLevel
            Preferred logging level, either Default, or Verbose
        .PARAMETER LogMaxSize
            Maximum log size in Bytes
        .PARAMETER LogMaxHistory
            Max number of logs to retain
        .PARAMETER DebugLogging
            Set debug logging to on, or off
        .PARAMETER CimSession
            Provides CimSession to set log configuration for
        .PARAMETER ComputerName
            Provides computer names to set log configuration for
        .PARAMETER PSSession
            Provides PSSession to set log configuration for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Set-CCMLoggingConfiguration -LogLevel Verbose
                Sets local computer to use Verbose logging
        .EXAMPLE
            C:\PS> Set-CCMLoggingConfiguration -ComputerName 'Workstation1234','Workstation4321' -LogMaxSize 8192000 -LogMaxHistory 2
                Configure the client to have a max log size of 8mb and retain 2 log files for Workstation1234, and Workstation4321
        .NOTES
            FileName:    Set-CCMLoggingConfiguration.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-11
            Updated:     2020-03-03
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateScript( { Test-Path -Path $_ -PathType Container -ErrorAction Stop } )]
        [string]$LogLocation,
        [Parameter(Mandatory = $false)]
        [ValidateSet('Default', 'Verbose', 'None')]
        [string]$LogLevel,
        [Parameter(Mandatory = $false)]
        [int]$LogMaxSize,
        [Parameter(Mandatory = $false)]
        [int]$LogMaxHistory,
        [Parameter(Mandatory = $false)]
        [bool]$DebugLogging,
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
        $setLogConfigSplat = @{
            Namespace   = 'root\ccm'
            ClassName   = 'SMS_Client'
            MethodName  = 'SetGlobalLoggingConfiguration'
            ErrorAction = 'Stop'
        }

        $LogLevelInt = switch ($LogLevel) {
            'None' {
                2
            }
            'Default' {
                1
            }
            'Verbose' {
                0
            }
        }

        $LogConfigArgs = @{ }
        $WhatIfLog = [System.Collections.Generic.List[string]]::new()
        switch ($PSBoundParameters.Keys) {
            'LogLevel' {
                $LogConfigArgs['LogLevel'] = [uint32]$LogLevelInt
                $WhatIfLog.Add([string]::Format("[{0} = '{1}']", $PSItem, (Get-Variable -Name $PSItem -ValueOnly -Scope Local)))
            }
            'LogMaxSize' {
                $LogConfigArgs['LogMaxSize'] = [uint32]$LogMaxSize
                $WhatIfLog.Add([string]::Format("[{0} = '{1}']", $PSItem, (Get-Variable -Name $PSItem -ValueOnly -Scope Local)))
            }
            'LogMaxHistory' {
                $LogConfigArgs['LogMaxHistory'] = [uint32]$LogMaxHistory
                $WhatIfLog.Add([string]::Format("[{0} = '{1}']", $PSItem, (Get-Variable -Name $PSItem -ValueOnly -Scope Local)))
            }
            'DebugLogging' {
                $LogConfigArgs['DebugLogging'] = [bool]$DebugLogging
                $WhatIfLog.Add([string]::Format("[{0} = '{1}']", $PSItem, (Get-Variable -Name $PSItem -ValueOnly -Scope Local)))
            }
            'LogLocation' {
                $SetLogLocationSplat = @{
                    Force        = $true
                    PropertyType = 'String'
                    Property     = 'LogDirectory'
                    Value        = $LogLocation.TrimEnd('\')
                    Key          = 'SOFTWARE\Microsoft\CCM\Logging\@Global'
                    RegRoot      = 'HKEY_LOCAL_MACHINE'
                }
                $WhatIfLog.Add([string]::Format("[{0} = '{1}']", $PSItem, (Get-Variable -Name $PSItem -ValueOnly -Scope Local)))
            }
        }
        $setLogConfigSplat['Arguments'] = $LogConfigArgs
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

            $WhatIfLog.Insert(0, "[ComputerName = '$Computer']")
            if ($PSCmdlet.ShouldProcess([string]::Join(' ', $WhatIfLog), "Set-CCMLoggingConfiguration")) {
                $Result = [ordered]@{ }
                $Result['ComputerName'] = $Computer
                $Result['LogConfigChanged'] = $false

                try {
                    switch -regex ($PSBoundParameters.Keys) {
                        '^LogLevel$|^LogMaxSize$|^LogMaxHistory$|^DebugLogging$' {
                            $LogConfigChanged = switch ($Computer -eq $env:ComputerName) {
                                $true {
                                    Invoke-CimMethod @setLogConfigSplat
                                }
                                $false {
                                    $invokeCommandSplat = @{
                                        ArgumentList = $setLogConfigSplat
                                        ScriptBlock  = {
                                            param($setLogConfigSplat)
                                            Invoke-CimMethod @setLogConfigSplat
                                        }
                                    }
                                    Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                                }
                            }
                            if ($LogConfigChanged) {
                                Write-Verbose "Successfully configured log options on $Computer via the 'SetGlobalLoggingConfiguration' CIM method"
                                $Result['LogConfigChanged'] = $true
                            }
                            break
                        }
                    }
                    switch ($PSBoundParameters.ContainsKey('LogLocation')) {
                        $true {
                            $LogLocationChanged = Set-CCMRegistryProperty @SetLogLocationSplat @connectionSplat
                            Write-Warning "The CCMExec service needs restarted for log location changes to take full affect."
                            $Result['LogLocationChanged'] = $LogLocationChanged[$Computer]
                        }
                    }

                    [pscustomobject]$Result
                }
                catch {
                    $ErrorMessage = $_.Exception.Message
                    Write-Error $ErrorMessage
                }
            }
        }
    }
}
#EndRegion '.\Public\Set-CCMLoggingConfiguration.ps1' 186
#Region '.\Public\Set-CCMManagementPoint.ps1' 0
function Set-CCMManagementPoint {
    <#
        .SYNOPSIS
            Sets the current management point for the MEMCM Client
        .DESCRIPTION
            This function will set the current management point for the MEMCM Client. This is done using the Microsoft.SMS.Client COM Object.
        .PARAMETER ManagementPointFQDN
            The desired management point that will be set for the specified computers/cimsessions
        .PARAMETER ComputerName
            Provides computer names to set the current management point for
        .PARAMETER PSSession
            Provides PSSession to set the current management point for
        .EXAMPLE
            C:\PS> Set-CCMManagementPoint -ManagementPointFQDN 'cmmp1.contoso.com'
                Sets the local computer's management point to cmmp1.contoso.com
        .EXAMPLE
            C:\PS> Set-CCMManagementPoint -ComputerName 'Workstation1234','Workstation4321' -ManagementPointFQDN 'cmmp1.contoso.com'
                Sets the management point for Workstation1234, and Workstation4321 to cmmp1.contoso.com
        .NOTES
            FileName:    Set-CCMManagementPoint.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-18
            Updated:     2020-08-01
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    [Alias('Set-CCMMP')]
    param(
        [parameter(Mandatory = $true)]
        [string]$ManagementPointFQDN,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [Alias('Session')]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession
    )
    begin {
        $SetCurrentManagementPointScriptBlockString = [string]::Format('(New-Object -ComObject Microsoft.SMS.Client).SetCurrentManagementPoint("{0}", 1)', $ManagementPointFQDN)
        $SetCurrentManagementPointScriptBlock = [scriptblock]::Create($SetCurrentManagementPointScriptBlockString)
        $invokeCommandSplat = @{
            ScriptBlock = $SetCurrentManagementPointScriptBlock
        }
    }
    process {
        foreach ($Connection in (Get-Variable -Name $PSCmdlet.ParameterSetName -ValueOnly)) {
            $getConnectionInfoSplat = @{
                $PSCmdlet.ParameterSetName = $Connection
                Prefer                     = 'PSSession'
            }
            $ConnectionInfo = Get-CCMConnection @getConnectionInfoSplat
            $Computer = $ConnectionInfo.ComputerName
            $connectionSplat = $ConnectionInfo.connectionSplat

            $Result = [ordered]@{ }
            $Result['ComputerName'] = $Computer
            $Result['ManagementPointFQDNSet'] = $false

            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [ManagementPointFQDN = '$ManagementPointFQDN']", "Set-CCMManagementPoint")) {
                try {
                    switch ($Computer -eq $env:ComputerName) {
                        $true {
                            $SetCurrentManagementPointScriptBlock.Invoke()
                        }
                        $false {
                            Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                        }
                    }
                    $Result['ManagementPointFQDNSet'] = $true
                }
                catch {
                    Write-Error "Failure to set management point to $ManagementPointFQDN for $Computer - $($_.Exception.Message)"
                }
                [pscustomobject]$Result
            }
        }
    }
}
#EndRegion '.\Public\Set-CCMManagementPoint.ps1' 78
#Region '.\Public\Set-CCMProvisioningMode.ps1' 0
function Set-CCMProvisioningMode {
    <#
        .SYNOPSIS
            Set ConfigMgr client provisioning mode to enabled or disabled, and control ProvisioningMaxMinutes
        .DESCRIPTION
            This function will allow you to set the configuration manager client provisioning mode using CIM queries.
            You can provide an array of computer names, or cimsession, or you can pass them through the pipeline.
            It will return a pscustomobject detailing the operations
        .PARAMETER Status
            Should provisioning mode be enabled, or disabled? Validate set ('Enabled','Disabled')
        .PARAMETER ProvisioningMaxMinutes
            Set the ProvisioningMaxMinutes value for provisioning mode. After this interval, provisioning mode is
            automatically disabled. This defaults to 48 hours. The client checks this every 60 minutes, so any
            value under 60 minutes will result in an effective ProvisioningMaxMinutes of 60 minutes.
        .PARAMETER CimSession
            Provides CimSessions to set provisioning mode for
        .PARAMETER ComputerName
            Provides computer names to set provisioning mode for
        .PARAMETER PSSession
            Provides PSSession to set provisioning mode for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Set-CCMProvisioningMode -Status Enabled
                Enables provisioning mode on the local computer
        .EXAMPLE
            C:\PS> Set-CCMProvisioningMode -ComputerName 'Workstation1234','Workstation4321' -Status Disabled
                Disables provisioning mode for Workstation1234, and Workstation4321
        .EXAMPLE
            C:\PS> Set-CCMProvisioningMode -ProvisioningMaxMinutes 360
                Sets ProvisioningMaxMinutes to 360 on the local computer so that provisioning mode is automatically
                disabled after 6 hours, instead of the default 48 hours
        .NOTES
            FileName:    Set-CCMProvisioningMode.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-09
            Updated:     2020-03-02
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param (
        [parameter(Mandatory = $false)]
        [ValidateSet('Enabled', 'Disabled')]
        [string]$Status,
        [parameter(Mandatory = $false)]
        [ValidateRange(60, [int]::MaxValue)]
        [int]$ProvisioningMaxMinutes,
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
        [bool]$ProvisioningMode = switch ($Status) {
            'Enabled' {
                $true
            }
            'Disabled' {
                $false
            }
        }
        $SetProvisioningModeSplat = @{
            Namespace  = 'root\CCM'
            ClassName  = 'SMS_Client'
            MethodName = 'SetClientProvisioningMode'
            Arguments  = @{
                bEnable = $ProvisioningMode
            }
        }
        $setCIMRegistryPropertySplat = @{
            RegRoot      = 'HKEY_LOCAL_MACHINE'
            Key          = 'Software\Microsoft\CCM\CcmExec'
            Property     = 'ProvisioningMaxMinutes'
            Value        = $ProvisioningMaxMinutes
            PropertyType = 'DWORD'
            Force        = $true
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

            $Return = [ordered]@{ }
            $Return['ComputerName'] = $Computer
            $Return['ProvisioningModeChanged'] = $false
            $Return['ProvisioningMaxMinutesChanged'] = $false
            try {
                if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [ProvisioningMode = '$Status'] [ProvisioningMaxMinutes = '$ProvisioningMaxMinutes']", "Set CCM Provisioning Mode")) {
                    switch ($PSBoundParameters.Keys) {
                        'Status' {
                            $Invocation = switch ($Computer -eq $env:ComputerName) {
                                $true {
                                    Invoke-CimMethod @SetProvisioningModeSplat
                                }
                                $false {
                                    $invokeCommandSplat = @{
                                        ArgumentList = $SetProvisioningModeSplat
                                        ScriptBlock  = {
                                            param($StatuSetProvisioningModeSplats)
                                            Invoke-CimMethod @SetProvisioningModeSplat
                                        }
                                    }
                                    Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                                }
                            }
                            if ($Invocation) {
                                Write-Verbose "Successfully set provisioning mode to $Status for $Computer via the 'SetClientProvisioningMode' CIM method"
                                $Return['ProvisioningModeChanged'] = $true
                            }
                        }
                        'ProvisioningMaxMinutes' {
                            $MaxMinutesChange = Set-CCMRegistryProperty @setCIMRegistryPropertySplat @connectionSplat
                            if ($MaxMinutesChange[$Computer]) {
                                Write-Verbose "Successfully set ProvisioningMaxMinutes for $Computer to $ProvisioningMaxMinutes"
                                $Return['ProvisioningMaxMinutesChanged'] = $true
                            }
                        }
                    }
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
            [pscustomobject]$Return
        }
    }
}
#EndRegion '.\Public\Set-CCMProvisioningMode.ps1' 151
#Region '.\Public\Set-CCMRegistryProperty.ps1' 0
function Set-CCMRegistryProperty {
    <#
        .SYNOPSIS
            Set registry properties values using the CIM StdRegProv, or Invoke-CCMCommand
        .DESCRIPTION
            Relies on remote CIM and StdRegProv to allow for setting a Registry Property value. If a PSSession, or ConnectionPreference
            is used, then Invoke-CCMCommand is used instead.
        .PARAMETER RegRoot
            The root key you want to search under
            ('HKEY_LOCAL_MACHINE', 'HKEY_USERS', 'HKEY_CURRENT_CONFIG', 'HKEY_DYN_DATA', 'HKEY_CLASSES_ROOT', 'HKEY_CURRENT_USER')
        .PARAMETER Key
            The key you want to set properties of. (ie. SOFTWARE\Microsoft\SMS\Client\Configuration\Client Properties)
        .PARAMETER Property
            The property name you want to set the value for
        .PARAMETER Value
            The desired value for the property
        .PARAMETER PropertyType
            The type of property you are setting. This is needed because the method for setting a registry value changes based on property type.
            'String', 'ExpandedString', 'Binary', 'DWORD', 'MultiString', 'QWORD'
        .PARAMETER Force
            Create the Property if it does not exist, otherwise only existing properties will have their value modified
        .PARAMETER CimSession
            Provides CimSessions to set registry properties for
        .PARAMETER ComputerName
            Provides computer names to set registry properties for
        .PARAMETER PSSession
            Provides PSSessions to set registry properties for
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
        .EXAMPLE
            PS> Set-CCMRegistryProperty -RegRoot HKEY_LOCAL_MACHINE -Key 'SOFTWARE\Microsoft\SMS\Client\Client Components\Remote Control' -Property "Allow Remote Control of an unattended computer" -Value 1 -PropertyType DWORD
            Name                           Value
            ----                           -----
            Computer123                    $true
        .OUTPUTS
            [System.Collections.Hashtable]
        .NOTES
            FileName:    Set-CCMRegistryProperty.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     Uhh... I forget
            Updated:     2020-03-02
#>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    [Alias('Set-CIMRegistryProperty')]
    param (
        [parameter(Mandatory = $true)]
        [ValidateSet('HKEY_LOCAL_MACHINE', 'HKEY_USERS', 'HKEY_CURRENT_CONFIG', 'HKEY_DYN_DATA', 'HKEY_CLASSES_ROOT', 'HKEY_CURRENT_USER')]
        [string]$RegRoot,
        [parameter(Mandatory = $true)]
        [string]$Key,
        [parameter(Mandatory = $true)]
        [string]$Property,
        [parameter(Mandatory = $true)]
        $Value,
        [parameter(Mandatory = $true)]
        [ValidateSet('String', 'ExpandedString', 'Binary', 'DWORD', 'MultiString', 'QWORD')]
        [string]$PropertyType,
        [parameter(Mandatory = $false)]
        [switch]$Force,
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
        #region create hash tables for translating values
        $RootKey = @{
            HKEY_CLASSES_ROOT   = 2147483648
            HKEY_CURRENT_USER   = 2147483649
            HKEY_LOCAL_MACHINE  = 2147483650
            HKEY_USERS          = 2147483651
            HKEY_CURRENT_CONFIG = 2147483653
            HKEY_DYN_DATA       = 2147483654
        }
        <#
            Maps the 'PropertyType' per property to the method we will invoke to set the value.
            For example, if the 'type' is string we have invoke the SetStringValue method
        #>
        $RegPropertyMethod = @{
            'String'         = 'SetStringValue'
            'ExpandedString' = 'SetExpandedStringValue'
            'Binary'         = 'SetBinaryValue'
            'DWORD'          = 'SetDWORDValue'
            'MultiString'    = 'SetMultiStringValue'
            'QWORD'          = 'SetQWORDValue'
        }
        $Method = $RegPropertyMethod[$PropertyType]
        #endregion create hash tables for translating values

        # convert RootKey friendly name to the [uint32] equivalent so it can be used later
        $Root = $RootKey[$RegRoot]

        #region define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
        $setCIMRegPropSplat = @{
            Namespace   = 'root\default'
            ClassName   = 'StdRegProv'
            ErrorAction = 'Stop'
        }
        #endregion define our hash tables for parameters to pass to Get-CIMInstance and our return hash table

        $PropertyTypeMap = @{
            SetDWORDValue          = [UInt32]
            SetQWORDValue          = [UInt64]
            SetStringValue         = [String]
            SetMultiStringValue    = [String[]]
            SetExpandedStringValue = [String]
            SetBinaryValue         = [byte[]]
        }

        $ReturnValName = @{
            SetDWORDValue          = 'uValue'
            SetQWORDValue          = 'uValue'
            SetStringValue         = 'sValue'
            SetMultiStringValue    = 'sValue'
            SetExpandedStringValue = 'sValue'
            SetBinaryValue         = 'uValue'
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

            $Return = [ordered]@{ }
            $Return[$Computer] = $false

            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [sValueName = '$Property'] [Value = '$Value']", "Set-CCMRegistryProperty")) {
                switch -regex ($ConnectionInfo.ConnectionType) {
                    '^CimSession$|^ComputerName$' {
                        $setCIMRegPropSplat['MethodName'] = 'EnumValues'
                        $setCIMRegPropSplat['Arguments'] = @{
                            hDefKey     = [uint32]$Root
                            sSubKeyName = $Key
                        }

                        $EnumValues = Invoke-CimMethod @setCIMRegPropSplat @connectionSplat

                        $setCIMRegPropSplat['MethodName'] = $Method
                        $setCIMRegPropSplat['Arguments']['sValueName'] = $Property
                        $setCIMRegPropSplat['Arguments'][$ReturnValName[$Method]] = $Value -as $PropertyTypeMap[$Method]

                        switch ($EnumValues.sNames -contains $Property) {
                            $true {
                                $SetProperty = Invoke-CimMethod @setCIMRegPropSplat @connectionSplat
                            }
                            $false {
                                switch ($Force.IsPresent) {
                                    $true {
                                        $SetProperty = Invoke-CimMethod @setCIMRegPropSplat @connectionSplat
                                    }
                                    $false {
                                        Write-Warning ([string]::Format('[Property = {0}] does not exist under [Key = {1}\{2}] and the force parameter was not specified. No changes will be made', $Property, $RegRoot, $Key))
                                    }
                                }
                            }
                        }
                        if ($null -ne $SetProperty) {
                            switch ($SetProperty.ReturnValue) {
                                0 {
                                    $Return[$Computer] = $true
                                }
                                default {
                                    Write-Error ([string]::Format('Failed to set value [Property = {0}] [Key = {1}\{2}] [Value = {3}] [PropertyType = {4}] [Method = {5}]', $Property, $RegRoot, $Key, $Value, $PropertyType, $Method))
                                }
                            }
                        }
                    }
                    '^PSSession$' {
                        $RegPath = [string]::Format('registry::{0}\{1}', $RegRoot, $Key)
                        $InvokeCommandSplat = @{
                            ArgumentList = $RegPath, $Property, $Value, $PropertyType, $Force.IsPresent
                        }

                        $InvokeCommandSplat['ScriptBlock'] = {
                            param(
                                $RegPath,
                                $Property,
                                $Value,
                                $PropertyType,
                                $Force
                            )
                            $Exists = Get-ItemProperty -Path $RegPath -Name $Property -ErrorAction SilentlyContinue
                            try {
                                switch ([bool]$Exists) {
                                    $true {
                                        Set-ItemProperty -Path $RegPath -Name $Property -Value $Value -Type $PropertyType -ErrorAction Stop
                                        Write-Output $true
                                    }
                                    $false {
                                        switch ([bool]$Force) {
                                            $true {
                                                Set-ItemProperty -Path $RegPath -Name $Property -Value $Value -Type $PropertyType -ErrorAction Stop
                                                Write-Output $true
                                            }
                                            $false {
                                                Write-Warning ([string]::Format('[Property = {{0}}] does not exist under [Key = {{1}}] and the force parameter was not specified. No changes will be made', $Property, $RegPath))
                                                Write-Output $false
                                            }
                                        }
                                    }
                                }
                            }
                            catch {
                                Write-Error $_.Exception.Message
                                Write-Output $false
                            }
                        }
                        
                        $Return[$Computer] = Invoke-CCMCommand @InvokeCommandSplat @connectionSplat
                    }
                }

                Write-Output $Return
            }
        }
    }
}
#EndRegion '.\Public\Set-CCMRegistryProperty.ps1' 240
#Region '.\Public\Set-CCMSite.ps1' 0
function Set-CCMSite {
    <#
        .SYNOPSIS
            Sets the current MEMCM Site for the MEMCM Client
        .DESCRIPTION
            This function will set the current MEMCM Site for the MEMCM Client. This is done using the Microsoft.SMS.Client COM Object.
        .PARAMETER SiteCode
            The desired MEMCM Site that will be set for the specified computers
        .PARAMETER ComputerName
            Provides computer names to set the current MEMCM Site for
        .PARAMETER PSSession
            Provides PSSession to set the current MEMCM Site for
        .EXAMPLE
            C:\PS> Set-CCMSite -SiteCode 'TST'
                Sets the local computer's MEMCM Site to TST
        .EXAMPLE
            C:\PS> Set-CCMSite -ComputerName 'Workstation1234','Workstation4321' -SiteCode 'TST'
                Sets the MEMCM Site for Workstation1234, and Workstation4321 to TST
        .NOTES
            FileName:    Set-CCMSite.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-18
            Updated:     2020-08-01
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ComputerName')]
    param(
        [parameter(Mandatory = $true)]
        [string]$SiteCode,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [Alias('Session')]      
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession
    )
    begin {
        $SetAssignedSiteCodeScriptBlockString = [string]::Format('(New-Object -ComObject Microsoft.SMS.Client).SetAssignedSite("{0}", 0)', $SiteCode)
        $SetAssignedSiteCodeScriptBlock = [scriptblock]::Create($SetAssignedSiteCodeScriptBlockString)
        $invokeCommandSplat = @{
            ScriptBlock = $SetAssignedSiteCodeScriptBlock
        }
    }
    process {
        foreach ($Connection in (Get-Variable -Name $PSCmdlet.ParameterSetName -ValueOnly)) {
            $getConnectionInfoSplat = @{
                $PSCmdlet.ParameterSetName = $Connection
                Prefer                     = 'PSSession'
            }
            $ConnectionInfo = Get-CCMConnection @getConnectionInfoSplat
            $Computer = $ConnectionInfo.ComputerName
            $connectionSplat = $ConnectionInfo.connectionSplat

            $Result = [ordered]@{ }
            $Result['ComputerName'] = $Computer

            if ($PSCmdlet.ShouldProcess("[ComputerName = '$Computer'] [Site = '$SiteCode']", "Set-CCMSite")) {
                try {
                    switch ($Computer -eq $env:ComputerName) {
                        $true {
                            $SetAssignedSiteCodeScriptBlock.Invoke()
                            $Result['SiteSet'] = $true
                            [pscustomobject]$Result
                        }
                        $false {
                            Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                        }
                    }
                }
                catch {
                    $Result['SiteSet'] = $false
                    Write-Error "Failure to set MEMCM Site to $SiteCode for $Computer - $($_.Exception.Message)"
                }
            }
        }
    }
}
#EndRegion '.\Public\Set-CCMSite.ps1' 77
#Region '.\Public\Test-CCMIsClientAlwaysOnInternet.ps1' 0
function Test-CCMIsClientAlwaysOnInternet {
    <#
        .SYNOPSIS
            Return the status of the MEMCM client having AlwaysOnInternet set
        .DESCRIPTION
            This function will invoke the IsClientAlwaysOnInternet of the MEMCM Client.
             This is done using the Microsoft.SMS.Client COM Object.
        .PARAMETER ComputerName
            Provides computer names to return AlwaysOnInternet setting info from
        .PARAMETER PSSession
            Provides PSSession to return AlwaysOnInternet setting info from
        .EXAMPLE
            C:\PS> Test-CCMIsClientAlwaysOnInternet
                Returns the status of the local computer having IsAlwaysOnInternet set
        .EXAMPLE
            C:\PS> Test-CCMIsClientAlwaysOnInternet -ComputerName 'Workstation1234','Workstation4321'
                Returns the status of 'Workstation1234','Workstation4321' having IsAlwaysOnInternet set
        .NOTES
            FileName:    Test-CCMIsClientAlwaysOnInternet.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-29
            Updated:     2020-08-01
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param(
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [Alias('Session')]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession
    )
    begin {
        $IsClientAlwaysOnInternetScriptBlock = {
            $Client = New-Object -ComObject Microsoft.SMS.Client
            [bool]$Client.IsClientAlwaysOnInternet()
        }
        $invokeCommandSplat = @{
            ScriptBlock = $IsClientAlwaysOnInternetScriptBlock
        }
    }
    process {
        foreach ($Connection in (Get-Variable -Name $PSCmdlet.ParameterSetName -ValueOnly)) {
            $getConnectionInfoSplat = @{
                $PSCmdlet.ParameterSetName = $Connection
                Prefer                     = 'PSSession'
            }
            $ConnectionInfo = Get-CCMConnection @getConnectionInfoSplat
            $Computer = $ConnectionInfo.ComputerName
            $connectionSplat = $ConnectionInfo.connectionSplat

            $Result = [ordered]@{ }
            $Result['ComputerName'] = $Computer

            try {
                switch ($Computer -eq $env:ComputerName) {
                    $true {
                        $Result['IsClientAlwaysOnInternet'] = $IsClientAlwaysOnInternetScriptBlock.Invoke()
                    }
                    $false {
                        $Result['IsClientAlwaysOnInternet'] = Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                    }
                }
                [pscustomobject]$Result
            }
            catch {
                Write-Error "Failure to determine if the MEMCM client is set to always be on the internet for $Computer - $($_.Exception.Message)"
            }
        }
    }
}
#EndRegion '.\Public\Test-CCMIsClientAlwaysOnInternet.ps1' 72
#Region '.\Public\Test-CCMIsClientOnInternet.ps1' 0
function Test-CCMIsClientOnInternet {
    <#
        .SYNOPSIS
            Return the status of the MEMCM client being on the internet (CMG/IBCM)
        .DESCRIPTION
            This function will invoke the IsClientOnInternet of the MEMCM Client.
             This is done using the Microsoft.SMS.Client COM Object.
        .PARAMETER ComputerName
            Provides computer names to return IsClientOnInternet setting info from
        .PARAMETER PSSession
            Provides PSSession to return IsClientOnInternet setting info from
        .EXAMPLE
            C:\PS> Test-CCMIsClientOnInternet
                Returns the status of the local computer having IsClientOnInternet set
        .EXAMPLE
            C:\PS> Test-CCMIsClientOnInternet -ComputerName 'Workstation1234','Workstation4321'
                Returns the status of 'Workstation1234','Workstation4321' having IsIsClientOnInternet set
        .NOTES
            FileName:    Test-CCMIsClientOnInternet.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-29
            Updated:     2020-08-01
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param(
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [Alias('Session')]      
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession
    )
    begin {
        $IsClientOnInternetScriptBlock = {
            $Client = New-Object -ComObject Microsoft.SMS.Client
            [bool]$Client.IsClientOnInternet()
        }
        $invokeCommandSplat = @{
            ScriptBlock = $IsClientOnInternetScriptBlock
        }
    }
    process {
        foreach ($Connection in (Get-Variable -Name $PSCmdlet.ParameterSetName -ValueOnly)) {
            $getConnectionInfoSplat = @{
                $PSCmdlet.ParameterSetName = $Connection
                Prefer                     = 'PSSession'
            }
            $ConnectionInfo = Get-CCMConnection @getConnectionInfoSplat
            $Computer = $ConnectionInfo.ComputerName
            $connectionSplat = $ConnectionInfo.connectionSplat

            $Result = [ordered]@{ }
            $Result['ComputerName'] = $Computer

            try {
                switch ($Computer -eq $env:ComputerName) {
                    $true {
                        $Result['IsClientOnInternet'] = $IsClientOnInternetScriptBlock.Invoke()
                    }
                    $false {
                        $Result['IsClientOnInternet'] = Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                    }
                }
                [pscustomobject]$Result
            }
            catch {
                Write-Error "Failure to determine if the MEMCM client is set to always be on the internet for $Computer - $($_.Exception.Message)"
            }
        }
    }
}
#EndRegion '.\Public\Test-CCMIsClientOnInternet.ps1' 72
#Region '.\Public\Test-CCMIsWindowAvailableNow.ps1' 0
function Test-CCMIsWindowAvailableNow {
    <#
        .SYNOPSIS
            Determine if a window is available now for the provided runtime and MWType
        .DESCRIPTION
            This function uses the IsWindowAvailableNow method of the CCM_ServiceWindowManager CIM class. It will allow you to
            determine if a deployment will run based on your input parameters.

            It also will determine your client settings for software updates to appropriately fall back to an 'All Deployment Service Window'
            according to both your settings, and whether a 'Software Update Service Window' is available
        .PARAMETER MWType
            Specifies the types of MW you want information for. Defaults to 'Software Update Service Window'. Valid options are below
                'All Deployment Service Window',
                'Program Service Window',
                'Reboot Required Service Window',
                'Software Update Service Window',
                'Task Sequences Service Window',
                'Corresponds to non-working hours'
        .PARAMETER MaxRunTime
            The max run time (in seconds) that will be passed to the IsWindowAvailableNow method. This is defined for the
            applications, programs, and updates you deploy. For software updates, you would want the cumulative
            max run time of all updates in a SUG.
        .PARAMETER CimSession
            Provides CimSession to gather Maintenance Window information info from
        .PARAMETER ComputerName
            Provides computer names to gather Maintenance Window information info from
        .PARAMETER PSSession
            Provides PSSession to gather Maintenance Window information info from
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the 
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then 
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to. 
        .EXAMPLE
            C:\PS> Test-CCMIsWindowAvailableNow
                Return information about the default MWType of 'Software Update Service Window' with a runtime of 0, and fallback
                based on client settings and 'Software Update Service Window' availability.
        .EXAMPLE
            C:\PS> Test-CCMIsWindowAvailableNow -ComputerName 'Workstation1234','Workstation4321' -MWType 'Task Sequences Service Window' -MaxRunTime 3600
                Return information on whether a task sequence with a run time of 3600 seconds can currently run on 'Workstation1234','Workstation4321'
        .NOTES
            FileName:    Test-CCMIsWindowAvailableNow.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-29
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
        [parameter(Mandatory = $false)]
        [ValidateSet('All Deployment Service Window',
            'Program Service Window',
            'Reboot Required Service Window',
            'Software Update Service Window',
            'Task Sequences Service Window',
            'Corresponds to non-working hours')]
        [string[]]$MWType = 'Software Update Service Window',
        [Parameter(Mandatory = $false)]
        [int]$MaxRuntime,
        [Parameter(Mandatory = $false)]
        [bool]$FallbackToAllProgramsWindow,
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
        #region Create hashtable for mapping MW types
        $MW_Type = @{
            'All Deployment Service Window'    = 1
            'Program Service Window'           = 2
            'Reboot Required Service Window'   = 3
            'Software Update Service Window'   = 4
            'Task Sequences Service Window'    = 5
            'Corresponds to non-working hours' = 6
        }
        #endregion Create hashtable for mapping MW types

        $testInMWSplat = @{
            Namespace  = 'root\CCM\ClientSDK'
            ClassName  = 'CCM_ServiceWindowManager'
            MethodName = 'IsWindowAvailableNow'
            Arguments  = @{
                MaxRuntime = [uint32]$MaxRuntime
            }
        }
        $getCurrentWindowTimeLeft = @{
            Namespace  = 'root\CCM\ClientSDK'
            ClassName  = 'CCM_ServiceWindowManager'
            MethodName = 'GetCurrentWindowAvailableTime'
            Arguments  = @{ }
        }
        $getUpdateMWExistenceSplat = @{
            Namespace = 'root\CCM\ClientSDK'
            Query     = 'SELECT Duration FROM CCM_ServiceWindow WHERE Type = 4'
        }
        $getSoftwareUpdateFallbackSettingsSplat = @{
            Namespace = 'root\CCM\Policy\Machine\ActualConfig'
            Query     = 'SELECT ServiceWindowManagement FROM CCM_SoftwareUpdatesClientConfig'
        }
        $invokeCommandSplat = @{
            FunctionsToLoad = 'Test-CCMIsWindowAvailableNow', 'Get-CCMConnection'
        }

        $StringArgs = @(switch ($PSBoundParameters.Keys) {
                'MaxRuntime' {
                    [string]::Format('-MaxRuntime {0}', $MaxRuntime)
                }
                'FallbackToAllProgramsWindow' {
                    [string]::Format('-FallbackToAllProgramsWindow ${0}', $FallbackToAllProgramsWindow)
                }
            })
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

            try {
                switch ($Computer -eq $env:ComputerName) {
                    $true {
                        $HasUpdateMW = $null -ne (Get-CimInstance @getUpdateMWExistenceSplat @connectionSplat).Duration
                        $FallbackSetting = (Get-CimInstance @getSoftwareUpdateFallbackSettingsSplat @connectionSplat).ServiceWindowManagement

                        foreach ($MW in $MWType) {
                            $MWFallback = switch ($FallbackToAllProgramsWindow) {
                                $true {
                                    switch ($MWType) {
                                        'Software Update Service Window' {
                                            switch ($FallbackSetting -ne $FallbackToAllProgramsWindow) {
                                                $true {
                                                    Write-Warning 'Requested fallback setting does not match the computers fallback setting for software updates'
                                                }
                                            }
                                            switch ($HasUpdateMW) {
                                                $true {
                                                    $FallbackSetting -and $HasUpdateMW
                                                }
                                                $false {
                                                    $true
                                                }
                                            }
                                        }
                                        default {
                                            $FallbackToAllProgramsWindow
                                        }
                                    }
                                }
                                $false {
                                    switch ($MWType) {
                                        'Software Update Service Window' {
                                            switch ($HasUpdateMW) {
                                                $true {
                                                    $FallbackSetting -and $HasUpdateMW
                                                }
                                                $false {
                                                    $true
                                                }
                                            }
                                        }
                                        default {
                                            $false
                                        }
                                    }
                                }
                            }
                            $testInMWSplat['Arguments']['FallbackToAllProgramsWindow'] = [bool]$MWFallback
                            $testInMWSplat['Arguments']['ServiceWindowType'] = [uint32]$MW_Type[$MW]
                            $CanProgramRunNow = Invoke-CimMethod @testInMWSplat @connectionSplat
                            if ($CanProgramRunNow -is [Object]) {
                                $getCurrentWindowTimeLeft['Arguments']['FallbackToAllProgramsWindow'] = [bool]$MWFallback
                                $getCurrentWindowTimeLeft['Arguments']['ServiceWindowType'] = [uint32]$MW_Type[$MW]
                                $TimeLeft = Invoke-CimMethod @getCurrentWindowTimeLeft @connectionSplat
                                $TimeLeftTimeSpan = New-TimeSpan -Seconds $TimeLeft.WindowAvailableTime
                                $Result['MaintenanceWindowType'] = $MW
                                $Result['CanProgramRunNow'] = $CanProgramRunNow.CanProgramRunNow
                                $Result['FallbackToAllProgramsWindow'] = $MWFallback
                                $Result['MaxRunTime'] = $MaxRuntime
                                $Result['WindowAvailableTime'] = [string]::Format('{0} day(s) {1} hour(s) {2} minute(s) {3} second(s)', $TimeLeftTimeSpan.Days, $TimeLeftTimeSpan.Hours, $TimeLeftTimeSpan.Minutes, $TimeLeftTimeSpan.Seconds)
                                [pscustomobject]$Result
                            }
                        }
                    }
                    $false {
                        $ScriptBlock = [string]::Format('Test-CCMIsWindowAvailableNow {0} {1}', [string]::Join(' ', $StringArgs), [string]::Format("-MWType '{0}'", [string]::Join("', '", $MWType)))
                        $invokeCommandSplat['ScriptBlock'] = [scriptblock]::Create($ScriptBlock)
                        Invoke-CCMCommand @invokeCommandSplat @connectionSplat
                    }
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
#EndRegion '.\Public\Test-CCMIsWindowAvailableNow.ps1' 218
#Region '.\Public\Test-CCMStaleLog.ps1' 0
Function Test-CCMStaleLog {
    <#
        .SYNOPSIS
            Returns a boolean based on whether a log file has been written to in the timeframe specified
        .DESCRIPTION
            This function is used to check the LastWriteTime property of a specified file. It will be compared to
            the *Stale parameters. Note that logs are assumed to be under the MEMCM Log directory. Note that
            this function uses the CIM_DataFile so that SMB is NOT needed. Get-CimInstance is able to query for
            file information.
        .PARAMETER LogFileName
            Name of the log file under the CCM\Logs directory to check. The full path for the MEMCM logs
            will be automatically identified. The .log extension is optional.
        .PARAMETER DaysStale
            Number of days of inactivity that you would consider the specified log stale.
        .PARAMETER HoursStale
            Number of days of inactivity that you would consider the specified log stale.
        .PARAMETER MinutesStale
            Number of minutes of inactivity that you would consider the specified log stale.
        .PARAMETER DisableCCMSetupFallback
            Disable the CCMSetup fallback check - details below.

            When the desired log file is not found, then the last modified timestamp for the CCMSetup log is checked.
            When the CCMSetup file has activity within the last 24 hours, then we assume that, even though our desired
            log file was not found, it isn't stale because the MEMCM client is recently installed or repaired.
            If the CCMSetup is found, and has no activity, or is just not found, then we assume the desired
            log is 'stale.' This additional check can be disabled with this switch parameter.
        .PARAMETER CimSession
            CimSessions to check the stale log on.
        .PARAMETER ComputerName
            Computer Names to check the stale log on.
        .PARAMETER PSSession
            PSSessions to check the stale log on.
        .PARAMETER ConnectionPreference
                Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
                is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
                when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
                pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
                specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
                falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
                the ComputerName parameter is passed to.
        .EXAMPLE
            C:\PS> Test-CCMStaleLog -LogFileName ccmexec -DaysStale 2
                Check if the ccmexec log file has been written to within the last 2 days on the local computer
        .EXAMPLE
            C:\PS> Test-CCMStaleLog -LogFileName AppDiscovery.log -DaysStale 7 -ComputerName Workstation123
                Check if the AppDiscovery.log file has been written to within the last 7 days on Workstation123
        .NOTES
            FileName:    Test-CCMStaleLog.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-25
            Updated:     2020-02-27
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$LogFileName,
        [Parameter(Mandatory = $false)]
        [int]$DaysStale,
        [Parameter(Mandatory = $false)]
        [int]$HoursStale,
        [Parameter(Mandatory = $false)]
        [int]$MinutesStale,
        [Parameter(Mandatory = $false)]
        [switch]$DisableCCMSetupFallback,
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
        $getRequestedLogInfoSplat = @{ }

        $TimeSpanSplat = @{ }
        switch ($PSBoundParameters.Keys) {
            'DaysStale' {
                $TimeSpanSplat['Days'] = $DaysStale
            }
            'HoursStale' {
                $TimeSpanSplat['Hours'] = $HoursStale
            }
            'MinutesStale' {
                $TimeSpanSplat['Minutes'] = $MinutesStale
            }
        }
        $StaleTimeframe = New-TimeSpan @TimeSpanSplat

        switch ($LogFileName.EndsWith('.log')) {
            $false {
                $LogFileName = [string]::Format('{0}.log', $LogFileName)
            }
        }

        $MEMCMClientInstallLog = "$env:windir\ccmsetup\Logs\ccmsetup.log"
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
            $Result['LogFileName'] = $LogFileName
            $Result['LogLastWriteTime'] = $null
            $Result['LogStale'] = $null
            $Result['CCMSetupLastWriteTime'] = $null
            $CCMLogDirectory = (Get-CCMLoggingConfiguration @connectionSplat).LogDirectory
            $LogFullPath = [string]::Join('\', $CCMLogDirectory, $LogFileName)

            Write-Verbose $([string]::Format('Checking {0} for activity', $LogFullPath))

            $getRequestedLogInfoSplat['Query'] = [string]::Format('SELECT Readable, LastModified FROM CIM_DataFile WHERE Name = "{0}" OR Name = "{1}"', ($LogFullPath -replace "\\", "\\"), ($MEMCMClientInstallLog -replace "\\", "\\"))
            # 'Poke' the log by querying it once. Log files sometimes do not show an accurate LastModified time until they are accessed
            $null = switch ($Computer -eq $env:ComputerName) {
                $true {
                    Get-CimInstance @getRequestedLogInfoSplat @connectionSplat
                }
                $false {
                    Get-CCMCimInstance @getRequestedLogInfoSplat @connectionSplat
                }
            }
            $RequestedLogInfo = switch ($Computer -eq $env:ComputerName) {
                $true {
                    Get-CimInstance @getRequestedLogInfoSplat @connectionSplat
                }
                $false {
                    Get-CCMCimInstance @getRequestedLogInfoSplat @connectionSplat
                }
            }
            $RequestedLog = $RequestedLogInfo.Where({ $_.Name -eq $LogFullPath})
            $MEMCMSetupLog = $RequestedLogInfo.Where({ $_.Name -eq $MEMCMClientInstallLog})
            if ($null -ne $MEMCMSetupLog) {
                $Result['CCMSetupLastWriteTime'] = ([datetime]$dtmMEMCMClientInstallLogDate = $MEMCMSetupLog.LastModified)
            }
            if ($null -ne $RequestedLog) {
                $Result['LogLastWriteTime'] = ([datetime]$LogLastWriteTime = $RequestedLog.LastModified)
                $LastWriteDiff = New-TimeSpan -Start $LogLastWriteTime -End (Get-Date -format yyyy-MM-dd)
                if ($LastWriteDiff -gt $StaleTimeframe) {
                    Write-Verbose $([string]::Format('{0} is not active', $LogFullPath))
                    Write-Verbose $([string]::Format('{0} last date modified is {1}', $LogFullPath, $LogDate))
                    Write-Verbose $([string]::Format("Current Date and Time is {0}", (Get-Date)))
                    $LogStale = $true
                }
                else {
                    Write-Verbose $([string]::Format('{0}.log is active', $LogFullPath))
                    $LogStale = $false
                }
            }
            elseif (-not $DisableCCMSetupFallback.IsPresent) {
                Write-Warning $([string]::Format('{0} not found; checking for recent ccmsetup activity', $LogFullPath))
                if ($null -ne $MEMCMClientInstallLogInfo) {
                    [int]$ClientInstallHours = (New-TimeSpan -Start $dtmMEMCMClientInstallLogDate -End (Get-Date)).TotalHours
                    if ($ClientInstallHours -lt 24) {
                        Write-Warning 'CCMSetup activity detected within last 24 hours - marking log as not stale'
                        $LogStale = $false
                    }
                    else {
                        Write-Warning 'CCMSetup activity not detected within last 24 hours - marking log as stale'
                        $LogStale = $true
                    }
                }
                else {
                    Write-Warning $([string]::Format('CCMSetup.log not found in {0} - marking log as stale', $MEMCMClientInstallLog))
                    $LogStale = $true
                }
            }
            else {
                Write-Warning $([string]::Format('{0} not found', $LogFullPath))
                $LogStale = 'File Not Found'
            }
            $Result['LogStale'] = $LogStale
            [pscustomobject]$Result
        }
    }
}
#EndRegion '.\Public\Test-CCMStaleLog.ps1' 192
#Region '.\Public\Write-CCMLogEntry.ps1' 0
Function Write-CCMLogEntry {
    <#
        .SYNOPSIS
            Write to a log file in the CMTrace Format
        .DESCRIPTION
            The function is used to write to a log file in a CMTrace compatible format. This ensures that CMTrace or OneTrace can parse the log
                and provide data in a familiar format.
        .PARAMETER Value
            String to be added it to the log file as the message, or value
        .PARAMETER Severity
            Severity for the log entry. You can either enter the string values of Informational, Warning, or Error, or alternatively
                you can enter 1 for Informational, 2 for Warning, and 3 for Error.
        .PARAMETER Component
            Stage that the log entry is occurring in, log refers to as 'component.'
        .PARAMETER FileName
            Name of the log file that the entry will written to - note this should not be the full path.
        .PARAMETER Folder
            Path to the folder where the log will be stored.
        .PARAMETER Bias
            Set timezone Bias to ensure timestamps are accurate. This defaults to the local machines bias, but one can be provided. It can be
                helpful to gather the bias once, and store it in a variable that is passed to this parameter as part of a splat, or $PSDefaultParameterValues
        .PARAMETER MaxLogFileSize
            Maximum size of log file before it rolls over. Set to 0 to disable log rotation. Defaults to 5MB
        .PARAMETER LogsToKeep
            Maximum number of rotated log files to keep. Set to 0 for unlimited rotated log files. Defaults to 0.
        .EXAMPLE
            C:\PS> Write-CCMLogEntry -Value 'Testing Function' -Component 'Test Script' -FileName 'LogTest.Log' -Folder 'c:\temp'
                Write out 'Testing Function' to the c:\temp\LogTest.Log file in a CMTrace format, noting 'Test Script' as the component.
        .NOTES
            FileName:    Write-CCMLogEntry.ps1
            Author:      Cody Mathis, Adam Cook
            Contact:     @CodyMathis123, @codaamok
            Created:     2020-01-23
            Updated:     2020-07-18
    #>
    param (
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Message', 'ToLog')]
        [string[]]$Value,
        [parameter(Mandatory = $false)]
        [ValidateSet('Informational', 'Warning', 'Error', '1', '2', '3')]
        [string]$Severity = 'Informational',
        [parameter(Mandatory = $false)]
        [string]$Component,
        [parameter(Mandatory = $true)]
        [string]$FileName,
        [parameter(Mandatory = $true)]
        [string]$Folder,
        [parameter(Mandatory = $false)]
        [int]$Bias = (Get-CimInstance -Query "SELECT Bias FROM Win32_TimeZone").Bias,
        [parameter(Mandatory = $false)]
        [int]$MaxLogFileSize = 5MB,
        [parameter(Mandatory = $false)]
        [int]$LogsToKeep = 0
    )
    begin {
        # Convert Severity to integer log level
        [int]$LogLevel = switch ($Severity) {
            Informational {
                1
            }
            Warning {
                2
            }
            Error {
                3
            }
            default {
                $PSItem
            }
        }

        # Determine log file location
        $LogFilePath = Join-Path -Path $Folder -ChildPath $FileName

        #region log rollover check if $MaxLogFileSize is greater than 0
        switch (([System.IO.FileInfo]$LogFilePath).Exists -and $MaxLogFileSize -gt 0) {
            $true {
                #region rename current file if $MaxLogFileSize exceeded, respecting $LogsToKeep
                switch (([System.IO.FileInfo]$LogFilePath).Length -ge $MaxLogFileSize) {
                    $true {
                        # Get log file name without extension
                        $LogFileNameWithoutExt = $FileName -replace ([System.IO.Path]::GetExtension($FileName))

                        # Get already rolled over logs
                        $AllLogs = Get-ChildItem -Path $Folder -Name "$($LogFileNameWithoutExt)_*" -File

                        # Sort them numerically (so the oldest is first in the list)
                        $AllLogs = Sort-Object -InputObject $AllLogs -Descending -Property { $_ -replace '_\d+\.lo_$' }, { [int]($_ -replace '^.+\d_|\.lo_$') } -ErrorAction Ignore

                        foreach ($Log in $AllLogs) {
                            # Get log number
                            $LogFileNumber = [int][Regex]::Matches($Log, "_([0-9]+)\.lo_$").Groups[1].Value
                            switch (($LogFileNumber -eq $LogsToKeep) -and ($LogsToKeep -ne 0)) {
                                $true {
                                    # Delete log if it breaches $LogsToKeep parameter value
                                    [System.IO.File]::Delete("$($Folder)\$($Log)")
                                }
                                $false {
                                    # Rename log to +1
                                    $NewFileName = $Log -replace "_([0-9]+)\.lo_$", "_$($LogFileNumber+1).lo_"
                                    [System.IO.File]::Copy("$($Folder)\$($Log)", "$($Folder)\$($NewFileName)", $true)
                                }
                            }
                        }

                        # Copy main log to _1.lo_
                        [System.IO.File]::Copy($LogFilePath, "$($Folder)\$($LogFileNameWithoutExt)_1.lo_", $true)

                        # Blank the main log
                        $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $LogFilePath, $false
                        $StreamWriter.Close()
                    }
                }
                #endregion rename current file if $MaxLogFileSize exceeded, respecting $LogsToKeep
            }
        }
        #endregion log rollover check if $MaxLogFileSize is greater than 0

        # Construct date for log entry
        $Date = (Get-Date -Format 'MM-dd-yyyy')

        # Construct context for log entry
        $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
    }
    process {
        foreach ($MSG in $Value) {
            #region construct time stamp for log entry based on $Bias and current time
            $Time = switch -regex ($Bias) {
                '-' {
                    [string]::Concat($(Get-Date -Format 'HH:mm:ss.fff'), $Bias)
                }
                Default {
                    [string]::Concat($(Get-Date -Format 'HH:mm:ss.fff'), '+', $Bias)
                }
            }
            #endregion construct time stamp for log entry based on $Bias and current time

            #region construct the log entry according to CMTrace format
            $LogText = [string]::Format('<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="{4}" type="{5}" thread="{6}" file="">', $MSG, $Time, $Date, $Component, $Context, $LogLevel, $PID)
            #endregion construct the log entry according to CMTrace format

            #region add value to log file
            try {
                $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $LogFilePath, 'Append'
                $StreamWriter.WriteLine($LogText)
                $StreamWriter.Close()
            }
            catch [System.Exception] {
                Write-Warning -Message "Unable to append log entry to $FileName file. Error message: $($_.Exception.Message)"
            }
            #endregion add value to log file
        }
    }
}
#EndRegion '.\Public\Write-CCMLogEntry.ps1' 155
