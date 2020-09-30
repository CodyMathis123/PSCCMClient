---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Test-CCMIsWindowAvailableNow

## SYNOPSIS
Determine if a window is available now for the provided runtime and MWType

## SYNTAX

### ComputerName (Default)
```
Test-CCMIsWindowAvailableNow [-MWType <String[]>] [-MaxRuntime <Int32>]
 [-FallbackToAllProgramsWindow <Boolean>] [-ComputerName <String[]>] [-ConnectionPreference <String>]
 [<CommonParameters>]
```

### CimSession
```
Test-CCMIsWindowAvailableNow [-MWType <String[]>] [-MaxRuntime <Int32>]
 [-FallbackToAllProgramsWindow <Boolean>] [-CimSession <CimSession[]>] [<CommonParameters>]
```

### PSSession
```
Test-CCMIsWindowAvailableNow [-MWType <String[]>] [-MaxRuntime <Int32>]
 [-FallbackToAllProgramsWindow <Boolean>] [-PSSession <PSSession[]>] [<CommonParameters>]
```

## DESCRIPTION
This function uses the IsWindowAvailableNow method of the CCM_ServiceWindowManager CIM class.
It will allow you to
determine if a deployment will run based on your input parameters.

It also will determine your client settings for software updates to appropriately fall back to an 'All Deployment Service Window'
according to both your settings, and whether a 'Software Update Service Window' is available

## EXAMPLES

### EXAMPLE 1
```
Test-CCMIsWindowAvailableNow
    Return information about the default MWType of 'Software Update Service Window' with a runtime of 0, and fallback
    based on client settings and 'Software Update Service Window' availability.
```

### EXAMPLE 2
```
Test-CCMIsWindowAvailableNow -ComputerName 'Workstation1234','Workstation4321' -MWType 'Task Sequences Service Window' -MaxRunTime 3600
    Return information on whether a task sequence with a run time of 3600 seconds can currently run on 'Workstation1234','Workstation4321'
```

## PARAMETERS

### -MWType
Specifies the types of MW you want information for.
Defaults to 'Software Update Service Window'.
Valid options are below
    'All Deployment Service Window',
    'Program Service Window',
    'Reboot Required Service Window',
    'Software Update Service Window',
    'Task Sequences Service Window',
    'Corresponds to non-working hours'

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Software Update Service Window
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxRuntime
The max run time (in seconds) that will be passed to the IsWindowAvailableNow method.
This is defined for the
applications, programs, and updates you deploy.
For software updates, you would want the cumulative
max run time of all updates in a SUG.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -FallbackToAllProgramsWindow
{{ Fill FallbackToAllProgramsWindow Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CimSession
Provides CimSession to gather Maintenance Window information info from

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
Provides computer names to gather Maintenance Window information info from

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
Provides PSSession to gather Maintenance Window information info from

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

**FileName**:    Test-CCMIsWindowAvailableNow.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2020-01-29  
**Updated**:     2020-09-29  

## RELATED LINKS
