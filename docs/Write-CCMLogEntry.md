---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Write-CCMLogEntry

## SYNOPSIS

Write to a log file in the CMTrace Format

## SYNTAX

```powershell
Write-CCMLogEntry [-Value] <String[]> [[-Severity] <Severity>] [[-Component] <String>] [-FileName] <String>
 [-Folder] <String> [[-Bias] <Int32>] [[-MaxLogFileSize] <Int32>] [[-LogsToKeep] <Int32>] [<CommonParameters>]
```

## DESCRIPTION

The function is used to write to a log file in a CMTrace compatible format.
This ensures that CMTrace or OneTrace can parse the log
    and provide data in a familiar format.

## EXAMPLES

### EXAMPLE 1

```powershell
Write-CCMLogEntry -Value 'Testing Function' -Component 'Test Script' -FileName 'LogTest.Log' -Folder 'c:\temp'
    Write out 'Testing Function' to the c:\temp\LogTest.Log file in a CMTrace format, noting 'Test Script' as the component.
```

## PARAMETERS

### -Value

String to be added it to the log file as the message, or value

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Message, ToLog

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Severity

Severity for the log entry.
You can either enter the string values of Informational, Warning, or Error, or alternatively
    you can enter 1 for Informational, 2 for Warning, and 3 for Error.

```yaml
Type: Severity
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Informational
Accept pipeline input: False
Accept wildcard characters: False
```

### -Component

Stage that the log entry is occurring in, log refers to as 'component.'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FileName

Name of the log file that the entry will written to - note this should not be the full path.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Folder

Path to the folder where the log will be stored.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Bias

Set timezone Bias to ensure timestamps are accurate.
This defaults to the local machines bias, but one can be provided.
It can be
    helpful to gather the bias once, and store it in a variable that is passed to this parameter as part of a splat, or $PSDefaultParameterValues

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: (Get-CimInstance -Query "SELECT Bias FROM Win32_TimeZone").Bias
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxLogFileSize

Maximum size of log file before it rolls over.
Set to 0 to disable log rotation.
Defaults to 5MB

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: 5242880
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogsToKeep

Maximum number of rotated log files to keep.
Set to 0 for unlimited rotated log files.
Defaults to 0.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

**FileName**:    Write-CCMLogEntry.ps1  
**Author**:      Cody Mathis, Adam Cook  
**Contact**:     @CodyMathis123, @codaamok  
**Created**:     2020-01-23  
**Updated**:     2021-06-19

## RELATED LINKS
