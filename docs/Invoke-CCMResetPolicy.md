---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Invoke-CCMResetPolicy

## SYNOPSIS
Invokes a ResetPolicy for the MEMCM client

## SYNTAX

### ComputerName (Default)
```
Invoke-CCMResetPolicy [-ResetType <String>] [-ComputerName <String[]>] [-ConnectionPreference <String>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### CimSession
```
Invoke-CCMResetPolicy [-ResetType <String>] [-CimSession <CimSession[]>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### PSSession
```
Invoke-CCMResetPolicy [-ResetType <String>] [-PSSession <PSSession[]>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
This function will force a complete policy reset on a client for multiple computers using CIM queries.
You can provide an array of computer names, or cimsessions, or you can pass them through the pipeline.

## EXAMPLES

### EXAMPLE 1
```
Invoke-CCMResetPolicy
    Reset the policy on the local machine and restarts CCMExec
```

## PARAMETERS

### -ResetType
Determins the policy reset type.

'Purge' will wipe all policy from the machine, forcing a complete redownload, and rebuilt.

'ForceFull' will simply force the next policy refresh to be a full instead of a delta.

https://docs.microsoft.com/en-us/previous-versions/system-center/developer/cc143785%28v%3dmsdn.10%29

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Purge
Accept pipeline input: False
Accept wildcard characters: False
```

### -CimSession
Provides CimSession to perform a policy reset on

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
Provides computer names to perform a policy reset on

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
Provides PSSession to perform a policy reset on

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

**FileName**:    Invoke-CCMResetPolicy.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2019-10-30  
**Updated**:     2020-03-02  

## RELATED LINKS
