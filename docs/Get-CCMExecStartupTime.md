---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Get-CCMExecStartupTime

## SYNOPSIS
Return the CCMExec service startup time based on process creation date

## SYNTAX

### ComputerName (Default)
```
Get-CCMExecStartupTime [-ComputerName <String[]>] [-ConnectionPreference <String>] [<CommonParameters>]
```

### CimSession
```
Get-CCMExecStartupTime [-CimSession <CimSession[]>] [<CommonParameters>]
```

### PSSession
```
Get-CCMExecStartupTime [-PSSession <PSSession[]>] [<CommonParameters>]
```

## DESCRIPTION
This function will return the startup time of the CCMExec service if it is currently running.
The method used is querying
for the Win32_Service CIM object, and passing the ProcessID to Win32_Process CIM class.
This lets us determine the
creation date of the CCMExec process, which would coorelate to service startup time.

## EXAMPLES

### EXAMPLE 1
```
Get-CCMExecStartupTime
    Returns CCMExec service startup time for the local computer
```

### EXAMPLE 2
```
Get-CCMExecStartupTime -ComputerName 'Workstation1234','Workstation4321'
    Returns CCMExec service startup time for Workstation1234, and Workstation4321
```

## PARAMETERS

### -CimSession
Provides CimSessions to gather CCMExec service startup time from

```yaml
Type: CimSession[]
Parameter Sets: CimSession
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ComputerName
Provides computer names to gather CCMExec service startup time from

```yaml
Type: String[]
Parameter Sets: ComputerName
Aliases: Connection, PSComputerName, PSConnectionName, IPAddress, ServerName, HostName, DNSHostName

Required: False
Position: Named
Default value: $env:ComputerName
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PSSession
Provides PSSessions to gather CCMExec service startup time from

```yaml
Type: PSSession[]
Parameter Sets: PSSession
Aliases: Session

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConnectionPreference
Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
is passed to the function.
This is ultimately going to result in the function running faster.
The typical use case is
when you are using the pipeline.
In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
pipeline.
The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
specified in this parameter, to the the alternative (eg.
you specify, PSSession, it falls back to CIMSession), and then
falling back to ComputerName.
Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
the ComputerName parameter is passed to.

```yaml
Type: String
Parameter Sets: ComputerName
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

**FileName**:    Get-CCMExecStartupTime.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2020-01-29  
**Updated**:     2020-02-27  

## RELATED LINKS
