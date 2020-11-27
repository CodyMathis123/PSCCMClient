---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Invoke-CCMTriggerSchedule

## SYNOPSIS
Triggers the specified ScheduleID on local, or remote computers

## SYNTAX

### ComputerName (Default)
```
Invoke-CCMTriggerSchedule -ScheduleID <String[]> [-ComputerName <String[]>] [-ConnectionPreference <String>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### CimSession
```
Invoke-CCMTriggerSchedule -ScheduleID <String[]> [-CimSession <CimSession[]>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### PSSession
```
Invoke-CCMTriggerSchedule -ScheduleID <String[]> [-PSSession <PSSession[]>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
This script will allow you to invoke the specified ScheduleID on a machine.
If the machine is remote, it will
usie the Invoke-CCMCommand to ensure the command can be invoked.
The sms_client class does not work when
invokeing methods remotely over CIM.

## EXAMPLES

### EXAMPLE 1
```
Invoke-CCMTriggerSchedule -ScheduleID TST20000
    Performs a TriggerSchedule operation on the TST20000 ScheduleID for the local computer
```

### EXAMPLE 2
```
Invoke-CCMTriggerSchedule -ScheduleID '{00000000-0000-0000-0000-000000000021}'
    Performs a TriggerSchedule operation on the {00000000-0000-0000-0000-000000000021} ScheduleID (Machine Policy Refresh) for the local
    computer
```

## PARAMETERS

### -ScheduleID
Define the schedule IDs to run on the machine, typically found by query another area of WMI

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -CimSession
Provides CimSessions to invoke IDs on

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
Provides computer names to invoke IDs on

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
Provides PSSession to invoke IDs on

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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

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

**FileName**:    Invoke-CCMTriggerSchedule.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2020-01-11  
**Updated**:     2020-03-02  

## RELATED LINKS
