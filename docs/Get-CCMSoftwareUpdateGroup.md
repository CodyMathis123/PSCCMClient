---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Get-CCMSoftwareUpdateGroup

## SYNOPSIS
Get information for the Software Update Groups deployed to a computer, including compliance

## SYNTAX

### ComputerName (Default)
```
Get-CCMSoftwareUpdateGroup [-AssignmentName <String[]>] [-AssignmentID <String[]>] [-ComputerName <String[]>]
 [-ConnectionPreference <String>] [<CommonParameters>]
```

### CimSession
```
Get-CCMSoftwareUpdateGroup [-AssignmentName <String[]>] [-AssignmentID <String[]>] [-CimSession <CimSession[]>]
 [<CommonParameters>]
```

### PSSession
```
Get-CCMSoftwareUpdateGroup [-AssignmentName <String[]>] [-AssignmentID <String[]>] [-PSSession <PSSession[]>]
 [<CommonParameters>]
```

## DESCRIPTION
Uses CIM to find information for the Software Update Groups deployed to a computer.
This includes checking the currently
reported 'compliance' for a software update group using the CCM_AssignmentCompliance CIM class

## EXAMPLES

### EXAMPLE 1
```
Get-CCMSoftwareUpdateGroup -Computer Testing123
    Will return all info available for the Software Update Groups deployed to Testing123
```

## PARAMETERS

### -AssignmentName
Provide an array of Software Update Group names to query for

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

### -AssignmentID
Provide an array of Software Update Group assignment ID to query for

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
Computer CimSession(s) which you want to get information for the Software Update Groups

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
Computer name(s) which you want to get information for the Software Update Groups

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
PSSessions which you want to get information for the Software Update Groups

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

**FileName**:    Get-CCMSoftwareUpdateGroup.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2020-01-21  
**Updated**:     2020-03-17  

## RELATED LINKS
