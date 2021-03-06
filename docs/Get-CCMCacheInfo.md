---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Get-CCMCacheInfo

## SYNOPSIS
Get ConfigMgr client cache directory info from computers via CIM

## SYNTAX

### ComputerName (Default)
```
Get-CCMCacheInfo [-ComputerName <String[]>] [-ConnectionPreference <String>] [<CommonParameters>]
```

### CimSession
```
Get-CCMCacheInfo [-CimSession <CimSession[]>] [<CommonParameters>]
```

### PSSession
```
Get-CCMCacheInfo [-PSSession <PSSession[]>] [<CommonParameters>]
```

## DESCRIPTION
This function will allow you to gather the ConfigMgr client cache directory info from multiple computers using CIM queries.
You can provide an array of computer names, or cimsessions, or you can pass them through the pipeline.

## EXAMPLES

### EXAMPLE 1
```
Get-CCMCacheInfo
    Return ConfigMgr client cache directory info for the local computer
```

### EXAMPLE 2
```
Get-CCMCacheInfo -ComputerName 'Workstation1234','Workstation4321'
    Return ConfigMgr client cache directory info for Workstation1234, and Workstation4321
```

## PARAMETERS

### -CimSession
Provides CimSession to gather cache info from.

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
Provides computer names to gather cache info from.

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
Provides PSSessions to gather cache info from.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

**FileName**:    Get-CCMCacheInfo.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2019-11-06  
**Updated**:     2020-02-27  

## RELATED LINKS
