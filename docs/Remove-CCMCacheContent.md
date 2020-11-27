---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Remove-CCMCacheContent

## SYNOPSIS
Removes the provided ContentID from the MEMCM cache

## SYNTAX

### ComputerName (Default)
```
Remove-CCMCacheContent [-ContentID <String[]>] [-Clear] [-Force] [-ComputerName <String[]>]
 [-ConnectionPreference <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### CimSession
```
Remove-CCMCacheContent [-ContentID <String[]>] [-Clear] [-Force] [-CimSession <CimSession[]>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### PSSession
```
Remove-CCMCacheContent [-ContentID <String[]>] [-Clear] [-Force] [-PSSession <PSSession[]>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This function will remove the provided ContentID from the MEMCM cache.
This is done using the UIResource.UIResourceMGR COM Object.

## EXAMPLES

### EXAMPLE 1
```
Remove-CCMCacheContent -Clear
    Clears the local MEMCM cache
```

### EXAMPLE 2
```
Remove-CCMCacheContent -ComputerName 'Workstation1234','Workstation4321' -ContentID TST002FE
    Removes ContentID TST002FE from the MEMCM cache for Workstation1234, and Workstation4321
```

## PARAMETERS

### -ContentID
ContentID that you want removed from the MEMCM cache.
An array can be provided

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Clear
Remove all content from the MEMCM cache

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

### -Force
Remove content from the cache, even if it is marked for 'persist content in client cache'

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
Provides CimSessions to remove the provided ContentID from the MEMCM cache for

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
Provides computer names to remove the provided ContentID from the MEMCM cache for

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
Provides PSSession to remove the provided ContentID from the MEMCM cache for

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

**FileName**:    Remove-CCMCacheContent.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2020-01-12  
**Updated**:     2020-11-26  

## RELATED LINKS
