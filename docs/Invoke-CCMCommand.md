---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Invoke-CCMCommand

## SYNOPSIS
Invoke commands remotely via Win32_Process:CreateProcess, or Invoke-Command

## SYNTAX

### ComputerName (Default)
```
Invoke-CCMCommand -ScriptBlock <ScriptBlock> [-FunctionsToLoad <String[]>] [-ArgumentList <Object[]>]
 [-ComputerName <String[]>] [-ConnectionPreference <String>] [<CommonParameters>]
```

### CimSession
```
Invoke-CCMCommand -ScriptBlock <ScriptBlock> [-FunctionsToLoad <String[]>] [-ArgumentList <Object[]>]
 [-Timeout <Int32>] [-CimSession <CimSession[]>] [<CommonParameters>]
```

### PSSession
```
Invoke-CCMCommand -ScriptBlock <ScriptBlock> [-FunctionsToLoad <String[]>] [-ArgumentList <Object[]>]
 [-PSSession <PSSession[]>] [<CommonParameters>]
```

## DESCRIPTION
This function is used as part of the PSCCMClient Module.
It's purpose is to allow commands
to be execute remotely, while also automatically determining the best, or preferred method
of invoking the command.
Based on the type of connection that is passed, whether a CimSession,
PSSession, or Computername with a ConnectionPreference, the command will be executed remotely
by either using the CreateProcess Method of the Win32_Process CIM Class, or it will use
Invoke-Command.

## EXAMPLES

### EXAMPLE 1
```
Invoke-CCMCommand -ScriptBlock { 'Testing This' } -ComputerName Workstation123
	Would return the string 'Testing This' which was executed on the remote machine Workstation123
```

### EXAMPLE 2
```
function Test-This {
	'Testing This'
}
Invoke-CCMCommand -Scriptblock { Test-This } -FunctionsToLoad Test-This -ComputerName Workstation123
	Would load the custom Test-This function into the scriptblock, and execute it. This would return the 'Testing This'
	string, based on the function being executed remotely on Workstation123.
```

## PARAMETERS

### -ScriptBlock
The ScriptBlock that should be executed remotely

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FunctionsToLoad
A list of functions to load into the remote command exeuction.
For example, you could specify that you want 
to load "Get-CustomThing" into the remote command, as you've already written the function and want to use
it as part of the scriptblock that will be remotely executed.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ArgumentList
The list of arguments that will be pass into the script block

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Timeout
The time in milliseconds after which the NamedPipe will timeout.
The NamedPipe connection is used in the 
CimSession parameter set, as this is how the object is returned from the remote command.

```yaml
Type: Int32
Parameter Sets: CimSession
Aliases:

Required: False
Position: Named
Default value: 120000
Accept pipeline input: False
Accept wildcard characters: False
```

### -CimSession
Provides CimSessions to invoke the specified scriptblock on

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
Provides computer names to invoke the specified scriptblock on

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
Provides PSSessions to invoke the specified scriptblock on

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
Default value: CimSession
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

**FileName**:    Invoke-CCMCommand.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2020-02-12  
**Updated**:     2020-09-29  

## RELATED LINKS
