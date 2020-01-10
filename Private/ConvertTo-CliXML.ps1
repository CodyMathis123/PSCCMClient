function ConvertTo-CliXml
{
	param (
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateNotNullOrEmpty()]
		[PSObject[]]$InputObject
	)
	return [management.automation.psserializer]::Serialize($InputObject)
}