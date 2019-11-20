Function ConvertFrom-CCMSchedule {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$ScheduleString
    )
    function Get-FancyDay {
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
    $MW = @{ }
    $Start = $Schedule.Substring(0, 8)
    $Recurrence = $Schedule.Substring(8, 8)
    switch ($Start) {
        '00012000' {

        }
        default {
            # Convert to binary string and pad left with 0 to ensure 32 character length
            $BStart = [Convert]::ToString([int64]"0x$Start".ToString(), 2).PadLeft(32, 48)

            # Collect timedata and ensure we pad left with 0 to ensure 2 character length
            [string]$StartMinute = ([Convert]::ToInt32($BStart.Substring(0, 6), 2).ToString()).PadLeft(2, 48)
            [string]$StartHour = ([Convert]::ToInt32($BStart.Substring(6, 5), 2).ToString()).PadLeft(2, 48)
            [string]$StartDay = ([Convert]::ToInt32($BStart.Substring(11, 5), 2).ToString()).PadLeft(2, 48)
            [string]$StartMonth = ([Convert]::ToInt32($BStart.Substring(16, 4), 2).ToString()).PadLeft(2, 48)
            [String]$StartYear = [Convert]::ToInt32($BStart.Substring(20, 6), 2) + 1970

            # set our StartString variable by formatting all our calculated datetime components
            $StartString = [string]::Format('{0}-{1}-{2} {3}:{4}:00', $StartYear, $StartMonth, $StartDay, $StartHour, $StartMinute)
            $StartDateTimeObject = $StartString | Get-Date
        }
    }
    # Convert to binary string and pad left with 0 to ensure 32 character length
    $BRec = [Convert]::ToString([int64]"0x$Recurrence".ToString(), 2).PadLeft(32, 48)

    [bool]$GMT = [Convert]::ToInt32($BRec.Substring(31, 1), 2)

    $DayDuration = 0
    $HourDuration = [Convert]::ToInt32($BRec.Substring(0, 5), 2)
    $MinuteDuration = [Convert]::ToInt32($BRec.Substring(5, 5), 2)
    If ($HourDuration -gt 24) {
        $h = $HourDuration % 24
        $DayDuration = ($HourDuration - $h) / 24
        $HourDuration = $h
    }

    $RecurType = [Convert]::ToInt32($BRec.Substring(10, 3), 2)

    Switch ($RecurType) {
        1 {
            $path = 'SMS_ST_NonRecurring'
            ##??
        }
        2 {
            $Type = 'SMS_ST_RecurInterval'
            $MinuteSpan = [Convert]::ToInt32($BRec.Substring(13, 6), 2)
            $HourSpan = [Convert]::ToInt32($BRec.Substring(19, 5), 2)
            $DaySpan = [Convert]::ToInt32($BRec.Substring(24, 5), 2)
            $Description = [string]::Format('Occurs every {0} days effective {1}', $DaySpan, $StartDateTimeObject)
        }
        3 {
            $Type = 'SMS_ST_RecurWeekly'
            $Day = [Convert]::ToInt32($BRec.Substring(13, 3), 2) - 1
            $WeekRecurrence = [Convert]::ToInt32($BRec.Substring(16, 3), 2)
            $Description = [string]::Format('Occurs every {0} weeks on {1} effective {2}', $WeekRecurrence, $([DayOfWeek]$Day), $StartDateTimeObject)
        }
        4 {
            $Type = 'SMS_ST_RecurMonthlyByWeekday'
            $Day = [Convert]::ToInt32($BRec.Substring(13, 3), 2) - 1
            $ForNumberOfMonths = [Convert]::ToInt32($BRec.Substring(16, 4), 2)
            $WeekOrder = [Convert]::ToInt32($BRec.Substring(20, 3), 2)
            $WeekRecurrence = switch ($WeekOrder) {
                0 {
                    'Last'
                }
                default {
                    $(Get-FancyDay -Day $WeekOrder)
                }
            }
            $Description = [string]::Format('Occurs the {0} {1} of every {2} months effective {3}', $WeekRecurrence, $([DayOfWeek]$Day), $ForNumberOfMonths, $StartDateTimeObject)
        }
        5 {
            $Type = 'SMS_ST_RecurMonthlyByDate'
            $MonthDay = [Convert]::ToInt32($BRec.Substring(13, 5), 2)
            $MonthRecurrence = switch ($MonthDay) {
                0 {
                    # [datetime]::DaysInMonth([datetime]::Today.Year, [datetime]::Today.Month)
                    'the last day'
                }
                default {
                    "day $PSItem"
                }
            }
            $ForNumberOfMonths = [Convert]::ToInt32($BRec.Substring(18, 4), 2)
            $Description = [string]::Format('Occurs {0} of every {1} months effective {2}', $MonthRecurrence, $ForNumberOfMonths, $StartDateTimeObject)
        }
        Default {
            Throw "Invalid type"
        }
    }

}