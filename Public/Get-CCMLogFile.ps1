Function Get-CCMLogFile {
    <#
    .SYNOPSIS
        Parse Configuration Manager format logs
    .DESCRIPTION
        This function is used to take Configuration Manager formatted logs and turn them into a PSCustomObject so that it can be
        searched and manipulated easily with PowerShell
    .PARAMETER LogFilePath
        Path to the log file(s) you would like to parse.
    .PARAMETER ParseSMSTS
        Only pulls out the TS actions. This is for parsing an SMSTSLog specifically
    .EXAMPLE
        PS C:\> Get-CCMLogFile -LogFilePath 'c:\windows\ccm\logs\ccmexec.log'
        Returns the CCMExec.log as a PSCustomObject
    .EXAMPLE
        PS C:\> Get-CCMLogFile -LogFilePath 'c:\windows\ccm\logs\AppEnforce.log', 'c:\windows\ccm\logs\AppDiscovery.log'
        Returns the AppEnforce.log and the AppDiscovery.log as a PSCustomObject
    .EXAMPLE 
        PS C:\> Get-CCMLogFile -LogFilePath 'c:\windows\ccm\logs\smstslog.log' -ParseSMSTS
        Returns all the actions that ran according to the SMSTSLog provided
    .OUTPUTS
        [pscustomobject]
    .NOTES
        I've done my best to test this against various SCCM log files. They are all generally 'formatted' the same, but do have some
        variance. I had to also balance speed and parsing.

        With that said, it can still parse a typical SCCM log VERY quickly. Smaller logs are parsed in milliseconds in my testing.
        Rolled over logs that are 5mb can be parsed in a couple seconds or less.

            FileName: Get-CCMLogFile.ps1
            Author:   Cody Mathis
            Contact:  @CodyMathis123
            Created:  2019-9-19
            Updated:  2019-01-01
    #>
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)]
        [Alias('Fullname')]
        [string[]]$LogFilePath,
        [Parameter(Mandatory = $false)]
        [switch]$ParseSMSTS
    )
    begin {
        try {
            Add-Type -ErrorAction SilentlyContinue -TypeDefinition @"
            public enum Severity
            {
                None,
                Informational,
                Warning,
                Error
            }
"@
        }
        catch {
            Write-Debug "Type Severity already exists"
        }

        function Get-TimeStampFromLogLine {
            <#
            .SYNOPSIS
                Parses a datetime object from an SCCM log line 
            .DESCRIPTION
                This will return a datetime object if it is passed the part of an SCCM log line that contains the date and time
            .PARAMETER LogLinSubArray
                A log line sub array which is everything past "]LOG]!><" split by '"'
                For Example:
                    time=
                    09:58:50.301+300
                    date=
                    11-18-2019
                    component=
                    TSManager
                    context=

                    type=
                    1
                    thread=
                    2164
                    file=
                    tsxml.cpp:898

                    such that the [3] and [1] are the date and time respectively
            .EXAMPLE
                PS C:\> Get-TimeStampFromLogLine -LogLineSubArray $LogLineSubArray
                return datetime object from the log line that was split into a subarray
            #>
            param (
                [Parameter(Mandatory = $true)]
                [array]$LogLineSubArray
            )
            $DateString = $LogLineSubArray[3]
            $DateStringArray = $DateString -split "-"

            $MonthParser = $DateStringArray[0] -replace '\d', 'M'
            $DayParser = $DateStringArray[1] -replace '\d', 'd'

            $DateTimeFormat = [string]::Format('{0}-{1}-yyyyHH:mm:ss.fff', $MonthParser, $DayParser)
            $TimeString = ($LogLineSubArray[1]).Split("+|-")[0].ToString().Substring(0, 12)
            $DateTimeString = [string]::Format('{0}{1}', $DateString, $TimeString)
            [datetime]::ParseExact($DateTimeString, $DateTimeFormat, $null)
        }
    }
    process {
        Foreach ($LogFile in $LogFilePath) {
            #region ingest log file with StreamReader. Quick, and prevents locks
            $File = [System.IO.File]::Open($LogFile, 'Open', 'Read', 'ReadWrite')
            $StreamReader = New-Object System.IO.StreamReader($File)
            [string]$LogFileRaw = $StreamReader.ReadToEnd()
            $StreamReader.Close()
            $File.Close()
            #endregion ingest log file with StreamReader. Quick, and prevents locks

            #region perform a regex match to determine the 'type' of log we are working with and parse appropriately
            switch ($true) {
                #region parse a 'typical' SCCM log
                (([Regex]::Match($LogFileRaw, "LOG\[(.*?)\]LOG(.*?)time(.*?)date")).Success) {
                    # split on what we know is a line beginning
                    switch -regex ($LogFileRaw -split "<!\[LOG\[") {
                        '^\s*$' {
                            # ignore empty lines
                            continue
                        }
                        default {
                            <#
                                split Log line into an array on what we know is the end of the message section
                                first item contains the message which can be parsed
                                second item contains all the information about the message/line (ie. type, component, datetime, thread) which can be parsed
                            #>
                            $LogLineArray = $PSItem -split "]LOG]!><"

                            # Strip the log message out of our first array index
                            $Message = $LogLineArray[0]

                            # Split LogLineArray into a a sub array based on double quotes to pull log line information
                            $LogLineSubArray = $LogLineArray[1] -split '"'

                            $LogLine = [System.Collections.Specialized.OrderedDictionary]::new()
                            # Rebuild the LogLine into a hash table
                            $LogLine['Message'] = $Message
                            $LogLine['Type'] = [Severity]$LogLineSubArray[9]
                            $LogLine['Component'] = $LogLineSubArray[5]
                            $LogLine['Thread'] = $LogLineSubArray[11]
                            
                            # if we are Parsing SMSTS then we will only pull out messages that match 'win32 code 0|failed to run the action'
                            switch ($ParseSMSTS.IsPresent) {
                                $true {
                                    switch -regex ($Message) {
                                        'win32 code 0|failed to run the action' {
                                            $LogLine.TimeStamp = Get-TimeStampFromLogLine -LogLineSubArray $LogLineSubArray
                                            [pscustomobject]$LogLine
                                        }
                                        default {
                                            continue
                                        }
                                    }
                                }
                                $false {
                                    $LogLine['TimeStamp'] = Get-TimeStampFromLogLine -LogLineSubArray $LogLineSubArray
                                    [pscustomobject]$LogLine
                                }
                            }
                        }
                    }
                }
                #endregion parse a 'typical' SCCM log

                #region parse a 'simple' SCCM log, usually found on site systems
                (([Regex]::Match($LogFileRaw, '\$\$\<(.*?)\>\<thread=')).Success) {
                    switch -regex ($LogFileRaw -split [System.Environment]::NewLine) {
                        '^\s*$' {
                            # ignore empty lines
                            continue
                        }
                        default {
                            <#
                                split Log line into an array
                                first item contains the message which can be parsed
                                second item contains all the information about the message/line (ie. type, component, timestamp, thread) which can be parsed
                            #>
                            $LogLineArray = $PSItem -split '\$\$<'

                            # Strip the log message out of our first array index
                            $Message = $LogLineArray[0]

                            # Split LogLineArray into a a sub array based on double quotes to pull log line information
                            $LogLineSubArray = $LogLineArray[1] -split '><'

                            switch -regex ($Message) {
                                '^\s*$' {
                                    # ignore empty messages
                                    continue
                                }
                                default {
                                    $LogLine = [System.Collections.Specialized.OrderedDictionary]::new()
                                    # Rebuild the LogLine into a hash table
                                    $LogLine['Message'] = $Message
                                    $LogLine['Type'] = [Severity]0
                                    $LogLine['Component'] = $LogLineSubArray[0].Trim()
                                    $LogLine['Thread'] = ($LogLineSubArray[2] -split " ")[0].Substring(7)

                                    #region determine timestamp for log line
                                    $DateTimeString = $LogLineSubArray[1]
                                    $DateTimeStringArray = $DateTimeString -split " "
                                    $DateString = $DateTimeStringArray[0]
                                    $DateStringArray = $DateString -split "-"

                                    $MonthParser = $DateStringArray[0] -replace '\d', 'M'
                                    $DayParser = $DateStringArray[1] -replace '\d', 'd'

                                    $DateTimeFormat = [string]::Format('{0}-{1}-yyyy HH:mm:ss.fff', $MonthParser, $DayParser)
                                    $TimeString = $DateTimeStringArray[1].ToString().Substring(0, 12)
                                    $DateTimeString = [string]::Format('{0} {1}', $DateString, $TimeString)
                                    $LogLine['TimeStamp'] = [datetime]::ParseExact($DateTimeString, $DateTimeFormat, $null)
                                    #endregion determine timestamp for log line

                                    [pscustomobject]$LogLine
                                }
                            }
                        }
                    }
                }
                #endregion parse a 'simple' SCCM log, usually found on site systems
            }
            #endregion perform a regex match to determine the 'type' of log we are working with and parse appropriately
        }
    }
}
