---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Invoke-CCMSoftwareUpdate

## SYNOPSIS
Invokes updates deployed via Configuration Manager on a client

## SYNTAX

### ComputerName (Default)
```
Invoke-CCMSoftwareUpdate [-ArticleID <String[]>] [-ComputerName <String[]>] [-ConnectionPreference <String>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### CimSession
```
Invoke-CCMSoftwareUpdate [-ArticleID <String[]>] [-CimSession <CimSession[]>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### PSSession
```
Invoke-CCMSoftwareUpdate [-ArticleID <String[]>] [-PSSession <PSSession[]>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
This script will allow you to invoke updates a machine (with optional credentials).
It uses remote CIM to find updates
based on your input, or you can optionally provide updates via the $Updates parameter, which support pipeline from
Get-CCMSoftwareUpdate.

Unfortunately, invoke MEMCM updates remotely via CIM does NOT seem to work.
As an alternative, Invoke-CIMPowerShell is used to
execute the command 'locally' on the remote machine.

## EXAMPLES

### EXAMPLE 1
```
Invoke-CCMSoftwareUpdate
    Invokes all updates on the local machine
```

### EXAMPLE 2
```
Invoke-CCMSoftwareUpdate -ComputerName TestingPC1
    Invokes all updates on the the remote computer TestingPC1
```

## PARAMETERS

### -ArticleID
An array of Article ID to invoke.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -CimSession
Computer CimSession(s) which you want to get invoke MEMCM patches for

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
Computer name(s) which you want to get invoke MEMCM patches for

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
PSSession(s) which you want to get invoke MEMCM patches for

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

## NOTES

**FileName**:    Invoke-CCMSoftwareUpdate.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2018-12-22  
**Updated**:     2020-03-02  

## RELATED LINKS
