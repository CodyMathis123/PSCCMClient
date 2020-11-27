---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Set-CCMClientAlwaysOnInternet

## SYNOPSIS
Set the ClientAlwaysOnInternet registry key on a computer

## SYNTAX

### ComputerName (Default)
```
Set-CCMClientAlwaysOnInternet -Status <String> [-ComputerName <String[]>] [-ConnectionPreference <String>]
 [<CommonParameters>]
```

### CimSession
```
Set-CCMClientAlwaysOnInternet -Status <String> [-CimSession <CimSession[]>] [<CommonParameters>]
```

### PSSession
```
Set-CCMClientAlwaysOnInternet -Status <String> [-PSSession <PSSession[]>] [<CommonParameters>]
```

## DESCRIPTION
This function leverages the Set-CCMRegistryProperty function in order to configure
the ClientAlwaysOnInternet property for the MEMCM Client.

## EXAMPLES

### EXAMPLE 1
```
Set-CCMClientAlwaysOnInternet -Status Enabled
    Sets ClientAlwaysOnInternet to Enabled for the local computer
```

### EXAMPLE 2
```
Set-CCMClientAlwaysOnInternet -ComputerName 'Workstation1234','Workstation4321' -Status Disabled
    Sets ClientAlwaysOnInternet to Disabled for 'Workstation1234', and 'Workstation4321'
```

## PARAMETERS

### -Status
Determines if the setting should be Enabled or Disabled

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
Provides CimSessions to set the ClientAlwaysOnInternet setting for

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
Provides computer names to set the ClientAlwaysOnInternet setting for

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
Provides PSSessions to set the ClientAlwaysOnInternet setting for

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

**FileName**:    Set-CCMClientAlwaysOnInternet.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2020-02-13  
**Updated**:     2020-02-27  

## RELATED LINKS
