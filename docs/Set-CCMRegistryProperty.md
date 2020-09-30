---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Set-CCMRegistryProperty

## SYNOPSIS
Set registry properties values using the CIM StdRegProv, or Invoke-CCMCommand

## SYNTAX

### ComputerName (Default)
```
Set-CCMRegistryProperty -RegRoot <String> -Key <String> -Property <String> -Value <Object>
 -PropertyType <String> [-Force] [-ComputerName <String[]>] [-ConnectionPreference <String>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### CimSession
```
Set-CCMRegistryProperty -RegRoot <String> -Key <String> -Property <String> -Value <Object>
 -PropertyType <String> [-Force] [-CimSession <CimSession[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### PSSession
```
Set-CCMRegistryProperty -RegRoot <String> -Key <String> -Property <String> -Value <Object>
 -PropertyType <String> [-Force] [-PSSession <PSSession[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Relies on remote CIM and StdRegProv to allow for setting a Registry Property value.
If a PSSession, or ConnectionPreference
is used, then Invoke-CCMCommand is used instead.

## EXAMPLES

### EXAMPLE 1
```
Set-CCMRegistryProperty -RegRoot HKEY_LOCAL_MACHINE -Key 'SOFTWARE\Microsoft\SMS\Client\Client Components\Remote Control' -Property "Allow Remote Control of an unattended computer" -Value 1 -PropertyType DWORD
Name                           Value
----                           -----
Computer123                    $true
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
The key you want to set properties of.
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
The property name you want to set the value for

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

### -Value
The desired value for the property

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PropertyType
The type of property you are setting.
This is needed because the method for setting a registry value changes based on property type.
'String', 'ExpandedString', 'Binary', 'DWORD', 'MultiString', 'QWORD'

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

### -Force
Create the Property if it does not exist, otherwise only existing properties will have their value modified

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
Provides CimSessions to set registry properties for

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
Provides computer names to set registry properties for

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
Provides PSSessions to set registry properties for

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

### [System.Collections.Hashtable]

## NOTES

**FileName**:    Set-CCMRegistryProperty.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     Uhh...  
**Updated**:     2020-03-02  

## RELATED LINKS
