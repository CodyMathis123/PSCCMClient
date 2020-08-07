Function ConvertFrom-CCMLogFile {
    <#
        .SYNOPSIS
            Parse Configuration Manager format logs
        .DESCRIPTION
            This function is used to take Configuration Manager formatted logs and turn them into a CMLogEntry so that it can be
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
            PS C:\> ConvertFrom-CCMLogFile -Path 'c:\windows\ccm\logs\ccmexec.log'
                Returns the CCMExec.log as a CMLogEntry
        .EXAMPLE
            PS C:\> ConvertFrom-CCMLogFile -Path 'c:\windows\ccm\logs\AppEnforce.log', 'c:\windows\ccm\logs\AppDiscovery.log' | Sort-Object -Property Timestamp
                Returns the AppEnforce.log and AppDiscovery.log as a CMLogEntry sorted by Timestamp
        .EXAMPLE
            PS C:\> ConvertFrom-CCMLogFile -Path 'c:\windows\ccm\logs\smstslog.log' -ParseSMSTS
                Returns all the actions that ran according to the SMSTSLog provided
        .EXAMPLE
            PS C:\> ConvertFrom-CCMLogFile -Path 'c:\windows\ccm\logs\cas.log' -Filter "Successfully created download  request \{(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}\} for content (\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}\.\d+"
                Return all log entires from the CAS.Log which pertain creating download requests for updates
        .EXAMPLE
            PS C:\> ConvertFrom-CCMLogFile -Path C:\windows\ccm\logs\AppDiscovery.log -TimestampGreaterThan (Get-Date).AddDays(-1)
                Returns all log entries from the AppDiscovery.log file which have a timestamp within the last day
        .OUTPUTS
            [CMLogEntry[]]
        .NOTES
            I've done my best to test this against various MEMCM log files. They are all generally 'formatted' the same, but do have some
            variance. I had to also balance speed and parsing.

            With that said, it can still parse a typical MEMCM log VERY quickly. Smaller logs are parsed in milliseconds in my testing.
            Rolled over logs that are 5mb can be parsed in a couple seconds or less. The -Filter option provides a great deal of
            flexibility and speed as well.

                FileName: ConvertFrom-CCMLogFile.ps1
                Author:   Cody Mathis
                Contact:  @CodyMathis123
                Created:  2019-09-19
                Updated:  2020-08-07
    #>
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    [OutputType([CMLogEntry[]])]
    [Alias('Get-CCMLogFile')]
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
        [Alias('Type')]
        [string[]]$Severity = @('None', 'Informational', 'Warning', 'Error'),
        [Parameter(Mandatory = $false)]
        [datetime]$TimestampGreaterThan = [datetime]::MinValue,
        [Parameter(Mandatory = $false)]
        [datetime]$TimestampLessThan = [datetime]::MaxValue
    )
    begin {
        #region If either timestamp filter parameter is specified we will validate the timestamp
        $CheckTimestampFilter = $PSBoundParameters.ContainsKey('TimestampGreaterThan') -or $PSBoundParameters.ContainsKey('TimestampLessThan')
        #endregion If either timestamp filter parameter is specified we will validate the timestamp
    }
    process {
        foreach ($LogFile in $Path) {
            #region ingest log file with StreamReader. Quick, and prevents locks
            $File = [System.IO.File]::Open($LogFile, 'Open', 'Read', 'ReadWrite')
            $StreamReader = New-Object System.IO.StreamReader($File)
            [string]$LogFileRaw = $StreamReader.ReadToEnd()
            $StreamReader.Close()
            $StreamReader.Dispose()
            $File.Close()
            $File.Dispose()
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

                            $LogLine = [CMLogEntry]::New($Message
                                , ($Type = [Severity]$LogLineSubArray[9])
                                , $LogLineSubArray[5]
                                , $LogLineSubArray[11])

                            #region parse log based on severity, which defaults to any severity if the parameter is not specified
                            switch ($Severity) {
                                ($Type) {
                                    switch ($PSCmdlet.ParameterSetName) {
                                        #region if ParseSMSTS specified, check message for known string for SMS step success / failure
                                        ParseSMSTS {
                                            switch -regex ($Message) {
                                                'win32 code 0|failed to run the action' {
                                                    $LogLine.ResolveTimestamp($LogLineSubArray, [CMLogType]::FullCMTrace)
                                                    switch ($CheckTimestampFilter) {
                                                        $true {
                                                            switch ($LogLine.TestTimestampFilter($TimestampGreaterThan, $TimestampLessThan)) {
                                                                $true {
                                                                    $LogLine
                                                                }
                                                            }
                                                        }
                                                        $false {
                                                            $LogLine
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
                                                    $LogLine.ResolveTimestamp($LogLineSubArray, [CMLogType]::FullCMTrace)
                                                    switch ($CheckTimestampFilter) {
                                                        $true {
                                                            switch ($LogLine.TestTimestampFilter($TimestampGreaterThan, $TimestampLessThan)) {
                                                                $true {
                                                                    $LogLine
                                                                }
                                                            }
                                                        }
                                                        $false {
                                                            $LogLine
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
                                            $LogLine.ResolveTimestamp($LogLineSubArray, [CMLogType]::FullCMTrace)
                                            switch ($CheckTimestampFilter) {
                                                $true {
                                                    switch ($LogLine.TestTimestampFilter($TimestampGreaterThan, $TimestampLessThan)) {
                                                        $true {
                                                            $LogLine
                                                        }
                                                    }
                                                }
                                                $false {
                                                    $LogLine
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
                            #endregion parse log based on severity, which defaults to any severity if the parameter is not specified
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
                                    $LogLine = [CMLogEntry]::New($Message
                                        , [Severity]0
                                        , $LogLineSubArray[0].Trim()
                                        , ($LogLineSubArray[2].Split([char]32, [System.StringSplitOptions]::RemoveEmptyEntries))[0].Substring(7))

                                    #region parse the log based on our Parameter Set Name
                                    switch ($PSCmdlet.ParameterSetName) {
                                        #region if CustomerFilter is specified, check message against the string as a regex match
                                        CustomFilter {
                                            switch -regex ($Message) {
                                                $Filter {
                                                    $LogLine.ResolveTimestamp($LogLineSubArray, [CMLogType]::SimpleCMTrace)
                                                    switch ($CheckTimestampFilter) {
                                                        $true {
                                                            switch ($LogLine.TestTimestampFilter($TimestampGreaterThan, $TimestampLessThan)) {
                                                                $true {
                                                                    $LogLine
                                                                }
                                                            }
                                                        }
                                                        $false {
                                                            $LogLine
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
                                            $LogLine.ResolveTimestamp($LogLineSubArray, [CMLogType]::SimpleCMTrace)
                                            switch ($CheckTimestampFilter) {
                                                $true {
                                                    switch ($LogLine.TestTimestampFilter($TimestampGreaterThan, $TimestampLessThan)) {
                                                        $true {
                                                            $LogLine
                                                        }
                                                    }
                                                }
                                                $false {
                                                    $LogLine
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