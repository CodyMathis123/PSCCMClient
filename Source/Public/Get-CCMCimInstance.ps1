<#
		.SYNOPSIS
			Invoke a Get-CimInstance command
		.DESCRIPTION
			This function is used to invoke a Get-CimInstance command. What differentiates this from just running
			Get-CimInstance is that the function will also accept a PSSession as a parameter, and invoke the
			Get-CimInstance command over that PSSession transparently.
		.PARAMETER Namespace
			Specifies the namespace of CIM class.

			The default namespace is root/cimv2.
		.PARAMETER ClassName
			Specifies the name of the CIM class for which to retrieve the CIM instances.
		.PARAMETER Filter
			Specifies a where clause to use as a filter. Specify the clause in either the WQL or the CQL query language.
		.PARAMETER Query
			Specifies a query to run on the CIM server. For WQL-based queries, you can only use a SELECT query that returns
			instances.

			If the value specified contains double quotes (“), single quotes (‘), or a backslash (\), you must escape those
			characters by prefixing them with the backslash (\) character. If the value specified uses the WQL LIKE operator,
			then you must escape the following characters by enclosing them in square brackets ([]): percent (%), underscore
			(_), or opening square bracket ([).

			You cannot use a metadata query to retrieve a list of classes or an event query. To retrieve a list of classes,
			use the Get-CimClass cmdlet. To retrieve an event query, use the Register-CimIndicationEvent cmdlet.

			You can specify the query dialect using the QueryDialect parameter.
		.PARAMETER CimSession
			Computer CimSession(s) which you want to query a CimInstance on
		.PARAMETER ComputerName
			Computer name(s) which you want to query a CimInstance on
		.PARAMETER PSSession
			PSSessions which you want to query a CimInstance on
		.PARAMETER ConnectionPreference
			Determines if the 'Get-CCMConnection' function should check for a PSSession, or a CIMSession first when a ComputerName
			is passed to the function. This is ultimately going to result in the function running faster. The typical use case is
			when you are using the pipeline. In the pipeline scenario, the 'ComputerName' parameter is what is passed along the
			pipeline. The 'Get-CCMConnection' function is used to find the available connections, falling back from the preference
			specified in this parameter, to the the alternative (eg. you specify, PSSession, it falls back to CIMSession), and then
			falling back to ComputerName. Keep in mind that the 'ConnectionPreference' also determines what type of connection / command
			the ComputerName parameter is passed to.
		.EXAMPLE
			C:\PS> Get-CCMCimInstance -Query "SELECT * FROM Win32_ComputerSystem" -ComputerName Workstation123 -ConnectionPreference PSSession
				Query for the Win32_ComputerSystem CimClass, preferring a PSSession first, falling back to CimSession
		.EXAMPLE
			C:\PS> Get-CCMCimInstance -Query "SELECT * FROM Win32_ComputerSystem" -ComputerName Workstation123 -ConnectionPreference CimSession
				Query for the Win32_ComputerSystem CimClass, preferring a CimSession first, falling back to PSSession
		.EXAMPLE
			C:\PS> Get-CCMCimInstance -Query "SELECT * FROM Win32_ComputerSystem" -PSSession $PSS
				Query for the Win32_ComputerSystem CimClass against the machine that the $PSS targets via a PSSession
		.EXAMPLE
			C:\PS> Get-CCMCimInstance -Query "SELECT * FROM Win32_ComputerSystem" -CimSession $CIM
				Query for the Win32_ComputerSystem CimClass against the machine that the $CIM targets via a CimSession
		.NOTES
            FileName:    Get-CCMCimInstance.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     Don't recall
            Updated:     2020-03-17	
#>
function Get-CCMCimInstance {
	[CmdletBinding(DefaultParameterSetName = 'CimQuery-ComputerName')]
	param
	(
		[Parameter(Mandatory = $false)]
		[string]$Namespace = 'root\cimv2',
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
		[System.Management.Automation.Runspaces.PSSession[]]$PSSession,
		[Parameter(Mandatory = $false, ParameterSetName = 'CimQuery-ComputerName')]
		[Parameter(Mandatory = $false, ParameterSetName = 'CimFilter-ComputerName')]
		[ValidateSet('CimSession', 'PSSession')]
		[string]$ConnectionPreference = 'CimSession'
	)
	begin {
		$ConnectionChecker = ($PSCmdlet.ParameterSetName).Split('-')[1]

		$GetCimInstanceSplat = @{ }
		switch ($PSBoundParameters.Keys) {
			'Namespace' {
				$GetCimInstanceSplat['NameSpace'] = $Namespace
			}
			'ClassName' {
				$GetCimInstanceSplat['ClassName'] = $ClassName
			}
			'Filter' {
				$GetCimInstanceSplat['Filter'] = $Filter
			}
			'Query' {
				$GetCimInstanceSplat['Query'] = $Query
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
					$GetCimInstanceOverPSSessionSplat = @{
						ArgumentList = $GetCimInstanceSplat
						ScriptBlock  = {
							param($GetCimInstanceSplat)
							Get-CimInstance @GetCimInstanceSplat
						}
					}
					
					Invoke-Command @GetCimInstanceOverPSSessionSplat @connectionSplat
				}
			}
		}
	}
}