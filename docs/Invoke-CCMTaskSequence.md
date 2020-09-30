---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Invoke-CCMTaskSequence

## SYNOPSIS
Invoke deployed task sequence on a computer

## SYNTAX

### ComputerName (Default)
```
Invoke-CCMTaskSequence [-PackageID <String[]>] [-TaskSequenceName <String[]>] [-Force]
 [-ComputerName <String[]>] [-ConnectionPreference <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### CimSession
```
Invoke-CCMTaskSequence [-PackageID <String[]>] [-TaskSequenceName <String[]>] [-Force]
 [-CimSession <CimSession[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### PSSession
```
Invoke-CCMTaskSequence [-PackageID <String[]>] [-TaskSequenceName <String[]>] [-Force]
 [-PSSession <PSSession[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This function can invoke a task sequence that is deployed to a computer.
It has an optional 'Force' parameter which will
temporarily change the RepeatRunBehavioar, and MandatoryAssignments parameters to force a task sequence to run regardless
of the schedule and settings assigned to it.

Note that the parameters for filter are all joined together with OR.

## EXAMPLES

### EXAMPLE 1
```
Invoke-CCMTaskSequence
    Invoke all task sequence listed in WMI on the local computer
```

### EXAMPLE 2
```
Invoke-CCMTaskSequence -TaskSequenceName 'Windows 10' -PackageID 'TST00443'
    Invoke the deployed task sequence listed in WMI on the local computer which have either a task sequence name of 'Windows 10' or
    a PackageID of 'TST00443'
```

## PARAMETERS

### -PackageID
An array of PackageID to filter on

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: PKG_PackageID

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -TaskSequenceName
An array of task sequence names to filter on

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: PKG_Name

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Force
Force the task sequence to run by temporarily changing the RepeatRunBehavioar, and MandatoryAssignments parameters as shown below

    Property = @{
        ADV_RepeatRunBehavior    = 'RerunAlways'
        ADV_MandatoryAssignments = $true
    }

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CimSession
Provides CimSession to invoke the task sequence on

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
Provides computer names to invoke the task sequence on

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
Provides PSSessions to invoke the task sequence on

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

**FileName**:    Invoke-CCMTaskSequence.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2020-01-15  
**Updated**:     2020-02-27  

## RELATED LINKS
