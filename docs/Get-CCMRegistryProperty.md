---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Get-CCMRegistryProperty

## SYNOPSIS
Return registry properties using the CIM StdRegProv, or Invoke-CCMCommand

## SYNTAX

### ComputerName (Default)
```
Get-CCMRegistryProperty -RegRoot <String> -Key <String> [-Property <String[]>] [-ComputerName <String[]>]
 [-ConnectionPreference <String>] [<CommonParameters>]
```

### CimSession
```
Get-CCMRegistryProperty -RegRoot <String> -Key <String> [-Property <String[]>] [-CimSession <CimSession[]>]
 [<CommonParameters>]
```

### PSSession
```
Get-CCMRegistryProperty -RegRoot <String> -Key <String> [-Property <String[]>] [-PSSession <PSSession[]>]
 [<CommonParameters>]
```

## DESCRIPTION
Relies on remote CIM and StdRegProv to allow for returning Registry Properties under a key.
If a PSSession, or ConnectionPreference
is used, then Invoke-CCMCommand is used instead.

## EXAMPLES

### EXAMPLE 1
```
Get-CCMRegistryProperty -RegRoot HKEY_LOCAL_MACHINE -Key 'SOFTWARE\Microsoft\SMS\Client\Client Components\Remote Control' -Property "Allow Remote Control of an unattended computer"
Name                           Value
----                           -----
Computer123                 @{Allow Remote Control of an unattended computer=1}
```

## PARAMETERS

### -RegRoot
The root key you want to search under
('HKEY_LOCAL_MACHINE', 'HKEY_USERS', 'HKEY_CURRENT_CONFIG', 'HKEY_DYN_DATA', 'HKEY_CLASSES_ROOT', 'HKEY_CURRENT_USER')

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

### -Key
The key you want to return properties of.
(ie.
SOFTWARE\Microsoft\SMS\Client\Configuration\Client Properties)

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

### -Property
The property name(s) you want to return the value of.
This is an optional string array \[string\[\]\] and if it is not provided, all properties
under the key will be returned

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

### -CimSession
Provides CimSessions to get registry properties from

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
Provides computer names to get registry properties from

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
Provides PSSessions to get registry properties from

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

### [System.Collections.Hashtable]

## NOTES

**FileName**:    Get-CCMRegistryProperty.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2019-11-07  
**Updated**:     2020-02-24  

## RELATED LINKS
