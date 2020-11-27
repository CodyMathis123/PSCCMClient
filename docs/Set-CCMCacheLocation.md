---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Set-CCMCacheLocation

## SYNOPSIS
Set ConfigMgr cache location from computers via CIM

## SYNTAX

### ComputerName (Default)
```
Set-CCMCacheLocation -Location <String> [-ComputerName <String[]>] [-ConnectionPreference <String>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### CimSession
```
Set-CCMCacheLocation -Location <String> [-CimSession <CimSession[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### PSSession
```
Set-CCMCacheLocation -Location <String> [-PSSession <PSSession[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This function will allow you to set the configuration manager cache location for multiple computers using CIM queries. 
You can provide an array of computer names, or cimsession, or you can pass them through the pipeline.
It will return a hashtable with the computer as key and boolean as value for success

## EXAMPLES

### EXAMPLE 1
```
Set-CCMCacheLocation -Location d:\windows\ccmcache
    Set cache location to d:\windows\ccmcache for local computer
```

### EXAMPLE 2
```
Set-CCMCacheLocation -ComputerName 'Workstation1234','Workstation4321' -Location 'C:\windows\ccmcache'
    Set Cache location to 'C:\Windows\CCMCache' for Workstation1234, and Workstation4321
```

### EXAMPLE 3
```
Set-CCMCacheLocation -ComputerName 'Workstation1234','Workstation4321' -Location 'C:\temp\ccmcache'
    Set Cache location to 'C:\temp\CCMCache' for Workstation1234, and Workstation4321
```

### EXAMPLE 4
```
Set-CCMCacheLocation -Location 'D:'
    Set Cache location to 'D:\CCMCache' for the local computer
```

## PARAMETERS

### -Location
Provides the desired cache location - note that ccmcache is appended if not provided as the end of the path

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CimSession
Provides CimSessions to set the cache location for

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
Provides computer names to set the cache location for

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
Provides PSSessions to set the cache location for

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

**FileName**:    Set-CCMCacheLocation.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2019-11-06  
**Updated**:     2020-03-01  

## RELATED LINKS
