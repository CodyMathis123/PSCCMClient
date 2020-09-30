---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Get-CCMApplication

## SYNOPSIS
Return deployed applications from a computer

## SYNTAX

### ComputerName (Default)
```
Get-CCMApplication [-ApplicationName <String[]>] [-ApplicationID <String[]>] [-IncludeIcon]
 [-ComputerName <String[]>] [-ConnectionPreference <String>] [<CommonParameters>]
```

### CimSession
```
Get-CCMApplication [-ApplicationName <String[]>] [-ApplicationID <String[]>] [-IncludeIcon]
 [-CimSession <CimSession[]>] [<CommonParameters>]
```

### PSSession
```
Get-CCMApplication [-ApplicationName <String[]>] [-ApplicationID <String[]>] [-IncludeIcon]
 [-PSSession <PSSession[]>] [<CommonParameters>]
```

## DESCRIPTION
Pulls a list of deployed applications from the specified computer(s) or CIMSession(s) with optional filters, and can be passed on
to Invoke-CCMApplication if desired.

Note that the parameters for filter are all joined together with OR.

## EXAMPLES

### EXAMPLE 1
```
Get-CCMApplication
    Returns all deployed applications listed in WMI on the local computer
```

### EXAMPLE 2
```
Get-CCMApplication -ApplicationID ScopeId_BE389CA5-D6CC-42AF-B8F5-A059F9C9AD91/Application_0607d288-fc0b-42b7-9a61-76abedf0673e -ApplicationName 'Software Install - Silent'
    Returns all deployed applications listed in WMI on the local computer which have either a application name of 'Software Install' or
    a ID of 'ScopeId_BE389CA5-D6CC-42AF-B8F5-A059F9C9AD91/Application_0607d288-fc0b-42b7-9a61-76abedf0673e'
```

## PARAMETERS

### -ApplicationName
An array of ApplicationName to filter on

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

### -ApplicationID
An array of application ID to filter on

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

### -IncludeIcon
Switch that determines if the Icon property will be included in the output.
As this can be a sizeable field, it is excluded by
default to minimize the time it takes for this to run, and the amount of memory that will be consumed.

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
Provides CimSession to gather deployed application info from

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
Provides computer names to gather deployed application info from

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
Provides PSSessions to gather deployed application info from

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

**FileName**:    Get-CCMApplication.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2020-01-21  
**Updated**:     2020-09-29  

## RELATED LINKS
