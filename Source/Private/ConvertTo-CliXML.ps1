function ConvertTo-CliXml {
	# TODO - Add help
	param (
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateNotNullOrEmpty()]
		[PSObject[]]$InputObject
	)
	return [management.automation.psserializer]::Serialize($InputObject)
}