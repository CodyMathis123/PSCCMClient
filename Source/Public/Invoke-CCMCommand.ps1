function Invoke-CCMCommand {
	[CmdletBinding(DefaultParameterSetName = 'ComputerName')]
	param
	(
		[Parameter(Mandatory = $true)]
		[scriptblock]$ScriptBlock,
		[Parameter(Mandatory = $false)]
		[string[]]$FunctionsToLoad,
		[Parameter(Mandatory = $false)]
		[object[]]$ArgumentList,
		[Parameter(Mandatory = $false, ParameterSetName = 'CimSession')]
		[ValidateRange(1000, 900000)]
		[int32]$Timeout = 120000,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
		[Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
		[Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
		[string[]]$ComputerName = $env:ComputerName,
		[Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
		[Alias('Session')]
		[System.Management.Automation.Runspaces.PSSession[]]$PSSession,
		[Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
		[ValidateSet('CimSession', 'PSSession')]
		[string]$ConnectionPreference = 'CimSession'
	)
	begin {
		$HelperFunctions = switch ($PSBoundParameters.ContainsKey('FunctionsToLoad')) {
			$true {
				Convert-FunctionToString -FunctionToConvert $FunctionsToLoad
			}
		}
		$ConnectionChecker = switch ($PSCmdlet.ParameterSetName) {
			'ComputerName' {
				$ConnectionPreference
			}
			default {
				$PSCmdlet.ParameterSetName
			}
		}
		switch ($ConnectionChecker) {
			'CimSession' {
				$invokeCommandSplat = @{
					ClassName  = 'Win32_Process'
					MethodName = 'Create'
				}
				$PipeName = [guid]::NewGuid().Guid
				$ArgList = switch ($PSBoundParameters.ContainsKey('ArgumentList')) {
					$true {
						$SupportFunctionsToConvert = 'ConvertTo-CCMCodeStringFromObject', 'ConvertFrom-CliXml', 'ConvertFrom-CCMCodeStringToObject'
						$PassArgList = $true
						ConvertTo-CCMCodeStringFromObject -inputObject $ArgumentList
					}
					$false {
						$SupportFunctionsToConvert = 'ConvertTo-CCMCodeStringFromObject'
						$PassArgList = $false
						[string]::Empty
					}
				}
				$SupportFunctions = Convert-FunctionToString -FunctionToConvert $SupportFunctionsToConvert
				$ScriptBlockString = [string]::Format(@'
		{0}

		{2}

		$namedPipe = New-Object System.IO.Pipes.NamedPipeServerStream "{1}", "Out"
		$namedPipe.WaitForConnection()
		$streamWriter = New-Object System.IO.StreamWriter $namedPipe
		$streamWriter.AutoFlush = $true
		$ScriptBlock = {{
			{3}
		}}
		$TempResultPreConversion = switch([bool]${4}) {{
			$true {{
				$ScriptBlock.Invoke((ConvertFrom-CCMCodeStringToObject -inputString {5}))
			}}
			$false {{
				$ScriptBlock.Invoke()
			}}
		}}
		$results = ConvertTo-CCMCodeStringFromObject -inputObject $TempResultPreConversion
		$streamWriter.WriteLine("$($results)")
		$streamWriter.dispose()
		$namedPipe.dispose()
'@ , $SupportFunctions, $PipeName, $HelperFunctions, $ScriptBlock, $PassArgList, $ArgList)

				$scriptBlockPreEncoded = [scriptblock]::Create($ScriptBlockString)
				$byteCommand = [System.Text.encoding]::UTF8.GetBytes($scriptBlockPreEncoded)
				$encodedScriptBlock = [convert]::ToBase64string($byteCommand)
				$invokeCommandSplat['Arguments'] = @{
					CommandLine = [string]::Format("powershell.exe (invoke-command ([scriptblock]::Create([system.text.encoding]::UTF8.GetString([System.convert]::FromBase64string('{0}')))))", $encodedScriptBlock)
				}
			}
			'PSSession' {
				$ScriptBlockString = [string]::Format(@'
				{0}

				{1}
'@ , $HelperFunctions, $ScriptBlock)
				$FullScriptBlock = [scriptblock]::Create($ScriptBlockString)

				$InvokeCommandSplat = @{
					ScriptBlock = $FullScriptBlock
				}
				switch ($PSBoundParameters.ContainsKey('ArgumentList')) {
					$true {
						$invokeCommandSplat['ArgumentList'] = $ArgumentList
					}
				}
			}
		}
	}
	process {
		foreach ($Connection in (Get-Variable -Name $PSCmdlet.ParameterSetName -ValueOnly -Scope Local)) {
			$getConnectionInfoSplat = @{
				$PSCmdlet.ParameterSetName = $Connection
			}
			$ConnectionInfo = Get-CCMConnection @getConnectionInfoSplat -Prefer $ConnectionChecker
			$Computer = $ConnectionInfo.ComputerName
			$connectionSplat = $ConnectionInfo.connectionSplat

			switch ($ConnectionChecker) {
				'CimSession' {
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
						ConvertFrom-CCMCodeStringToObject -inputString $tempData
					}
				}
				'PSSession' {
					Invoke-Command @InvokeCommandSplat @connectionSplat
				}
			}
		}
	}
}