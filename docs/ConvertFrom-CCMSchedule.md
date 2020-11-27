---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# ConvertFrom-CCMSchedule

## SYNOPSIS
Convert Configuration Manager Schedule Strings

## SYNTAX

```
ConvertFrom-CCMSchedule [-ScheduleString] <String[]> [<CommonParameters>]
```

## DESCRIPTION
This function will take a Configuration Manager Schedule String and convert it into a readable object, including
the calculated description of the schedule

## EXAMPLES

### EXAMPLE 1
```
ConvertFrom-CCMSchedule -ScheduleString 1033BC7B10100010
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
```

## PARAMETERS

### -ScheduleString
Accepts an array of strings.
This should be a schedule string in the MEMCM format

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Schedules

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

This function was created to allow for converting MEMCM schedule strings without relying on the SDK / Site Server
It also happens to be a TON faster than the Convert-CMSchedule cmdlet and the CIM method on the site server

## RELATED LINKS
