---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Get-CCMLastSoftwareInventory

## SYNOPSIS
Returns info about the last time Software Inventory ran

## SYNTAX

### ComputerName (Default)
```
Get-CCMLastSoftwareInventory [-ComputerName <String[]>] [-ConnectionPreference <String>] [<CommonParameters>]
```

### CimSession
```
Get-CCMLastSoftwareInventory [-CimSession <CimSession[]>] [<CommonParameters>]
```

### PSSession
```
Get-CCMLastSoftwareInventory [-PSSession <PSSession[]>] [<CommonParameters>]
```

## DESCRIPTION
This function will return info about the last time Software Inventory was ran.
This is pulled from the InventoryActionStatus WMI Class.
The Software inventory major, and minor version is included.
This can be helpful in troubleshooting Software inventory issues.

## EXAMPLES

### EXAMPLE 1
```
Get-CCMLastSoftwareInventory
    Returns info regarding the last Software inventory cycle for the local computer
```

### EXAMPLE 2
```
Get-CCMLastSoftwareInventory -ComputerName 'Workstation1234','Workstation4321'
    Returns info regarding the last Software inventory cycle for Workstation1234, and Workstation4321
```

## PARAMETERS

### -CimSession
Provides CimSession to gather Software inventory last run info from

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
Provides computer names to gather Software inventory last run info from

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
Provides PSSessions to gather Software inventory last run info from

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

**FileName**:    Get-CCMLastSoftwareInventory.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2020-01-01  
**Updated**:     2020-02-27  

## RELATED LINKS
