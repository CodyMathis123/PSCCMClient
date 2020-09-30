---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Set-CCMProvisioningMode

## SYNOPSIS
Set ConfigMgr client provisioning mode to enabled or disabled, and control ProvisioningMaxMinutes

## SYNTAX

### ComputerName (Default)
```
Set-CCMProvisioningMode [-Status <String>] [-ProvisioningMaxMinutes <Int32>] [-ComputerName <String[]>]
 [-ConnectionPreference <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### CimSession
```
Set-CCMProvisioningMode [-Status <String>] [-ProvisioningMaxMinutes <Int32>] [-CimSession <CimSession[]>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### PSSession
```
Set-CCMProvisioningMode [-Status <String>] [-ProvisioningMaxMinutes <Int32>] [-PSSession <PSSession[]>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This function will allow you to set the configuration manager client provisioning mode using CIM queries.
You can provide an array of computer names, or cimsession, or you can pass them through the pipeline.
It will return a pscustomobject detailing the operations

## EXAMPLES

### EXAMPLE 1
```
Set-CCMProvisioningMode -Status Enabled
    Enables provisioning mode on the local computer
```

### EXAMPLE 2
```
Set-CCMProvisioningMode -ComputerName 'Workstation1234','Workstation4321' -Status Disabled
    Disables provisioning mode for Workstation1234, and Workstation4321
```

### EXAMPLE 3
```
Set-CCMProvisioningMode -ProvisioningMaxMinutes 360
    Sets ProvisioningMaxMinutes to 360 on the local computer so that provisioning mode is automatically
    disabled after 6 hours, instead of the default 48 hours
```

## PARAMETERS

### -Status
Should provisioning mode be enabled, or disabled?
Validate set ('Enabled','Disabled')

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProvisioningMaxMinutes
Set the ProvisioningMaxMinutes value for provisioning mode.
After this interval, provisioning mode is
automatically disabled.
This defaults to 48 hours.
The client checks this every 60 minutes, so any
value under 60 minutes will result in an effective ProvisioningMaxMinutes of 60 minutes.

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

### -CimSession
Provides CimSessions to set provisioning mode for

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
Provides computer names to set provisioning mode for

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
Provides PSSession to set provisioning mode for

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

**FileName**:    Set-CCMProvisioningMode.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2020-01-09  
**Updated**:     2020-03-02  

## RELATED LINKS
