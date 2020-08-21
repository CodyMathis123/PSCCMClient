function Invoke-CCMCommand {
	<#
		.SYNOPSIS
			Invoke commands remotely via Win32_Process:CreateProcess, or Invoke-Command
		.DESCRIPTION
			This function is used as part of the PSCCMClient Module. It's purpose is to allow commands
			to be execute remotely, while also automatically determining the best, or preferred method
			of invoking the command. Based on the type of connection that is passed, whether a CimSession,
			PSSession, or Computername with a ConnectionPreference, the command will be executed remotely
			by either using the CreateProcess Method of the Win32_Process CIM Class, or it will use
			Invoke-Command.
		.PARAMETER ScriptBlock
			The ScriptBlock that should be executed remotely
		.PARAMETER FunctionsToLoad
			A list of functions to load into the remote command exeuction. For example, you could specify that you want 
			to load "Get-CustomThing" into the remote command, as you've already written the function and want to use
			it as part of the scriptblock that will be remotely executed.
		.PARAMETER ArgumentList
			The list of arguments that will be pass into the script block
		.PARAMETER Timeout
			The time in milliseconds after which the NamedPipe will timeout. The NamedPipe connection is used in the 
			CimSession parameter set, as this is how the object is returned from the remote command. 
        .PARAMETER CimSession
            Provides CimSessions to invoke the specified scriptblock on
        .PARAMETER ComputerName
            Provides computer names to invoke the specified scriptblock on
        .PARAMETER PSSession
            Provides PSSessions to invoke the specified scriptblock on
        .PARAMETER ConnectionPreference
            Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
            is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
            when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
            pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
            specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
            falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
            the ComputerName parameter is passed to.
		.EXAMPLE
			C:\PS> Invoke-CCMCommand -ScriptBlock { 'Testing This' } -ComputerName Workstation123
				Would return the string 'Testing This' which was executed on the remote machine Workstation123
		.EXAMPLE
			C:\PS> function Test-This {
				'Testing This'
			}
			Invoke-CCMCommand -Scriptblock { Test-This } -FunctionsToLoad Test-This -ComputerName Workstation123
				Would load the custom Test-This function into the scriptblock, and execute it. This would return the 'Testing This'
				string, based on the function being executed remotely on Workstation123.
		.NOTES
			FileName:    Invoke-CCMCommand.ps1
			Author:      Cody Mathis
			Contact:     @CodyMathis123
			Created:     2020-02-12
			Updated:     2020-03-02
	#>
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
						$SupportFunctionsToConvert = 'ConvertTo-Base64StringFromObject', 'ConvertFrom-CliXml', 'ConvertFrom-Base64ToObject'
						$PassArgList = $true
						ConvertTo-Base64StringFromObject -inputObject $ArgumentList
					}
					$false {
						$SupportFunctionsToConvert = 'ConvertTo-Base64StringFromObject'
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
				$ScriptBlock.Invoke((ConvertFrom-Base64ToObject -inputString {5}))
			}}
			$false {{
				$ScriptBlock.Invoke()
			}}
		}}
		$results = ConvertTo-Base64StringFromObject -inputObject $TempResultPreConversion
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
						ConvertFrom-Base64ToObject -inputString $tempData
					}
				}
				'PSSession' {
					Invoke-Command @InvokeCommandSplat @connectionSplat
				}
			}
		}
	}
}