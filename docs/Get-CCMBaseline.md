---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Get-CCMBaseline

## SYNOPSIS
Get MEMCM Configuration Baselines on the specified computer(s) or cimsession(s)

## SYNTAX

### ComputerName (Default)
```
Get-CCMBaseline [-BaselineName <String[]>] [-ComputerName <String[]>] [-ConnectionPreference <String>]
 [<CommonParameters>]
```

### CimSession
```
Get-CCMBaseline [-BaselineName <String[]>] [-CimSession <CimSession[]>] [<CommonParameters>]
```

### PSSession
```
Get-CCMBaseline [-BaselineName <String[]>] [-PSSession <PSSession[]>] [<CommonParameters>]
```

## DESCRIPTION
This function is used to identify baselines on computers.
You can provide an array of computer names, or cimsessions, and
configuration baseline names which will be queried for.
If you do not specify a baseline name, then there will be no filter applied.
A \[PSCustomObject\] is returned that outlines the findings.

## EXAMPLES

### EXAMPLE 1
```
Get-CCMBaseline
    Gets all baselines identified in WMI on the local computer.
```

### EXAMPLE 2
```
Get-CCMBaseline -ComputerName 'Workstation1234','Workstation4321' -BaselineName 'Check Connection Compliance','Double Check Connection Compliance'
    Gets the two baselines on the Computers specified. This demonstrates that both ComputerName and BaselineName accept string arrays.
```

### EXAMPLE 3
```
Get-CCMBaseline -ComputerName 'Workstation1234','Workstation4321'
    Gets all baselines identified in WMI for the Computers specified.
```

## PARAMETERS

### -BaselineName
Provides the configuration baseline names that you wish to search for.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: NotSpecified
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -CimSession
Provides cimsessions to return baselines from.

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
Provides computer names to find the configuration baselines on.

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
Provides PSSessions to return baselines from.

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

**FileName**:    Get-CCMBaseline.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2019-07-24  
**Updated**:     2020-02-27  

It is important to note that if a configuration baseline has user settings, the only way to search for it is if the user is logged in, and you run this script
with those credentials provided to a CimSession.
An example would be if Workstation1234 has user Jim1234 logged in, with a configuration baseline 'FixJimsStuff'
that has user settings,

This command would successfully find FixJimsStuff
Get-CCMBaseline -ComputerName 'Workstation1234' -BaselineName 'FixJimsStuff' -CimSession $CimSessionWithJimsCreds

This command would not find the baseline FixJimsStuff
Get-CCMBaseline -ComputerName 'Workstation1234' -BaselineName 'FixJimsStuff'

You could remotely query for that baseline AS Jim1234, with either a runas on PowerShell, or providing Jim's credentials to a cimsesion passed to -cimsession param.
If you try to query for this same baseline without Jim's credentials being used in some way you will see that the baseline is not found.

## RELATED LINKS
