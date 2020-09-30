---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Repair-CCMCacheLocation

## SYNOPSIS
Repairs ConfigMgr cache location from computers via CIM.
This cleans up \\\\ and ccmcache\ccmcache in path

## SYNTAX

### ComputerName (Default)
```
Repair-CCMCacheLocation [-ComputerName <String[]>] [-ConnectionPreference <String>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### CimSession
```
Repair-CCMCacheLocation [-CimSession <CimSession[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### PSSession
```
Repair-CCMCacheLocation [-PSSession <PSSession[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This function will allow you to clean the existing cache path for multiple computers using CIM queries.
You can provide an array of computer names, or cimsessions, or you can pass them through the pipeline.
It will return a hashtable with the computer as key and boolean as value for success

## EXAMPLES

### EXAMPLE 1
```
Repair-CCMCacheLocation -Location d:\windows\ccmcache
    Repair cache for local computer
```

### EXAMPLE 2
```
Repair-CCMCacheLocation -ComputerName 'Workstation1234','Workstation4321'
    Repair Cache location for Workstation1234, and Workstation4321
```

## PARAMETERS

### -CimSession
Provides CimSessions to repair the cache location for

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
Provides computer names to repair the cache location for

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
Provides PSSessions to repair the cache location for

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

**FileName**:    Repair-CCMCacheLocation.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2019-11-06  
**Updated**:     2020-02-24  

## RELATED LINKS
