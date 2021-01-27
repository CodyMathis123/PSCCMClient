function Invoke-CIMPowerShell {
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
		[int32]$Timeout = 15000,
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

		$SupportFunctions = Convert-FunctionToString -FunctionToConvert 'ConvertTo-CCMCodeStringFromObject'
		$HelperFunctions = switch ($PSBoundParameters.ContainsKey('FunctionsToLoad')) {
			$true {
				Convert-FunctionToString -FunctionToConvert $FunctionsToLoad
			}
		}

		$ScriptBlockString = [string]::Format(@'
		{0}

		$namedPipe = [System.IO.Pipes.NamedPipeServerStream]::new("{1}", "Out")
		$namedPipe.WaitForConnection()
		$streamWriter = [System.IO.StreamWriter]::new($namedPipe)
		$streamWriter.AutoFlush = $true
		$TempResultPreConversion = & {{
			{2}

			{3}
		}}
		$results = ConvertTo-CCMCodeStringFromObject -inputObject $TempResultPreConversion
		$streamWriter.WriteLine($results)
		$streamWriter.dispose()
		$namedPipe.dispose()
'@ , $SupportFunctions, $PipeName, $HelperFunctions, $ScriptBlock)

		$scriptBlockPreEncoded = [scriptblock]::Create($ScriptBlockString)
		$byteCommand = [System.Text.encoding]::Unicode.GetBytes($scriptBlockPreEncoded)
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
				CommandLine = [string]::Format("powershell.exe -EncodedCommand {0}", $encodedScriptBlock)
			}

			$null = Invoke-CimMethod @invokeCommandSplat @connectionSplat

			$namedPipe = [ System.IO.Pipes.NamedPipeClientStream]::new($Computer, $PipeName, "In")
			$namedPipe.Connect($timeout)
			$streamReader = New-Object System.IO.StreamReader $namedPipe

			while ($null -ne ($data = $streamReader.ReadLine())) {
				$tempData = $data
			}

			$streamReader.dispose()
			$namedPipe.dispose()

			if (-not [string]::IsNullOrWhiteSpace($tempData)) {
				ConvertFrom-CCMCodeStringToObject -inputString $tempData
			}
		}
	}
}