Function ConvertFrom-CCMSchedule {
    <#
    .SYNOPSIS
        Convert Configuration Manager Schedule Strings
    .DESCRIPTION
        This function will take a Configuration Manager Schedule String and convert it into a readable object, including
        the calculated description of the schedule
    .PARAMETER ScheduleString
        Accepts an array of strings. This should be a schedule string in the SCCM format
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
        This function was created to allow for converting SCCM schedule strings without relying on the SDK / Site Server
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
            $MW = [System.Collections.Specialized.OrderedDictionary]::new()

            # the first 8 characters are the Start of the MW, while the last 8 characters are the recurrence schedule
            $Start = $Schedule.Substring(0, 8)
            $Recurrence = $Schedule.Substring(8, 8)

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
                    $StartDateTimeString = [string]::Format('{0}-{1}-{2} {3}:{4}:00', $StartYear, $StartMonth, $StartDay, $StartHour, $StartMinute)
                    $StartDateTimeObject = Get-Date -Date $StartDateTimeString
                }
            }
            # Convert to binary string and pad left with 0 to ensure 32 character length for consistent parsing
            $binaryRecurrence = [Convert]::ToString([int64]"0x$Recurrence".ToString(), 2).PadLeft(32, 48)

            [bool]$IsGMT = [Convert]::ToInt32($binaryRecurrence.Substring(31, 1), 2)

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
