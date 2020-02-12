# TODO - Add Help
function Invoke-CCMCommand {
	[CmdletBinding(DefaultParameterSetName = 'ComputerName')]
	param
	(
		[Parameter(Mandatory = $true)]
		[scriptblock]$ScriptBlock,
		[Parameter(Mandatory = $false)]
		[string[]]$FunctionsToLoad,
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