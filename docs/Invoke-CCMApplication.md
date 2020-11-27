---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Invoke-CCMApplication

## SYNOPSIS
Invoke the provided method for an application deployed to a computer

## SYNTAX

### ComputerName (Default)
```
Invoke-CCMApplication -ID <String[]> -IsMachineTarget <Boolean[]> -Revision <String[]> -Method <String>
 [-EnforcePreference <String>] [-Priority <String>] [-IsRebootIfNeeded <Boolean>] [-ComputerName <String[]>]
 [-ConnectionPreference <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### CimSession
```
Invoke-CCMApplication -ID <String[]> -IsMachineTarget <Boolean[]> -Revision <String[]> -Method <String>
 [-EnforcePreference <String>] [-Priority <String>] [-IsRebootIfNeeded <Boolean>] [-CimSession <CimSession[]>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### PSSession
```
Invoke-CCMApplication -ID <String[]> -IsMachineTarget <Boolean[]> -Revision <String[]> -Method <String>
 [-EnforcePreference <String>] [-Priority <String>] [-IsRebootIfNeeded <Boolean>] [-PSSession <PSSession[]>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Uses the Install, or Uninstall method of the CCM_Application CIMClass to perform actions on applications.

Not that you cannot inherently invoke these methods on every single application.
It will have to adhere
to the same logic that any application must follow for installation.
This includes meeting application 
requirements, being 'Applicable' in the sense of trying to 'Install' an application that is not currently
detected as installed, or trying to 'Uninstall' an application that is currently detected as installed, 
and it has an Uninstall command. 

The most surefire way to invoke an application method is to do so as system.
Otherwise, you can also do
the invoking as the current interactive user of the targeted machine.

## EXAMPLES

### EXAMPLE 1
```
Get-CCMApplication -ApplicationName '7-Zip' | Invoke-CCMApplication -Method Install
    Invokes the install of 7-Zip on the local computer
```

### EXAMPLE 2
```
Invoke-CCMApplication -ID ScopeId_BE389CA5-D6CC-42AF-B8F5-A059F9C9AD91/Application_0607d288-fc0b-42b7-9a61-76abedf0673e -Method Uninstall
    Invokes the uninstall of the application with the specified ID
```

## PARAMETERS

### -ID
An array of ID to invoke

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

### -IsMachineTarget
Boolean value that specifies if the application is machine targeted, or user targeted

```yaml
Type: Boolean[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Revision
The revision of the application that will have an action invoked.
This is needed so that MEMCM knows
    what policy it should be working with.

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

### -Method
Install, or Uninstall.
Keep in mind that you can only perform whatever action is available for an application.
    If it is a required application that does not allow uninstall, then the invoke will not work.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Action

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnforcePreference
When the install should take place.
Options are 'Immediate', 'NonBusinessHours', or 'AdminSchedule'

Defaults to 'Immediate'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Immediate
Accept pipeline input: False
Accept wildcard characters: False
```

### -Priority
The priority that is passed to the method.
Options are 'Foreground', 'High', 'Normal', and 'Low'

Defaults to 'High'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: High
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsRebootIfNeeded
Boolean that tells MEMCM if it can reboot the computer IF a reboot is required after the method completes based on exit code.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CimSession
Provides CimSession to invoke the application method on

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
Provides computer names to invoke the application method on

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
Provides PSSessions to invoke the application method on

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

**FileName**:    Invoke-CCMApplication.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2020-01-21  
**Updated**:     2020-03-02  

## RELATED LINKS
