---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Get-CCMServiceWindow

## SYNOPSIS
Get ConfigMgr Service Window information from computers via CIM

## SYNTAX

### ComputerName (Default)
```
Get-CCMServiceWindow [-SWType <String[]>] [-ComputerName <String[]>] [-ConnectionPreference <String>]
 [<CommonParameters>]
```

### CimSession
```
Get-CCMServiceWindow [-SWType <String[]>] [-CimSession <CimSession[]>] [<CommonParameters>]
```

### PSSession
```
Get-CCMServiceWindow [-SWType <String[]>] [-PSSession <PSSession[]>] [<CommonParameters>]
```

## DESCRIPTION
This function will allow you to gather Service Window information from multiple computers using CIM queries.
Note that 'ServiceWindows' are object
that describe the schedule for a maintenance window, such as the recurrence, and date / time information.
You can provide an array of computer names,
or you can pass them through the pipeline.
You are also able to specify the Service Window Type (SWType) you wish to query for, and pass credentials.
What is returned is the data from the 'ActualConfig' section of WMI on the computer.
The data returned will include the 'schedules' as well as
the schedule type.
Note that the schedules are not really 'human readable' and can be passed into ConvertFrom-CCMSchedule to convert
them into a readable object.
This is the equivalent of the 'Convert-CMSchedule' cmdlet that is part of the MEMCM PowerShell module, but
it does not require the module and it is much faster.

## EXAMPLES

### EXAMPLE 1
```
Get-CCMSchedule
    Return all the 'All Deployment Service Window', 'Software Update Service Window' Maintenance Windows for the local computer. These are the two default MW types
    that the function looks for
```

### EXAMPLE 2
```
Get-CCMSchedule -ComputerName 'Workstation1234','Workstation4321' -SWType 'Software Update Service Window'
    Return all the 'Software Update Service Window' Maintenance Windows for Workstation1234, and Workstation4321
```

## PARAMETERS

### -SWType
Specifies the types of SW you want information for.
Valid options are below
    'All Deployment Service Window',
    'Program Service Window',
    'Reboot Required Service Window',
    'Software Update Service Window',
    'Task Sequences Service Window',
    'Corresponds to non-working hours'

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: MWType

Required: False
Position: Named
Default value: @('All Deployment Service Window', 'Software Update Service Window')
Accept pipeline input: False
Accept wildcard characters: False
```

### -CimSession
Provides CimSessions to gather Service Window information info from

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
Provides computer names to gather Service Window information info from

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
Provides PSSessions to gather Service Window information info from

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

**FileName**:    Get-CCMSchedule.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2019-12-12  
**Updated**:     2020-02-27  

## RELATED LINKS
