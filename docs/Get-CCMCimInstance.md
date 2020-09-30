---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Get-CCMCimInstance

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### CimQuery-ComputerName (Default)
```
Get-CCMCimInstance [-Namespace <String>] -Query <String> [-ComputerName <String[]>]
 [-ConnectionPreference <String>] [<CommonParameters>]
```

### CimFilter-ComputerName
```
Get-CCMCimInstance [-Namespace <String>] -ClassName <String> [-Filter <String>] [-ComputerName <String[]>]
 [-ConnectionPreference <String>] [<CommonParameters>]
```

### CimFilter-PSSession
```
Get-CCMCimInstance [-Namespace <String>] -ClassName <String> [-Filter <String>] [-PSSession <PSSession[]>]
 [<CommonParameters>]
```

### CimFilter-CimSession
```
Get-CCMCimInstance [-Namespace <String>] -ClassName <String> [-Filter <String>] [-CimSession <CimSession[]>]
 [<CommonParameters>]
```

### CimQuery-PSSession
```
Get-CCMCimInstance [-Namespace <String>] -Query <String> [-PSSession <PSSession[]>] [<CommonParameters>]
```

### CimQuery-CimSession
```
Get-CCMCimInstance [-Namespace <String>] -Query <String> [-CimSession <CimSession[]>] [<CommonParameters>]
```

### PassThrough-ComputerName
```
Get-CCMCimInstance [-Namespace <String>] [-ComputerName <String[]>] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -CimSession
{{ Fill CimSession Description }}

```yaml
Type: CimSession[]
Parameter Sets: CimFilter-CimSession, CimQuery-CimSession
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ClassName
{{ Fill ClassName Description }}

```yaml
Type: String
Parameter Sets: CimFilter-ComputerName, CimFilter-PSSession, CimFilter-CimSession
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
{{ Fill ComputerName Description }}

```yaml
Type: String[]
Parameter Sets: CimQuery-ComputerName, CimFilter-ComputerName, PassThrough-ComputerName
Aliases: Connection, PSComputerName, PSConnectionName, IPAddress, ServerName, HostName, DNSHostName

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ConnectionPreference
{{ Fill ConnectionPreference Description }}

```yaml
Type: String
Parameter Sets: CimQuery-ComputerName, CimFilter-ComputerName
Aliases:
Accepted values: CimSession, PSSession

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
{{ Fill Filter Description }}

```yaml
Type: String
Parameter Sets: CimFilter-ComputerName, CimFilter-PSSession, CimFilter-CimSession
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Namespace
{{ Fill Namespace Description }}

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

### -PSSession
{{ Fill PSSession Description }}

```yaml
Type: PSSession[]
Parameter Sets: CimFilter-PSSession, CimQuery-PSSession
Aliases: Session

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Query
{{ Fill Query Description }}

```yaml
Type: String
Parameter Sets: CimQuery-ComputerName, CimQuery-PSSession, CimQuery-CimSession
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Microsoft.Management.Infrastructure.CimSession[]

### System.String[]

## OUTPUTS

### System.Object

## NOTES

## RELATED LINKS
