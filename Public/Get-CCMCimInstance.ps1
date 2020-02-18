# TODO - Add Help
function Get-CCMCimInstance {
	[CmdletBinding(DefaultParameterSetName = 'CimQuery-ComputerName')]
	param
	(
		[Parameter(Mandatory = $false)]
		[string]$Namespace,
		[Parameter(Mandatory = $true, ParameterSetName = 'CimFilter-CimSession')]
		[Parameter(Mandatory = $true, ParameterSetName = 'CimFilter-PSSession')]
		[Parameter(Mandatory = $true, ParameterSetName = 'CimFilter-ComputerName')]
		[string]$ClassName,
		[Parameter(Mandatory = $false, ParameterSetName = 'CimFilter-CimSession')]
		[Parameter(Mandatory = $false, ParameterSetName = 'CimFilter-PSSession')]
		[Parameter(Mandatory = $false, ParameterSetName = 'CimFilter-ComputerName')]
		[string]$Filter,
		[Parameter(Mandatory = $true, ParameterSetName = 'CimQuery-CimSession')]
		[Parameter(Mandatory = $true, ParameterSetName = 'CimQuery-PSSession')]
		[Parameter(Mandatory = $true, ParameterSetName = 'CimQuery-ComputerName')]
		[string]$Query,
		[Parameter(Mandatory = $false, ParameterSetName = 'CimQuery-ComputerName')]
		[Parameter(Mandatory = $false, ParameterSetName = 'CimFilter-ComputerName')]
		[ValidateSet('CimSession', 'PSSession')]
		[string]$ConnectionPreference = 'CimSession',
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimQuery-CimSession')]
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimFilter-CimSession')]
		[Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'PassThrough-ComputerName')]
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimQuery-ComputerName')]
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimFilter-ComputerName')]
		[Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
		[string[]]$ComputerName = $env:ComputerName,
		[Parameter(Mandatory = $false, ParameterSetName = 'CimQuery-PSSession')]
		[Parameter(Mandatory = $false, ParameterSetName = 'CimFilter-PSSession')]
		[Alias('Session')]
		[System.Management.Automation.Runspaces.PSSession[]]$PSSession
	)
	begin {
		$ConnectionChecker = ($PSCmdlet.ParameterSetName).Split('-')[1]

		$GetCimInstanceSplat = @{ }
		$StringArgs = switch ($PSBoundParameters.Keys) {
			'Namespace' {
				$GetCimInstanceSplat['NameSpace'] = $Namespace
				[string]::Format('-NameSpace "{0}"', $Namespace)
			}
			'ClassName' {
				$GetCimInstanceSplat['ClassName'] = $ClassName
				[string]::Format('-ClassName "{0}"', $ClassName)
			}
			'Filter' {
				$GetCimInstanceSplat['Filter'] = $Filter
				[string]::Format("-Filter '{0}'", $($Filter -replace "'", "''"))
			}
			'Query' {
				$GetCimInstanceSplat['Query'] = $Query
				[string]::Format("-Query '{0}'", $($Query -replace "'", "''"))
			}
		}
	}
	process {
		foreach ($Connection in (Get-Variable -Name $ConnectionChecker -ValueOnly -Scope Local)) {
			$getConnectionInfoSplat = @{
				$ConnectionChecker = $Connection
			}
			$ConnectionInfo = Get-CCMConnection @getConnectionInfoSplat -Prefer $ConnectionPreference
			$ConnectionPreference = $ConnectionInfo.ConnectionType
			$connectionSplat = $ConnectionInfo.connectionSplat

			switch ($ConnectionPreference) {
				'CimSession' {
					Get-CimInstance @GetCimInstanceSplat @connectionSplat
				}
				'PSSession' {
					$ScriptBlockString = [string]::Format('Get-CimInstance {0}', ([string]::Join(' ', $StringArgs)))
					$ScriptBlock = [scriptblock]::Create($ScriptBlockString)
					Invoke-Command -ScriptBlock $ScriptBlock @connectionSplat
				}
			}
		}
	}
}