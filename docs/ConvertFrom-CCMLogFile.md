---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# ConvertFrom-CCMLogFile

## SYNOPSIS
Parse Configuration Manager format logs

## SYNTAX

### __AllParameterSets (Default)
```
ConvertFrom-CCMLogFile -Path <String[]> [-Severity <String[]>] [-TimestampGreaterThan <DateTime>]
 [-TimestampLessThan <DateTime>] [<CommonParameters>]
```

### ParseSMSTS
```
ConvertFrom-CCMLogFile -Path <String[]> [-ParseSMSTS] [-Severity <String[]>] [-TimestampGreaterThan <DateTime>]
 [-TimestampLessThan <DateTime>] [<CommonParameters>]
```

### CustomFilter
```
ConvertFrom-CCMLogFile -Path <String[]> [-Filter <String>] [-Severity <String[]>]
 [-TimestampGreaterThan <DateTime>] [-TimestampLessThan <DateTime>] [<CommonParameters>]
```

## DESCRIPTION
This function is used to take Configuration Manager formatted logs and turn them into a CMLogEntry so that it can be
searched and manipulated easily with PowerShell

## EXAMPLES

### EXAMPLE 1
```
ConvertFrom-CCMLogFile -Path 'c:\windows\ccm\logs\ccmexec.log'
```
Returns the CCMExec.log as a CMLogEntry

### EXAMPLE 2
```
ConvertFrom-CCMLogFile -Path 'c:\windows\ccm\logs\AppEnforce.log', 'c:\windows\ccm\logs\AppDiscovery.log' | Sort-Object -Property Timestamp
```
Returns the AppEnforce.log and AppDiscovery.log as a CMLogEntry sorted by Timestamp

### EXAMPLE 3
```
ConvertFrom-CCMLogFile -Path 'c:\windows\ccm\logs\smstslog.log' -ParseSMSTS
```
Returns all the actions that ran according to the SMSTSLog provided

### EXAMPLE 4
```
ConvertFrom-CCMLogFile -Path 'c:\windows\ccm\logs\cas.log' -Filter "Successfully created download  request \{(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}\} for content (\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}\.\d+"
```
Return all log entires from the CAS.Log which pertain creating download requests for updates

### EXAMPLE 5
```
ConvertFrom-CCMLogFile -Path C:\windows\ccm\logs\AppDiscovery.log -TimestampGreaterThan (Get-Date).AddDays(-1)
```
Returns all log entries from the AppDiscovery.log file which have a timestamp within the last day

## PARAMETERS

### -Path
Path to the log file(s) you would like to parse.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Fullname, LogFilePath

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ParseSMSTS
Only pulls out the TS actions.
This is for parsing an SMSTSLog specifically

```yaml
Type: SwitchParameter
Parameter Sets: ParseSMSTS
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
A custom regex filter to use when reading in log lines

```yaml
Type: String
Parameter Sets: CustomFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Severity
A filter to return only messages of a particular severity.
By default, all severities are returned.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Type

Required: False
Position: Named
Default value: @('None', 'Informational', 'Warning', 'Error')
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimestampGreaterThan
A \[datetime\] object that will filter the returned log lines.
They will only be returned if they are greater than or
equal to the provided \[datetime\]

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: [datetime]::MinValue
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimestampLessThan
A \[datetime\] object that will filter the returned log lines.
They will only be returned if they are less than or
equal to the provided \[datetime\]

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: [datetime]::MaxValue
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [CMLogEntry[]]

## NOTES

I've done my best to test this against various MEMCM log files.
They are all generally 'formatted' the same, but do have some
variance.
I had to also balance speed and parsing.

With that said, it can still parse a typical MEMCM log VERY quickly.
Smaller logs are parsed in milliseconds in my testing.
Rolled over logs that are 5mb can be parsed in a couple seconds or less.
The -Filter option provides a great deal of
flexibility and speed as well.

**FileName**: ConvertFrom-CCMLogFile.ps1  
**Author**:   Cody Mathis  
**Contact**:  @CodyMathis123  
**Created**:  2019-09-19  
**Updated**:  2020-08-08

## RELATED LINKS
