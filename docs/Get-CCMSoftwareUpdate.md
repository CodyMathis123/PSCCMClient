---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Get-CCMSoftwareUpdate

## SYNOPSIS
Get pending MEMCM patches for a machine

## SYNTAX

### ComputerName (Default)
```
Get-CCMSoftwareUpdate [-IncludeDefs] [-ComputerName <String[]>] [-ConnectionPreference <String>]
 [<CommonParameters>]
```

### CimSession
```
Get-CCMSoftwareUpdate [-IncludeDefs] [-CimSession <CimSession[]>] [<CommonParameters>]
```

### PSSession
```
Get-CCMSoftwareUpdate [-IncludeDefs] [-PSSession <PSSession[]>] [<CommonParameters>]
```

## DESCRIPTION
Uses CIM to find MEMCM patches that are currently available on a machine.

## EXAMPLES

### EXAMPLE 1
```
Get-CCMSoftwareUpdate -Computer Testing123
will return all non-AV Dev patches for computer Testing123
```

## PARAMETERS

### -IncludeDefs
A switch that will determine if you want to include AV Definitions in your query

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
Computer CimSession(s) which you want to get pending MEMCM patches for

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
Computer name(s) which you want to get pending MEMCM patches for

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
{{ Fill PSSession Description }}

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

**FileName**:    Get-CCMSoftwareUpdate.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2020-01-15  
**Updated**:     2020-03-09  

## RELATED LINKS
