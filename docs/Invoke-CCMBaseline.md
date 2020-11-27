---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Invoke-CCMBaseline

## SYNOPSIS
Invoke MEMCCM Configuration Baselines on the specified computers

## SYNTAX

### ComputerName (Default)
```
Invoke-CCMBaseline [-BaselineName <String[]>] [-ComputerName <String[]>] [-ConnectionPreference <String>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### CimSession
```
Invoke-CCMBaseline [-BaselineName <String[]>] [-CimSession <CimSession[]>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### PSSession
```
Invoke-CCMBaseline [-BaselineName <String[]>] [-PSSession <PSSession[]>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
This function will allow you to provide an array of computer names, PSSessions, or cimsessions, and configuration baseline names which will be invoked.
If you do not specify a baseline name, then ALL baselines on the machine will be invoked.
A \[PSCustomObject\] is returned that
outlines the results, including the last time the baseline was ran, and if the previous run returned compliant or non-compliant.

## EXAMPLES

### EXAMPLE 1
```
Invoke-CCMBaseline
    Invoke all baselines identified in WMI on the local computer.
```

### EXAMPLE 2
```
Invoke-CCMBaseline -ComputerName 'Workstation1234','Workstation4321' -BaselineName 'Check Computer Compliance','Double Check Computer Compliance'
    Invoke the two baselines on the computers specified. This demonstrates that both ComputerName and BaselineName accept string arrays.
```

### EXAMPLE 3
```
Invoke-CCMBaseline -ComputerName 'Workstation1234','Workstation4321'
    Invoke all baselines identified in WMI for the computers specified.
```

## PARAMETERS

### -BaselineName
Provides the configuration baseline names that you wish to invoke.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: NotSpecified
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -CimSession
Provides cimsessions to invoke the configuration baselines on.

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
Provides computer names to invoke the configuration baselines on.

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
Provides PSSessions to invoke the configuration baselines on.

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

**FileName**:    Invoke-CCMBaseline.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2019-07-24  
**Updated**:     2020-03-01  

It is important to note that if a configuration baseline has user settings, the only way to invoke it is if the user is logged in, and you run this script
with those credentials provided to a CimSession.
An example would be if Workstation1234 has user Jim1234 logged in, with a configuration baseline 'FixJimsStuff'
that has user settings,

This command would successfully invoke FixJimsStuff
Invoke-CCMBaseline -ComputerName 'Workstation1234' -BaselineName 'FixJimsStuff' -CimSession $CimSessionWithJimsCreds

This command would not find the baseline FixJimsStuff, and be unable to invoke it
Invoke-CCMBaseline -ComputerName 'Workstation1234' -BaselineName 'FixJimsStuff'

You could remotely invoke that baseline AS Jim1234, with either a runas on PowerShell, or providing Jim's credentials to a cimsesion passed to -cimsession param.
If you try to invoke this same baseline without Jim's credentials being used in some way you will see that the baseline is not found.

Outside of that, it will dynamically generate the arguments to pass to the TriggerEvaluation method.
I found a handful of examples on the internet for
invoking MEMCM Configuration Baselines, and there were always comments about certain scenarios not working.
This implementation has been consistent in
invoking Configuration Baselines, including those with user settings, as long as the context is correct.

## RELATED LINKS
