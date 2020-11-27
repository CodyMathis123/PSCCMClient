---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# ConvertTo-CCMLogFile

## SYNOPSIS
Convert from a CMLogEntry object to a file in CM log format.

## SYNTAX

```
ConvertTo-CCMLogFile [[-CMLogEntries] <CMLogEntry[]>] [[-LogPath] <String>] [<CommonParameters>]
```

## DESCRIPTION
This function takes an array of CMLogEntry objects and will turn them back into a log file. This can be useful
for aggregating or filtering multiple log files, and returning them back into one log file. CMLogEntry objects
can be obtained using the ConvertFrom-CCMLogFile function.

## EXAMPLES

### Example 1
```powershell
PS C:\> ConvertTo-CCMLogFile -CMLogEntries $LogEntries -LogPath C:\temp\Output.log
```

Convert the $LogEntry object (an array of CMLogEntry) into a CM log formatted file c:\temp\Output.log

## PARAMETERS

### -CMLogEntries
An array of CMLogEntry retrieved using ConvertFrom-CCMLogFile

```yaml
Type: CMLogEntry[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogPath
The output log file path

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

**FileName**:    ConvertTo-CCMLogFile.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2020-08-06  
**Updated**:     2020-11-26  

## RELATED LINKS
