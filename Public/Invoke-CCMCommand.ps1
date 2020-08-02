function Invoke-CCMCommand {
	<#
		.SYNOPSIS
			Invoke commands remotely via Invoke-Command, allowing arguments and functions to be passed
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
        .PARAMETER ComputerName
            Provides computer names to invoke the specified scriptblock on
        .PARAMETER PSSession
            Provides PSSessions to invoke the specified scriptblock on
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
			Updated:     2020-08-01
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
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
		[Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
		[string[]]$ComputerName = $env:ComputerName,
		[Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
		[Alias('Session')]
		[System.Management.Automation.Runspaces.PSSession[]]$PSSession
	)
	begin {
		$HelperFunctions = switch ($PSBoundParameters.ContainsKey('FunctionsToLoad')) {
			$true {
				Convert-FunctionToString -FunctionToConvert $FunctionsToLoad
			}
		}
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
	process {
		foreach ($Connection in (Get-Variable -Name $PSCmdlet.ParameterSetName -ValueOnly -Scope Local)) {
			$getConnectionInfoSplat = @{
				$PSCmdlet.ParameterSetName = $Connection
			}
			$ConnectionInfo = Get-CCMConnection @getConnectionInfoSplat -Prefer PSSession
			$connectionSplat = $ConnectionInfo.connectionSplat

			Invoke-Command @InvokeCommandSplat @connectionSplat
		}
	}
}
