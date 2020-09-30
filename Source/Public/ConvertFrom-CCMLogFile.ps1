Function ConvertFrom-CCMLogFile {
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
                            $UnparsedLogLine = $PSItem
                            $Parse = $false
                            $Parse = switch ($PSCmdlet.ParameterSetName) {
                                #region if ParseSMSTS specified, check logline for known string for SMS step success / failure
                                ParseSMSTS {
                                    switch -regex ($UnparsedLogLine) {
                                        'win32 code 0|failed to run the action' {
                                            $true
                                        }
                                    }
                                }
                                #endregion if ParseSMSTS specified, check logline for known string for SMS step success / failure

                                #region if CustomerFilter is specified, check logline against the string as a regex match
                                CustomFilter {
                                    switch -regex ($UnparsedLogLine) {
                                        $Filter {
                                            $true
                                        }
                                    }
                                }
                                #endregion if CustomerFilter is specified, check logline against the string as a regex match

                                #region if no filtering is provided then the we parse all loglines
                                default {
                                    $true
                                }
                                #endregion if no filtering is provided then the we parse all loglines
                            }

                            switch ($Parse) {
                                $true {
                                    <#
                                        split Log line into an array on what we know is the end of the message section
                                        first item contains the message which can be parsed
                                        second item contains all the information about the message/line (ie. type, component, datetime, thread) which can be parsed
                                    #>
                                    $LogLineArray = [regex]::Split($UnparsedLogLine, ']LOG]!><')

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
                                    }
                                    #endregion parse log based on severity, which defaults to any severity if the parameter is not specified
                                }
                            }
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
                            $UnparsedLogLine = $PSItem
                            $Parse = $false
                            $Parse = switch ($PSCmdlet.ParameterSetName) {
                                #region if CustomerFilter is specified, check logline against the string as a regex match
                                CustomFilter {
                                    switch -regex ($UnparsedLogLine) {
                                        $Filter {
                                            $true
                                        }
                                    }
                                }
                                #endregion if CustomerFilter is specified, check logline against the string as a regex match

                                #region if no filtering is provided then the we parse all loglines
                                default {
                                    $true
                                }
                                #endregion if no filtering is provided then the we parse all loglines
                            }
                            switch ($Parse) {
                                $true {
                                    <#
                                        split Log line into an array
                                        first item contains the message which can be parsed
                                        second item contains all the information about the message/line (ie. type, component, timestamp, thread) which can be parsed
                                    #>
                                    $LogLineArray = [regex]::Split($UnparsedLogLine, '\$\$<')

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
                                    }
                                }
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