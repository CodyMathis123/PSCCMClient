function Invoke-CIMPowerShell {
	<#
		.SYNOPSIS
			Invoke PowerShell scriptblocks over CIM
		.DESCRIPTION
			This function uses the 'Create' method of the Win32_Process class in order to remotely invoke PowerShell
			scriptblocks. In order to return the object from the remote machine, Named Pipes are used, which requires
			Port 445 to be open. 
		.PARAMETER PipeName
			The name of the 'NamedPipe' that will be used. By default this is a randomly generated GUID. 
		.PARAMETER ScriptBlock
			The scriptblock in which you want to invoke over CIM
		.PARAMETER FunctionsToLoad
			An array of 'Functions' you want to load into the remote command. For example, you might have a custom written
			function to interact with a COM object that you want to load into the remote command. Instead of having an entire
			scriptblock that recreates the function, you can simply specify the function in this parameter.
		.PARAMETER Timeout
			The timeout value before the connection will fail to return data over the NamedPipe
		.PARAMETER CimSession
			CimSession to invoke the remote code on
		.PARAMETER ComputerName
			Computer name to invoke the remote code on
		.EXAMPLE
			C:\PS> Invoke-CimPowerShell -Scriptblock { 
				$Client = New-Object -ComObject Microsoft.SMS.Client
				$Client.GetDNSSuffix()
			 } -ComputerName Workstation123
			 	Return the current DNS Suffix for the MEMCM on Workstation123 using the ComObject and a scriptblock
		.EXAMPLE
			C:\PS> Invoke-CimPowerShell -Scriptblock { Get-CCMDNSSuffix } -ComputerName Workstation123 -FunctionsToLoad Get-CCMDNSSuffix
			 	Return the current DNS Suffix for the MEMCM on Workstation123 by loading our existing function that does this work
        .NOTES
            FileName:    Invoke-CIMPowerShell.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-01-07
            Updated:     2020-02-12
	#>
	[CmdletBinding(DefaultParameterSetName = 'ComputerName')]
	param
	(
		[Parameter(Mandatory = $false)]
		$PipeName = ([guid]::NewGuid()).Guid.ToString(),
		[Parameter(Mandatory = $true)]
		[scriptblock]$ScriptBlock,
		[Parameter(Mandatory = $false)]
		[string[]]$FunctionsToLoad,
		[Parameter(Mandatory = $false)]
		[ValidateRange(1000, 900000)]
		[int32]$Timeout = 120000,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
		[Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
		[Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
		[string[]]$ComputerName = $env:ComputerName
	)
	begin {
		$invokeCommandSplat = @{
			ClassName  = 'Win32_Process'
			MethodName = 'Create'
		}

		$SupportFunctions = Convert-FunctionToString -FunctionToConvert 'ConvertTo-CliXml', 'ConvertTo-Base64StringFromObject'
		$HelperFunctions = switch ($PSBoundParameters.ContainsKey('FunctionsToLoad')) {
			$true {
				Convert-FunctionToString -FunctionToConvert $FunctionsToLoad
			}
		}

		$ScriptBlockString = [string]::Format(@'
		{0}

		$namedPipe = New-Object System.IO.Pipes.NamedPipeServerStream "{1}", "Out"
		$namedPipe.WaitForConnection()
		$streamWriter = New-Object System.IO.StreamWriter $namedPipe
		$streamWriter.AutoFlush = $true
		$TempResultPreConversion = & {{
			{2}

			{3}
		}}
		$results = ConvertTo-Base64StringFromObject -inputObject $TempResultPreConversion
		$streamWriter.WriteLine("$($results)")
		$streamWriter.dispose()
		$namedPipe.dispose()
'@ , $SupportFunctions, $PipeName, $HelperFunctions, $ScriptBlock)

		$scriptBlockPreEncoded = [scriptblock]::Create($ScriptBlockString)
		$byteCommand = [System.Text.encoding]::UTF8.GetBytes($scriptBlockPreEncoded)
		$encodedScriptBlock = [convert]::ToBase64string($byteCommand)
	}
	process {
		foreach ($Connection in (Get-Variable -Name $PSCmdlet.ParameterSetName -ValueOnly -Scope Local)) {
			$getConnectionInfoSplat = @{
				$PSCmdlet.ParameterSetName = $Connection
			}
			$ConnectionInfo = Get-CCMConnection @getConnectionInfoSplat
			$Computer = $ConnectionInfo.ComputerName
			$connectionSplat = $ConnectionInfo.connectionSplat

			$invokeCommandSplat['Arguments'] = @{
				CommandLine = [string]::Format("powershell.exe (invoke-command ([scriptblock]::Create([system.text.encoding]::UTF8.GetString([System.convert]::FromBase64string('{0}')))))", $encodedScriptBlock)
			}

			$null = Invoke-CimMethod @invokeCommandSplat @connectionSplat

			$namedPipe = New-Object System.IO.Pipes.NamedPipeClientStream $Computer, "$($PipeName)", "In"
			$namedPipe.Connect($timeout)
			$streamReader = New-Object System.IO.StreamReader $namedPipe

			while ($null -ne ($data = $streamReader.ReadLine())) {
				$tempData = $data
			}

			$streamReader.dispose()
			$namedPipe.dispose()

			if (-not [string]::IsNullOrWhiteSpace($tempData)) {
				ConvertFrom-Base64ToObject -inputString $tempData
			}
		}
	}
}