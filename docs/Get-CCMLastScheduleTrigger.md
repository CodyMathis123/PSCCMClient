---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Get-CCMLastScheduleTrigger

## SYNOPSIS
Returns the last time a specified schedule was triggered

## SYNTAX

### ComputerName (Default)
```
Get-CCMLastScheduleTrigger [<CommonParameters>]
```

### ByName-ComputerName
```
Get-CCMLastScheduleTrigger -Schedule <String[]> [-ComputerName <String[]>] -ConnectionPreference <String>
 [<CommonParameters>]
```

### ByName-PSSession
```
Get-CCMLastScheduleTrigger -Schedule <String[]> -PSSession <PSSession[]> [<CommonParameters>]
```

### ByName-CimSession
```
Get-CCMLastScheduleTrigger -Schedule <String[]> [-CimSession <CimSession[]>] [<CommonParameters>]
```

### ByID-ComputerName
```
Get-CCMLastScheduleTrigger -ScheduleID <String[]> [-ForceWildcard] [-ComputerName <String[]>]
 -ConnectionPreference <String> [<CommonParameters>]
```

### ByID-PSSession
```
Get-CCMLastScheduleTrigger -ScheduleID <String[]> [-ForceWildcard] -PSSession <PSSession[]>
 [<CommonParameters>]
```

### ByID-CimSession
```
Get-CCMLastScheduleTrigger -ScheduleID <String[]> [-ForceWildcard] [-CimSession <CimSession[]>]
 [<CommonParameters>]
```

## DESCRIPTION
This function will return the last time a schedule was triggered.
Keep in mind this is when a scheduled run happens, such as the periodic machine
policy refresh.
This is why you won't see the timestamp increment if you force a eval, and then check the schedule LastTriggerTime.

## EXAMPLES

### EXAMPLE 1
```
Get-CCMLastScheduleTrigger -Schedule 'Hardware Inventory'
Returns a [pscustomobject] detailing the schedule trigger history info available in WMI for Hardware Inventory
```

### EXAMPLE 2
```
Get-CCMLastScheduleTrigger -ComputerName 'Workstation1234','Workstation4321' -MWType 'Software Update Service Window'
    Return all the 'Software Update Service Window' Maintenance Windows for Workstation1234, and Workstation4321
```

## PARAMETERS

### -Schedule
Specifies the schedule to get trigger history info for.
This has a validate set of all possible 'standard' options that the client can perform
on a schedule.

```yaml
Type: String[]
Parameter Sets: ByName-ComputerName, ByName-PSSession, ByName-CimSession
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScheduleID
Specifies the ScheduleID to get trigger history info for.
This is a non-validated parameter that lets you simply query for a ScheduleID of your choosing.

```yaml
Type: String[]
Parameter Sets: ByID-ComputerName, ByID-PSSession, ByID-CimSession
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ForceWildcard
Switch that forces the CIM queries to surround your ScheduleID with % and changes the condition to 'LIKE' instead of =

```yaml
Type: SwitchParameter
Parameter Sets: ByID-ComputerName, ByID-PSSession, ByID-CimSession
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CimSession
Provides CimSessions to gather schedule trigger info from

```yaml
Type: CimSession[]
Parameter Sets: ByName-CimSession, ByID-CimSession
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ComputerName
Provides computer names to gather schedule trigger info from

```yaml
Type: String[]
Parameter Sets: ByName-ComputerName, ByID-ComputerName
Aliases: Connection, PSComputerName, PSConnectionName, IPAddress, ServerName, HostName, DNSHostName

Required: False
Position: Named
Default value: $env:ComputerName
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PSSession
Provides PSSessions to gather schedule trigger info from

```yaml
Type: PSSession[]
Parameter Sets: ByName-PSSession, ByID-PSSession
Aliases:

Required: True
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
Parameter Sets: ByName-ComputerName, ByID-ComputerName
Aliases:

Required: True
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

**FileName**:    Get-CCMLastScheduleTrigger.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2019-12-31  
**Updated**:     2020-02-23  

## RELATED LINKS
