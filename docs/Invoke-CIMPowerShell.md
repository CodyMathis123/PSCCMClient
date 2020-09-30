---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# Invoke-CIMPowerShell

## SYNOPSIS
Invoke PowerShell scriptblocks over CIM

## SYNTAX

### ComputerName (Default)
```
Invoke-CIMPowerShell [-PipeName <Object>] -ScriptBlock <ScriptBlock> [-FunctionsToLoad <String[]>]
 [-Timeout <Int32>] [-ComputerName <String[]>] [<CommonParameters>]
```

### CimSession
```
Invoke-CIMPowerShell [-PipeName <Object>] -ScriptBlock <ScriptBlock> [-FunctionsToLoad <String[]>]
 [-Timeout <Int32>] [-CimSession <CimSession[]>] [<CommonParameters>]
```

## DESCRIPTION
This function uses the 'Create' method of the Win32_Process class in order to remotely invoke PowerShell
scriptblocks.
In order to return the object from the remote machine, Named Pipes are used, which requires
Port 445 to be open.

## EXAMPLES

### EXAMPLE 1
```
Invoke-CimPowerShell -Scriptblock { 
	$Client = New-Object -ComObject Microsoft.SMS.Client
	$Client.GetDNSSuffix()
 } -ComputerName Workstation123
 	Return the current DNS Suffix for the MEMCM on Workstation123 using the ComObject and a scriptblock
```

### EXAMPLE 2
```
Invoke-CimPowerShell -Scriptblock { Get-CCMDNSSuffix } -ComputerName Workstation123 -FunctionsToLoad Get-CCMDNSSuffix
 	Return the current DNS Suffix for the MEMCM on Workstation123 by loading our existing function that does this work
```

## PARAMETERS

### -PipeName
The name of the 'NamedPipe' that will be used.
By default this is a randomly generated GUID.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: ([guid]::NewGuid()).Guid.ToString()
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScriptBlock
The scriptblock in which you want to invoke over CIM

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FunctionsToLoad
An array of 'Functions' you want to load into the remote command.
For example, you might have a custom written
function to interact with a COM object that you want to load into the remote command.
Instead of having an entire
scriptblock that recreates the function, you can simply specify the function in this parameter.

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

### -Timeout
The timeout value before the connection will fail to return data over the NamedPipe

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 120000
Accept pipeline input: False
Accept wildcard characters: False
```

### -CimSession
CimSession to invoke the remote code on

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
Computer name to invoke the remote code on

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

**FileName**:    Invoke-CIMPowerShell.ps1  
**Author**:      Cody Mathis  
**Contact**:     @CodyMathis123  
**Created**:     2020-01-07  
**Updated**:     2020-09-29  

## RELATED LINKS
