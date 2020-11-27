---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Get-CCMMaintenanceWindow

## SYNOPSIS
Get ConfigMgr Maintenance Window information from computers via CIM

## SYNTAX

### ComputerName (Default)
```
Get-CCMMaintenanceWindow [-MWType <String[]>] [-ComputerName <String[]>] [-ConnectionPreference <String>]
 [<CommonParameters>]
```

### CimSession
```
Get-CCMMaintenanceWindow [-MWType <String[]>] [-CimSession <CimSession[]>] [<CommonParameters>]
```

### PSSession
```
Get-CCMMaintenanceWindow [-MWType <String[]>] [-PSSession <PSSession[]>] [<CommonParameters>]
```

## DESCRIPTION
This function will allow you to gather maintenance window information from multiple computers using CIM queries.
You can provide an array of computer names, or cimsessions,
or you can pass them through the pipeline.
You are also able to specify the Maintenance Window Type (MWType) you wish to query for.

## EXAMPLES

### EXAMPLE 1
```
Get-CCMMaintenanceWindow
    Return all the 'All Deployment Service Window', 'Software Update Service Window' Maintenance Windows for the local computer. These are the two default MW types
    that the function looks for
```

### EXAMPLE 2
```
Get-CCMMaintenanceWindow -ComputerName 'Workstation1234','Workstation4321' -MWType 'Software Update Service Window'
    Return all the 'Software Update Service Window' Maintenance Windows for Workstation1234, and Workstation4321
```

## PARAMETERS

### -MWType
Specifies the types of MW you want information for.
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
Default value: @('All Deployment Service Window', 'Software Update Service Window')
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
Provides PSSessions to gather Maintenance Window information info from

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

**FileName**:    Get-CCMMaintenanceWindow.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2019-08-14  
**Updated**:     2020-02-27  

## RELATED LINKS
