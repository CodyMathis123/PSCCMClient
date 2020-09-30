---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Test-CCMIsClientAlwaysOnInternet

## SYNOPSIS
Return the status of the MEMCM client having AlwaysOnInternet set

## SYNTAX

### ComputerName (Default)
```
Test-CCMIsClientAlwaysOnInternet [-ComputerName <String[]>] [-ConnectionPreference <String>]
 [<CommonParameters>]
```

### CimSession
```
Test-CCMIsClientAlwaysOnInternet [-CimSession <CimSession[]>] [<CommonParameters>]
```

### PSSession
```
Test-CCMIsClientAlwaysOnInternet [-PSSession <PSSession[]>] [<CommonParameters>]
```

## DESCRIPTION
This function will invoke the IsClientAlwaysOnInternet of the MEMCM Client.
 This is done using the Microsoft.SMS.Client COM Object.

## EXAMPLES

### EXAMPLE 1
```
Test-CCMIsClientAlwaysOnInternet
    Returns the status of the local computer having IsAlwaysOnInternet set
```

### EXAMPLE 2
```
Test-CCMIsClientAlwaysOnInternet -ComputerName 'Workstation1234','Workstation4321'
    Returns the status of 'Workstation1234','Workstation4321' having IsAlwaysOnInternet set
```

## PARAMETERS

### -CimSession
Provides CimSessions to return AlwaysOnInternet setting info from

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
Provides computer names to return AlwaysOnInternet setting info from

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
Provides PSSession to return AlwaysOnInternet setting info from

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

**FileName**:    Test-CCMIsClientAlwaysOnInternet.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2020-01-29  
**Updated**:     2020-03-01  

## RELATED LINKS
