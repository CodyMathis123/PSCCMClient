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
		[int32]$Timeout = 120000,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
		[Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
		[Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
		[string[]]$ComputerName = $env:ComputerName
	)
	begin {
		$invokeCIMPowerShellSplat = @{
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
			$Computer = switch ($PSCmdlet.ParameterSetName) {
				'ComputerName' {
					Write-Output -InputObject $Connection
					switch ($Connection -eq $env:ComputerName) {
						$false {
							if ($ExistingCimSession = Get-CimSession -ComputerName $Connection -ErrorAction Ignore) {
								Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
								$invokeCIMPowerShellSplat.Remove('ComputerName')
								$invokeCIMPowerShellSplat['CimSession'] = $ExistingCimSession
							}
							else {
								Write-Verbose "No active CimSession found for $Connection - falling back to -ComputerName parameter for CIM cmdlets"
								$invokeCIMPowerShellSplat.Remove('CimSession')
								$invokeCIMPowerShellSplat['ComputerName'] = $Connection
							}
						}
						$true {
							$invokeCIMPowerShellSplat.Remove('CimSession')
							$invokeCIMPowerShellSplat.Remove('ComputerName')
							Write-Verbose 'Local computer is being queried - skipping computername, and cimsession parameter'
						}
					}
				}
				'CimSession' {
					Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
					Write-Output -InputObject $Connection.ComputerName
					$invokeCIMPowerShellSplat.Remove('ComputerName')
					$invokeCIMPowerShellSplat['CimSession'] = $Connection
				}
			}

			$invokeCIMPowerShellSplat['Arguments'] = @{
				CommandLine = [string]::Format("powershell.exe (invoke-command ([scriptblock]::Create([system.text.encoding]::UTF8.GetString([System.convert]::FromBase64string('{0}')))))", $encodedScriptBlock)
			}

			$null = Invoke-CimMethod @invokeCIMPowerShellSplat

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