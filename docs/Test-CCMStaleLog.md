---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Test-CCMStaleLog

## SYNOPSIS
Returns a boolean based on whether a log file has been written to in the timeframe specified

## SYNTAX

### ComputerName (Default)
```
Test-CCMStaleLog -LogFileName <String> [-DaysStale <Int32>] [-HoursStale <Int32>] [-MinutesStale <Int32>]
 [-DisableCCMSetupFallback] [-ComputerName <String[]>] [-ConnectionPreference <String>] [<CommonParameters>]
```

### CimSession
```
Test-CCMStaleLog -LogFileName <String> [-DaysStale <Int32>] [-HoursStale <Int32>] [-MinutesStale <Int32>]
 [-DisableCCMSetupFallback] [-CimSession <CimSession[]>] [<CommonParameters>]
```

### PSSession
```
Test-CCMStaleLog -LogFileName <String> [-DaysStale <Int32>] [-HoursStale <Int32>] [-MinutesStale <Int32>]
 [-DisableCCMSetupFallback] [-PSSession <PSSession[]>] [<CommonParameters>]
```

## DESCRIPTION
This function is used to check the LastWriteTime property of a specified file.
It will be compared to
the *Stale parameters.
Note that logs are assumed to be under the MEMCM Log directory.
Note that
this function uses the CIM_DataFile so that SMB is NOT needed.
Get-CimInstance is able to query for
file information.

## EXAMPLES

### EXAMPLE 1
```
Test-CCMStaleLog -LogFileName ccmexec -DaysStale 2
    Check if the ccmexec log file has been written to within the last 2 days on the local computer
```

### EXAMPLE 2
```
Test-CCMStaleLog -LogFileName AppDiscovery.log -DaysStale 7 -ComputerName Workstation123
    Check if the AppDiscovery.log file has been written to within the last 7 days on Workstation123
```

## PARAMETERS

### -LogFileName
Name of the log file under the CCM\Logs directory to check.
The full path for the MEMCM logs
will be automatically identified.
The .log extension is optional.

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

### -DaysStale
Number of days of inactivity that you would consider the specified log stale.

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

### -HoursStale
Number of days of inactivity that you would consider the specified log stale.

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

### -MinutesStale
Number of minutes of inactivity that you would consider the specified log stale.

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

### -DisableCCMSetupFallback
Disable the CCMSetup fallback check - details below.

When the desired log file is not found, then the last modified timestamp for the CCMSetup log is checked.
When the CCMSetup file has activity within the last 24 hours, then we assume that, even though our desired
log file was not found, it isn't stale because the MEMCM client is recently installed or repaired.
If the CCMSetup is found, and has no activity, or is just not found, then we assume the desired
log is 'stale.' This additional check can be disabled with this switch parameter.

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
CimSessions to check the stale log on.

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
Computer Names to check the stale log on.

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
PSSessions to check the stale log on.

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

**FileName**:    Test-CCMStaleLog.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2020-01-25  
**Updated**:     2020-02-27  

## RELATED LINKS
