---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Set-CCMDNSSuffix

## SYNOPSIS
Sets the current DNS suffix for the MEMCM Client

## SYNTAX

### ComputerName (Default)
```
Set-CCMDNSSuffix [-DNSSuffix <String>] [-ComputerName <String[]>] [-ConnectionPreference <String>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### CimSession
```
Set-CCMDNSSuffix [-DNSSuffix <String>] [-CimSession <CimSession[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### PSSession
```
Set-CCMDNSSuffix [-DNSSuffix <String>] [-PSSession <PSSession[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This function will set the current DNS suffix for the MEMCM Client.
This is done using the Microsoft.SMS.Client COM Object.

## EXAMPLES

### EXAMPLE 1
```
Set-CCMDNSSuffix -DNSSuffix 'contoso.com'
    Sets the local computer's DNS Suffix to contoso.com
```

### EXAMPLE 2
```
Set-CCMDNSSuffix -ComputerName 'Workstation1234','Workstation4321' -DNSSuffix 'contoso.com'
    Sets the DNS Suffix for Workstation1234, and Workstation4321 to contoso.com
```

## PARAMETERS

### -DNSSuffix
The desired DNS Suffix that will be set for the specified computers/cimsessions

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CimSession
Provides CimSessions to set the current DNS suffix for

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
Provides computer names to set the current DNS suffix for

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
Provides PSSession to set the current DNS suffix for

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

**FileName**:    Set-CCMDNSSuffix.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2020-01-18  
**Updated**:     2020-03-01  

## RELATED LINKS
